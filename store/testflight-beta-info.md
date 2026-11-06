# TestFlight / APK Dağıtım Rehberi

AquaMate şu an mağaza vitrininde yayınlanmayacak; Android tarafında imzalı
release APK, iOS tarafında TestFlight ile gerçek kullanıcıya dağıtılacak.

## 0. Bu sürümün durumu

| Alan | Değer |
|---|---|
| Sürüm | 1.0.0 |
| Build numarası | 5 |
| Yükleme | build 5: 6 Kasım 2026, 20:40 (Delivery UUID `85b8afda-d31e-4a3b-95ba-dab4aa7726e5`) |
| TestFlight durumu | `IN_BETA_TESTING` (IC iç grubu, otomatik bildirim açık) |
| Şifreleme beyanı | `usesNonExemptEncryption: false` (compliance tamam) |
| İşletim sistemi alt sınırı | iOS 15.0 |

Yeni sürüm yüklemek için: `pubspec.yaml` içindeki `+N` değerini artır (son
kullanılan: 5), `./tool/build_release.sh ipa` çalıştır, sonra:

```bash
ASC_KEY_ID=<anahtar kimliği>   # App Store Connect > Users and Access > Integrations
ISSUER=$(python3 -c "import json;print(json.load(open('$HOME/.config/asc-mcp/config.json'))['issuerId'])")
xcrun altool --upload-app --type ios -f build/ios/ipa/AquaMate.ipa \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ISSUER"

python3 tool/asc_testflight.py status 5   # işleme durumu
python3 tool/asc_testflight.py setup 5    # test notlarını yaz
```

## 1. Sürüm numarası

`pubspec.yaml` içindeki `version:` alanı iki değeri belirler:

```yaml
version: 1.0.0+5   # 1.0.0 = versionName / CFBundleShortVersionString
                   # +5    = versionCode / CFBundleVersion (her yüklemede artır)
```

Yeni bir TestFlight yüklemesinde **mutlaka** `+N` değerini artır.

## 1.1 Bu sürümün APK'sı

| Alan | Değer |
|---|---|
| Dosya | `dist/aquamate-1.0.0-arm64-v8a.apk` (20 MB) |
| versionCode | 2005 |
| SHA-256 | `f0c690805dd84c1f4f3c5996d35d2a7b852f5e713ef595ec09a0dc2781d6233b` |
| İndirme linki | https://litter.catbox.moe/qe0l99.apk (72 saat geçerli) |

Diğer ABI'ler aynı klasörde: `-armeabi-v7a.apk` (eski cihazlar),
`-x86_64.apk` (emülatör). Kalıcı link için GitHub Releases kullanılması önerilir.

## 2. Android: imzalı release APK

### 2.1 Keystore üret (tek sefer)

```bash
./tool/setup_keystore.sh
```

- Keystore: `~/.aquamate_keys/aquamate-upload.jks` (iCloud ve repo dışında)
- `android/key.properties` otomatik yazılır, `.gitignore`'da.
- **Parolayı kaybetme.** Keystore olmadan mevcut kurulumların üzerine güncelleme
  yapılamaz.

### 2.2 Derle

```bash
./tool/build_release.sh apk
```

Çıktılar `dist/` altında:
- `aquamate-1.0.0-arm64-v8a.apk` — modern Android telefonlar (önerilen)
- `aquamate-1.0.0-armeabi-v7a.apk` — eski 32-bit cihazlar
- `aquamate-1.0.0-x86_64.apk` — emülatörler

Betik ayrıca `dist/symbols-android/` içine obfuscation sembollerini yazar;
çökme raporlarını okumak için sakla.

### 2.3 Dağıt

- Dosyayı doğrudan paylaş (Drive, e-posta, kendi siten) veya
- Firebase App Distribution / GitHub Releases ile sürüm takibi yap.

> **Not:** Daha önce debug anahtarıyla imzalanmış bir APK kuruluysa imza
> farklı olduğu için Android güncellemeyi reddeder. Kullanıcı eski sürümü
> kaldırıp yeni APK'yı kurmalıdır. Bunu yayın notuna yaz.

### 2.4 İzin verilenler

Release yapısında demo veri araçları ve "örnek veri ekle" düğmeleri
görünmez (`kDebugMode` ile korunur). Veritabanı ilk açılışta boş başlar.

## 3. iOS: TestFlight

### 3.1 Ön koşullar

- Apple Developer Program üyeliği (TestFlight için zorunlu).
- Xcode'da `Runner` hedefi için doğru Team (`BZXS49579H`) ve otomatik imza.
- App Store Connect'te `com.aquamate.aquamate` bundle ID'si tanımlı olmalı.

### 3.2 TestFlight için zorunlu alanlar

| Alan | Değer / Not |
|---|---|
| Privacy Policy URL | `store/privacy-policy.html` dosyasını yayınla (aşağıya bak) |
| Beta açıklaması | `store/testflight-beta-info.md` |
| İletişim e-postası | efeyapiyor@gmail.com |
| Yaş sınıfı | 4+ |
| Kategori | Health & Fitness |
| Veri toplama beyanı | "Data Not Collected" (uygulama hiçbir veri toplamıyor) |
| Şifreleme | `ITSAppUsesNonExemptEncryption = false` (Info.plist'te hazır) |
| ATT | Kullanılmıyor, `NSPrivacyTracking = false` |

### 3.3 Build ve yükleme

```bash
./tool/build_release.sh ipa
```

1. Xcode → Window → Organizer → Archives → **Distribute App** →
   *App Store Connect* → *Upload*.
   (Alternatif: `xcrun altool` veya Transporter uygulaması.)
2. App Store Connect → TestFlight → *Builds* → işlem bitince **Internal
   Testing** grubuna ekle.
3. Dış test için (External Testing) Apple kısa bir **Beta App Review**
   yapar; gizlilik URL'si ve beta açıklaması burada kontrol edilir.
4. `store/testflight-beta-info.md` içeriğini "What to Test" alanına kopyala.

### 3.4 Gizlilik politikasını yayınlama (3 adım)

1. GitHub'da public bir repo aç (örn. `aquamate-legal`).
2. `store/privacy-policy.html` dosyasını `index.html` olarak yükle.
3. Settings → Pages → Branch: `main` / root → Save.
   Adres: `https://<kullanici>.github.io/aquamate-legal/`
4. Bu adresi hem App Store Connect'e hem `lib/core/app_info.dart` içindeki
   `privacyUrl` alanına yaz.

## 4. Yayın öncesi kontrol listesi

- [ ] `flutter analyze` → 0 sorun
- [ ] `flutter test` → tümü geçiyor
- [ ] `pubspec.yaml` sürümü artırıldı (`+N`)
- [ ] Android: `key.properties` mevcut, APK `apksigner verify` ile imza kontrolü
- [ ] iOS: Xcode'da Team ve provisioning doğru, build numarası yeni
- [ ] Uygulama ikonu ve açılış ekranı markalı (varsayılan Flutter logosu yok)
- [ ] İlk açılışta onboarding akışı çalışıyor
- [ ] Bildirim izni isteniyor, reddedilirse uygulama çalışmaya devam ediyor
- [ ] Eski sürümden (v1 veritabanı) güncelleme test edildi: kayıtlar korunuyor
- [ ] Gizlilik politikası URL'si erişilebilir
- [ ] Test cihazında uçtan uca akış: içecek ekle → kap seç → istatistik → eko raporu

## 4.1 Bilinen sınırlamalar

- Daha önce **debug anahtarıyla imzalanmış** bir APK cihazda kuruluysa, imza
  farklı olduğu için güncelleme reddedilir. Eski sürüm kaldırılıp yeniden
  kurulmalıdır.
- Uygulama yalnızca açık temayı destekler (karanlık mod tasarımı yok; sistem karanlık moddayken de açık tema kullanılır).
- iPhone'da yalnızca dikey yön desteklenir; iPad tüm yönlerde çalışır.
- Veriler cihaza özeldir; cihazlar arası senkronizasyon yoktur.
- Kafein ve ambalaj değerleri yaklaşık referanslardır, tıbbi amaçlı değildir.

## 5. Sürüm notu şablonu

```
AquaMate 1.0.0
• Kafein takibi: günlük limit, kaynak dağılımı ve son kafein saati
• Sürdürülebilirlik: her içecekte kap seçimi, atık ve CO₂e raporu
• Aylık / yıllık dönemsel istatistikler
• 22 içecek türü ve kendi içeceğini ekleme
• Yeni tasarım, yeni uygulama ikonu
```
