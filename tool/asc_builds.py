#!/usr/bin/env python3
"""App Store Connect API ile TestFlight build listesini sorgular.

Kullanım: python3 tool/asc_builds.py [bundle_id]
"""

from __future__ import annotations

import json
import time
import urllib.request
from pathlib import Path

import jwt

CONFIG = Path.home() / ".config" / "asc-mcp" / "config.json"
KEY_DIR = Path.home() / ".appstoreconnect" / "private_keys"


def token() -> str:
    cfg = json.loads(CONFIG.read_text())
    key_id = cfg["keyId"]
    issuer = cfg["issuerId"]
    key_path = KEY_DIR / f"AuthKey_{key_id}.p8"
    if not key_path.exists():
        raise SystemExit(f"Anahtar bulunamadı: {key_path}")
    private_key = key_path.read_text()
    now = int(time.time())
    payload = {"iss": issuer, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": key_id})


def get(path: str) -> dict:
    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        headers={"Authorization": f"Bearer {token()}"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())


def main() -> None:
    bundle = "com.aquamate.aquamate"
    apps = get(f"/v1/apps?filter[bundleId]={bundle}")
    if not apps["data"]:
        raise SystemExit(f"Uygulama bulunamadı: {bundle}")
    app = apps["data"][0]
    print("App:", app["attributes"]["name"], "| id:", app["id"])
    print("SKU:", app["attributes"].get("sku"))

    builds = get(
        f"/v1/builds?filter[app]={app['id']}&limit=20&sort=-version"
        "&fields[builds]=version,uploadedDate,processingState,expired"
    )
    print("\nSon build'ler:")
    for b in builds["data"]:
        a = b["attributes"]
        print(
            f"  build {a.get('version'):>4}  {a.get('uploadedDate','')[:16]}  "
            f"durum={a.get('processingState')}  süresi_doldu={a.get('expired')}"
        )

    versions = get(f"/v1/apps/{app['id']}/appInfos?limit=5")
    for info in versions["data"]:
        print("\nApp info lokalizasyonları:")
        locs = get(f"/v1/appInfos/{info['id']}/appInfoLocalizations")
        for loc in locs["data"]:
            attrs = loc["attributes"]
            print(f"  {attrs.get('locale')}: {attrs.get('name')}")


if __name__ == "__main__":
    main()
