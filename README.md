# Rip-Cord

Operant-conditioning habit interruption for Android (Material 3).  
When an urge to check your phone hits, **pull the Rip-Cord**: interrupt, do one short competing response, then put the phone down. Points and streak stay a private record in Log.

**Purpose:** Establish good habits and break out of negative thinking patterns. **Pull the ripcord.**

**Privacy:** 100% on-device. No accounts, no analytics SDKs, no network required for core features.

## Features

- **Activation**
  - Large in-app **Pull Rip-Cord** button (with haptic feedback)
  - Android **Quick Settings** tile labeled “Rip-Cord”
  - Home-screen **1×1 widget**
  - Deep link: `ripcord://activate?source=tile|widget|fab`
- **Competing response** (10–45s, configurable; prompts designed for ~15–30s)
  - Built-in library of **~100** short prompts plus **12** always-available Mindfulness, Creative, Writing, and Values prompts
  - Random pick each time you pull (not only on app open)
  - Editable library: add, edit, disable, custom categories
  - Explicit **I completed this** / **Stop**, then the app leaves
  - Optional TTS and grayscale mode
  - **Breathing prompts:** expanding/shrinking circle guide + soft chime
- **After a pull**
  - Optional hand-off set in Settings: a walk timer in the Clock app, a playlist/music link, or the dialer for one trusted person. Otherwise Rip-Cord just closes
- **Urge drill**
  - Name the urge, one physical action, under a minute, then leave. No points. Can be the default pull
- **Trusted person**
  - Name and number typed in Settings (no contacts permission). One tap opens a blank SMS composer. The number stays on the device
- **Private record**
  - Base points and streak (rolling window) live in Log
  - Stopping does **not** reset streak (only window expiry does)
- **Log**
  - Daily/weekly counts, success rate, longest free period, CSV export
- **App chrome**
  - **?** About — purpose of the app  
  - **X** Exit — leave the app  

## Requirements (building from source)

- Flutter 3.22+ (developed with 3.44 / Dart 3.12)
- Android SDK 31+ (target Galaxy S24+ / One UI)
- JDK 17
- For device install: USB cable + **USB debugging** enabled

## Setup (developers)

```powershell
# Ensure tools are on PATH (example Windows paths)
# Flutter: C:\src\flutter\bin
# ANDROID_HOME: %LOCALAPPDATA%\Android\Sdk
# JAVA_HOME: Temurin 17

cd C:\Users\tyler\rip-cord
flutter pub get
flutter test
flutter build apk --release
```

APK output:

```text
build\app\outputs\flutter-apk\app-release.apk
```

---

## Install & reinstall (sideload) — end user

Use this whenever you **rebuild** the app and want it on your phone again. You do **not** need to uninstall first for normal updates.

### One-time phone setup (Samsung / One UI)

1. **Settings → About phone → Software information**  
2. Tap **Build number** seven times (enable Developer options)  
3. **Settings → Developer options**  
   - Turn on **USB debugging**  
   - Optional: **Install via USB**  
4. Connect the phone with a **data-capable** USB cable  
5. Set USB mode to **File transfer / MTP** (from the USB notification)  
6. When prompted **Allow USB debugging?**, tap **Allow**

### Check the computer sees the phone

```powershell
adb devices
```

You should see a serial and the word **`device`** (not `unauthorized` or empty).

Example:

```text
List of devices attached
R5CX202DG7F    device
```

If it says **`unauthorized`**, unlock the phone and accept the debugging prompt, then run `adb devices` again.

### Rebuild the app

```powershell
cd C:\Users\tyler\rip-cord
flutter build apk --release
```

### Install or **reinstall over** the existing app

```powershell
adb install -r C:\Users\tyler\rip-cord\build\app\outputs\flutter-apk\app-release.apk
```

| Flag | Meaning |
|------|---------|
| **`-r`** | **Replace** the existing Rip-Cord install (reinstall). **Keeps your data** (points, streak, log, custom prompts) when the package name and signing key are the same. |

Success looks like:

```text
Performing Streamed Install
Success
```

Then open **Rip-Cord** from the app drawer on the phone.

### If you have more than one device/emulator

```powershell
adb devices
adb -s YOUR_SERIAL install -r C:\Users\tyler\rip-cord\build\app\outputs\flutter-apk\app-release.apk
```

Example for a known S24+:

```powershell
adb -s R5CX202DG7F install -r C:\Users\tyler\rip-cord\build\app\outputs\flutter-apk\app-release.apk
```

### Live run (debug, optional)

```powershell
cd C:\Users\tyler\rip-cord
flutter run -d YOUR_SERIAL
```

### When would I lose my data?

| Situation | Data kept? |
|-----------|------------|
| `adb install -r` after a normal rebuild (same package, same debug signing) | **Yes** |
| Uninstall the app from the phone, then install again | **No** — wiped |
| Install a build signed with a **different** key | May fail, or require uninstall first (**data lost** if you uninstall) |
| **Clear all data** inside Rip-Cord Settings | **No** — intentional reset |

### Install without adb (file copy)

1. Copy `app-release.apk` to the phone (USB file share, Drive, etc.)  
2. Open it with **My Files** (or your file manager)  
3. Allow **Install unknown apps** for that app if Android asks  
4. Install  

For updates this way, installing over the existing package usually preserves data the same as `-r`, as long as the signing key matches.

### Troubleshooting

| Problem | What to try |
|---------|-------------|
| `adb devices` empty | Unlock phone, re-plug cable, set File transfer, confirm USB debugging on |
| `unauthorized` | Accept the Allow USB debugging dialog; try `adb kill-server` then `adb devices` |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Signing keys differ — uninstall old app (loses data) or reinstall with the same keystore |
| `INSTALL_FAILED_USER_RESTRICTED` | Enable **Install via USB** in Developer options |
| App icon missing after install | Search app drawer for “Rip-Cord”; reboot phone if needed |

---

## Samsung / One UI: activation surfaces

### Quick Settings tile

1. Swipe down twice to expand Quick Settings.  
2. Tap the pencil / **Edit** control.  
3. Find **Rip-Cord** and drag it into the active tiles.  
4. Tap the tile once to open the competing-response sequence.  

### Home widget

1. Long-press the home screen → **Widgets**.  
2. Find **Rip-Cord** → place the 1×1 button.  
3. Tap to activate.  

---

## Permissions

Core app does not require special runtime permissions for basic use.

| Permission / component | Why |
|------------------------|-----|
| Quick Settings `TileService` | System tile; user must pin it |
| App widget receiver | Home-screen one-tap activate |
| Deep link `ripcord://` | Shared launch path for tile/widget |
| TTS query (optional) | Only if you enable spoken responses |
| Audio playback | Soft chime during guided breathing |

**Not included:** Accessibility Service, Device Admin, draw-over-other-apps overlay, app-blocking friction.

## Architecture (brief)

| Layer | Choice |
|-------|--------|
| UI | Flutter Material 3 |
| State | Riverpod |
| Navigation | go_router (+ deep links) |
| Persistence | SharedPreferences + JSON files |
| Audio | `audioplayers` (local chime) |
| Native | Kotlin `TileService`, `AppWidgetProvider`, deep link |

Project package: `com.ripcord.rip_cord`

## Developer docs

See **[HANDOFF.md](HANDOFF.md)** for full implementation history, library versioning, architecture notes, and roadmap.

See **[docs/PLAY_STORE.md](docs/PLAY_STORE.md)** to sign a Play App Bundle, host the privacy policy, and complete Play Console steps.

## License

Private / personal use unless otherwise stated.
