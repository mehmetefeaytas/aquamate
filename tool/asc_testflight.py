#!/usr/bin/env python3
"""Yeni TestFlight build'ini gruba ekler ve test notlarını yazar.

Kullanım:
  python3 tool/asc_testflight.py status <build_no>   # durum kontrolü
  python3 tool/asc_testflight.py setup  <build_no>   # gruba ekle + not yaz
"""

from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import jwt

CONFIG = Path.home() / ".config" / "asc-mcp" / "config.json"
KEY_DIR = Path.home() / ".appstoreconnect" / "private_keys"
BUNDLE = "com.aquamate.aquamate"

BETA_NOTES = """AquaMate 1.0.0 (build 5) — kişiselleştirme sürümü.

Yenilikler:
• İlk açılışta adını gir; ana sayfa "Merhaba, adın" diye karşılar
• Hakkında: geliştirici bilgisi ve bağlantı
• Kafein takibi: günlük limit, kaynak dağılımı, uyku saatine göre son kafein saati
• Sürdürülebilirlik: her içecekte tek dokunuşla kap seçimi, atık (g) ve CO2e hesabı, eko skoru
• Ay sonu raporu ve "şunu tercih etseydin" tasarruf karşılaştırması
• Geri dönüşüm işareti ve akşam hatırlatması
• Bugün / hafta / ay / yıl dönemli istatistikler
• 22 içecek türü + kendi içeceğini ekleme
• Yeni tasarım ve yeni uygulama ikonu

Test etmenizi istediklerimiz:
1) İlk açılış: adınızı girin, onboarding 4 adımı tamamlayın (hedef, kafein, uyku saati, bildirim izni). Ana sayfada "Merhaba, adınız" görünmeli. Ayarlar > profil kartından adı değiştirebilirsiniz.
2) Ana sayfa: 200/330/500 ml hızlı ekleme yapın — her seferinde "Hangi kaptan içtin?" sayfası açılmalı. Matara ve karton bardak seçip farkı görün.
3) İstatistik > Eko: atık ve CO2e değerlerinin arttığını, eko skorunun değiştiğini kontrol edin.
4) İstatistik > Hidrasyon: kayıt listesindeki geri dönüşüm simgesine dokunup "geri dönüşüme attım" işaretini test edin.
5) Eski sürümden güncelleme: önceki build'deki kayıtlarınız kaybolmamalı.
6) Ayarlar: kafein limiti ve uyku saatini değiştirip son kafein saatinin güncellendiğini doğrulayın.

Geri bildirim: efeyapiyor@gmail.com
"""


def _token() -> str:
    cfg = json.loads(CONFIG.read_text())
    key_id = cfg["keyId"]
    key_path = KEY_DIR / f"AuthKey_{key_id}.p8"
    now = int(time.time())
    payload = {"iss": cfg["issuerId"], "iat": now, "exp": now + 900,
               "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, key_path.read_text(), algorithm="ES256",
                      headers={"kid": key_id})


def api(path: str, method: str = "GET", body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {_token()}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=40) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        print("HTTP", exc.code, exc.read().decode()[:600])
        raise


def app_id() -> str:
    apps = api(f"/v1/apps?filter[bundleId]={BUNDLE}")
    return apps["data"][0]["id"]


def find_build(number: str) -> dict | None:
    builds = api(
        f"/v1/builds?filter[app]={app_id()}&filter[version]={number}"
        "&limit=1&fields[builds]=version,processingState,uploadedDate"
    )
    return builds["data"][0] if builds["data"] else None


def status(number: str) -> None:
    build = find_build(number)
    if build is None:
        print(f"build {number}: henüz görünmüyor")
        return
    attrs = build["attributes"]
    print(f"build {number}: {attrs.get('processingState')} "
          f"({attrs.get('uploadedDate','')[:16]})")
    if attrs.get("processingState") != "VALID":
        return
    groups = api(
        f"/v1/betaGroups?filter[builds]={build['id']}&limit=50"
        "&fields[betaGroups]=name,isInternalGroup"
    )
    names = [g["attributes"]["name"] for g in groups["data"]]
    print("  gruplar:", ", ".join(names) if names else "(yok)")
    notes = api(f"/v1/builds/{build['id']}/betaBuildLocalizations")
    for loc in notes["data"]:
        print("  not dili:", loc["attributes"].get("locale"))


def setup(number: str) -> None:
    build = find_build(number)
    if build is None or build["attributes"]["processingState"] != "VALID":
        raise SystemExit(f"build {number} henüz işlenmedi; sonra tekrar dene.")
    build_id = build["id"]

    # 1) Test notları (What to Test)
    existing = api(f"/v1/builds/{build_id}/betaBuildLocalizations")["data"]
    tr = [l for l in existing if l["attributes"].get("locale") == "tr"]
    if tr:
        api(
            f"/v1/betaBuildLocalizations/{tr[0]['id']}",
            "PATCH",
            {"data": {"type": "betaBuildLocalizations", "id": tr[0]["id"],
                      "attributes": {"whatsNew": BETA_NOTES}}},
        )
        print("Test notları güncellendi (tr).")
    else:
        api(
            "/v1/betaBuildLocalizations",
            "POST",
            {"data": {"type": "betaBuildLocalizations",
                      "attributes": {"locale": "tr", "whatsNew": BETA_NOTES},
                      "relationships": {"build": {"data": {"type": "builds",
                                                            "id": build_id}}}}},
        )
        print("Test notları oluşturuldu (tr).")

    # 2) Internal gruba ekle
    groups = api(
        f"/v1/betaGroups?filter[app]={app_id()}&limit=50"
        "&fields[betaGroups]=name,isInternalGroup"
    )["data"]
    if not groups:
        print("Uyarı: hiç TestFlight grubu yok; App Store Connect'ten oluştur.")
        return

    for group in groups:
        name = group["attributes"]["name"]
        internal = group["attributes"].get("isInternalGroup")
        api(
            f"/v1/betaGroups/{group['id']}/relationships/builds",
            "POST",
            {"data": [{"type": "builds", "id": build_id}]},
        )
        print(f"Gruba eklendi: {name} (internal={internal})")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    action, number = sys.argv[1], sys.argv[2]
    if action == "status":
        status(number)
    elif action == "setup":
        setup(number)
    else:
        raise SystemExit(__doc__)
