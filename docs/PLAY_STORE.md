# Rip-Cord — Google Play packaging

## Done in the repo

| Item | Location |
|------|----------|
| Upload keystore | `android/upload-keystore.jks` (**gitignored**) |
| Signing passwords | `android/key.properties` (**gitignored**) |
| Release signing wired | `android/app/build.gradle.kts` |
| Privacy policy draft | `docs/privacy-policy.html` |
| App ID (do not change) | `com.ripcord.rip_cord` |

**Back up now:** copy `upload-keystore.jks` **and** `key.properties` to a password manager / encrypted drive. If you lose them you cannot update the same Play listing.

## Build the Play artifact

```powershell
cd C:\Users\tyler\rip-cord
flutter build appbundle --release
```

Output:

```text
build\app\outputs\bundle\release\app-release.aab
```

That `.aab` is what you upload to Play Console (not the APK).

Sideload testing can still use:

```powershell
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Release APKs are now signed with the **upload key**, not the debug key. Installing over an old debug-signed build will fail with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Uninstall the old debug build first (that wipes local data) or keep using the same upload key going forward.

## Host the privacy policy

Play needs a **public HTTPS URL**. Options:

1. GitHub Pages / any static host: upload `docs/privacy-policy.html`
2. Google Sites / a simple personal page: paste the same text
3. Paste the file contents to any site you already own

Then put that URL in Play Console → App content → Privacy policy.

## Play Console checklist (you do this in the browser)

1. Create a developer account — [play.google.com/console](https://play.google.com/console) — **$25**, verify identity.
2. Create app: name **Rip-Cord**, default language, app (not game), free.
3. Enable **Play App Signing** (default). Upload the `.aab`. First upload registers your upload key.
4. Store listing: title, short/full description, screenshots, 512×512 icon, 1024×500 feature graphic, contact email, privacy policy URL.
5. Complete **Data safety**, **Ads** (no), **Content rating**, target audience (avoid “designed for children”).
6. Category: Lifestyle or Health & Fitness. Do **not** claim medical treatment.
7. **Closed testing** (new personal accounts): invite ≥12 testers, 14 consecutive days opted in via Play.
8. Apply for production when Console allows.

## Suggested Data safety answers (core app)

- Data collected: **No** (or “collected but not shared,” stored only on device — match whatever Console options you see)
- Data shared with third parties: **No**
- Data encrypted in transit: N/A if you collect nothing remotely
- Users can request deletion: yes — uninstall / clear app data
- Account required: **No**
- Expectation ratings stay on device. The optional reminder is a local notification (off by default), not data sent off the phone. If you declare the notification permission, it is only for that opt-in reminder.

If the merged APK still has `INTERNET` from plugins, do **not** claim “the app cannot use the network.” Say you do not upload habit data.

## Versioning

`pubspec.yaml` `version: x.y.z+build`

- Play `versionName` = `x.y.z`
- Play `versionCode` = `build` (must increase every upload)

## Still optional later

- Custom launcher icon (replace default Flutter icon)
- Feature graphic / screenshots from the S24+
- Confirm `targetSdk` vs Play’s current floor at upload time
