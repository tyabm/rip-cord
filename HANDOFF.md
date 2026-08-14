# Rip-Cord — Project Handoff

**Last updated:** 2026-08-06  
**Status:** MVP complete + post-MVP polish (incl. 24h bonus prompt unlock) — release APK sideloaded to Galaxy S24+ (SM-S926U)  
**Repo path:** `C:\Users\tyler\rip-cord`  
**Package ID:** `com.ripcord.rip_cord`

---

## 1. What this app is

Rip-Cord is an **operant-conditioning habit interruption tool** for Android (primary target: Samsung Galaxy S24+ / One UI). When the user feels an urge to check their phone, they pull a one-tap **Rip-Cord** that:

1. Interrupts the automatic behavior chain  
2. Delivers a short **competing response** (reframe + optional physical action)  
3. Awards **immediate reinforcement** (points, streak, celebration)  
4. **Logs** the event locally for shaping longer non-use intervals  

**Purpose (About dialog):** Establish good habits and break out of negative thinking patterns. **Pull the ripcord.**

**Privacy principle:** 100% on-device for core features — no cloud accounts, no remote analytics, no third-party tracking SDKs.

---

## 2. What has been done

### 2.1 Toolchain (this machine)

| Component | Location / notes |
|-----------|------------------|
| Flutter 3.44.8 (stable) | `C:\src\flutter` |
| Dart 3.12.2 | Bundled with Flutter |
| JDK 17 (Temurin) | `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot` |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk` (API 34–36, build-tools, NDK, emulator) |
| AVD | `RipCord_API34` (Pixel 7 profile, Android 14, `google_apis` x86_64) |
| Physical device tested | Samsung **SM-S926U** (Galaxy S24+), Android 16 / API 36, adb serial `R5CX202DG7F` |
| User env vars | `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `JAVA_HOME`, PATH includes Flutter + platform-tools + emulator |

### 2.2 Application (MVP + later changes)

#### Activation surfaces
- [x] Large in-app **Pull Rip-Cord** button (Home tab)
- [x] **Double haptic** on Rip-Cord press (heavy → medium) so activation is clearly felt
- [x] Android **Quick Settings** tile (`RipCordTileService`)
- [x] Home-screen **1×1 widget** (`RipCordWidgetProvider`)
- [x] Deep link: `ripcord://activate?source=fab|tile|widget|deepLink`
- [x] `MainActivity` MethodChannel for initial / new links while app is running

#### Competing-response sequence
- [x] Full-screen sequence with configurable duration (**10–45 s**, default **25**)
- [x] Weighted random pick from editable response library
- [x] **Avoid immediate repeat** of the last selected response when possible
- [x] Phrase + optional action prompt (designed for **~15–30 seconds**)
- [x] Countdown progress; **I completed this** enabled when timer finishes
- [x] **Abort** → logged incomplete, **no points**
- [x] Optional **TTS** (`flutter_tts`) — skipped when a guided breath animation is active
- [x] Optional **grayscale** ColorFilter during sequence
- [x] Process-death handling: pending sequence marked incomplete on next launch

#### Prompt library (~100 built-ins)
- [x] **100** stable-ID seeds (`seed_*`) in `lib/data/seed.dart`
- [x] Categories: **Breathing**, **Grounding**, **Movement**, **Reframe**, **Action** (~20 each)
- [x] Optional `category` field on responses; Settings groups by category
- [x] **Library version** (`responseLibraryVersion`, current **2**) upgrades old installs stuck on the original 8 prompts
- [x] `refreshBuiltInResponses()` / Settings **Restore / refresh built-in prompts** (keeps true customs; drops legacy first-run UUIDs)
- [x] `mergeMissingDefaultResponses()` for incremental seed additions after version is current
- [x] Settings shows library count: `N prompts (M enabled)`

#### Breathing guide (post-MVP)
- [x] When response is Breathing (or breath-like), show **BreathGuide** UI:
  - Static outer ring = full breath capacity  
  - Inner orb **expands/shrinks** with inhale / hold / exhale timing  
  - Phase label + per-phase countdown  
  - Soft **chime** asset (`assets/sounds/breath_chime.wav`) via `audioplayers`  
  - Light haptic on phase change  
- [x] Patterns in `lib/domain/breath_pattern.dart`: box, paced 4/6, physiological sigh, 4-7-8, coherent, long exhale, gentle default
- [x] `ChimeService` in `lib/services/chime_service.dart`

#### Reinforcement engine
- [x] Base points (configurable)
- [x] Streak with rolling time window (default 24h); abort does **not** reset streak
- [x] Optional variable-ratio bonus (default 20% chance of extra points)
- [x] Celebration / reward screen (animation + haptics)
- [x] Pure unit-tested logic in `lib/domain/reinforcement.dart`

#### Logging & summary
- [x] Every activation logged (timestamp, outcome, duration, phrase, points, source)
- [x] Log tab: today/week uses, success rates, points, streak, longest free period
- [x] CSV export via system share sheet (`share_plus`)

#### Settings & customization
- [x] Competing-response library: add / edit / delete / enable / category
- [x] Sequence duration, base points, variable-ratio controls, streak window
- [x] Theme: system / light / dark / high-contrast
- [x] TTS + grayscale toggles
- [x] Clear-all data (resets to defaults + seed phrases)
- [x] In-app help for adding QS tile and widget (Samsung-oriented copy)
- [x] Design tip: prompts short (**15–30 s**); match timer to action

#### App chrome (post-MVP)
- [x] **About (`?`)** and **Exit (`X`)** on Home, Log, and Settings app bars
- [x] Shared helper: `lib/features/common/app_chrome.dart`
- [x] About copy: purpose + “Pull the ripcord.” + on-device privacy one-liner
- [x] Exit: `SystemNavigator.pop()` (not shown on sequence/reward screens)

#### UI / platform quality
- [x] Material 3, large touch targets, bottom nav (Home · Log · Settings)
- [x] TalkBack-oriented labels on primary action / breath guide
- [x] Text scale clamping for large accessibility fonts
- [x] `minSdk` **31**, release signing currently uses **debug** keystore (sideload/dev only)

#### Persistence
- [x] Settings: `SharedPreferences` (includes `responseLibraryVersion`, `lastResponseId`)
- [x] Responses + events: JSON files under app documents directory
- [x] Seed library of **100** default competing responses on first launch / library upgrade

### 2.3 Project layout (high level)

```
rip-cord/
  lib/
    main.dart, app.dart, router.dart
    domain/          # models, reinforcement, free-period, breath_pattern
    data/            # repository + seed (~100 prompts)
    providers/       # Riverpod
    features/
      common/        # About / Exit app chrome
      home/
      sequence/      # sequence + breath_guide
      reward/, log/, settings/
    services/        # TTS, CSV export, chime
    theme/
  assets/sounds/     # breath_chime.wav
  android/           # TileService, Widget, MainActivity, manifests
  test/              # reinforcement, free_period, seed, breath_pattern, deep-link
  README.md          # end-user setup, sideload, reinstall
  HANDOFF.md         # this file
```

### 2.4 Build & verification status

| Check | Result |
|-------|--------|
| `flutter analyze` | Clean (as of last full run) |
| `flutter test` | Passing (incl. seed count ≤100, breath patterns) |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` (~51 MB) |
| Emulator | Debug install/run on `RipCord_API34` |
| Physical device | **Sideload success** on SM-S926U via `adb install -r` |

### 2.5 Changelog since original handoff (2026-08-05 → 2026-08-06)

| Area | Change |
|------|--------|
| Prompt library | Expanded from 8 → **100**; categories; versioned upgrade path |
| Random selection | Per activation (not per app open); avoid last-response repeat |
| Breathing UX | Animated orb + soft chime + phase haptics |
| Rip-Cord button | Stronger double haptic on press |
| App chrome | About (?) and Exit (X) on main tabs |
| Device | USB debugging + release APK installed on Galaxy S24+ |
| Dependencies | Added `audioplayers` + chime asset |
| Bonus unlock | High 24h point threshold unlocks Mindfulness/Creative/Writing/Values for 24h; re-earn to restore; library v3 |

### 2.6 Explicitly not in MVP (by design)

- Cloud sync, accounts, multi-user  
- Accessibility Service app-blocking / unlock delays  
- Floating overlay over other apps (`SYSTEM_ALERT_WINDOW`)  
- Automatic unlock / app-launch urge detection  
- Volume-key / side-button remapping  
- iOS  
- ML urge prediction  
- Token shop / spend points for cosmetics (points accumulate only)  
- Rich charts beyond summary chips  

---

## 3. How to run / ship (quick reference)

### Emulator

```powershell
$env:Path = "$env:LOCALAPPDATA\Android\Sdk\emulator;$env:LOCALAPPDATA\Android\Sdk\platform-tools;C:\src\flutter\bin;" + $env:Path

flutter emulators --launch RipCord_API34
# wait until booted
cd C:\Users\tyler\rip-cord
flutter run -d emulator-5554
```

### Release APK (sideload / reinstall)

See **README.md** for full end-user reinstall steps. Short form:

```powershell
cd C:\Users\tyler\rip-cord
flutter build apk --release
adb devices
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

`-r` **replaces** the existing install and **preserves app data** (points, log, custom prompts) when the package id and signing key are unchanged.

### Live debug on phone

```powershell
adb devices   # note serial, e.g. R5CX202DG7F
cd C:\Users\tyler\rip-cord
flutter run -d R5CX202DG7F
```

### Samsung S24+ activation after install

1. **Quick Settings:** expand panel → edit → add **Rip-Cord** tile  
2. **Widget:** long-press home → Widgets → **Rip-Cord** 1×1  
3. Open app once after install so storage/seed initializes (or library version upgrades) cleanly  

---

## 4. Architecture notes for the next developer

| Layer | Choice | Why |
|-------|--------|-----|
| Framework | Flutter (Android-only platform folder) | Preferred single codebase; native tile/widget via Kotlin |
| State | Riverpod | Simple `dataVersionProvider` invalidation after mutations |
| Nav | go_router + `StatefulShellRoute` | Deep link to `/activate` |
| Storage | Prefs + JSON files | No code generation; fine for current scale |
| Audio | `audioplayers` + local WAV | Soft breath chime, offline |
| Native | Hand-written `TileService` + `AppWidgetProvider` | Avoid fragile pub plugins for QS |

**Reinforcement product rule (documented in Settings):**  
Abort does not break streak; only **streak window expiry** does.

**Library selection:** Full library loads from disk on open (fast). Each Rip-Cord pull picks one **enabled** response at random (weighted), excluding the previous id when possible.

**Library migration:** `currentResponseLibraryVersion` in `lib/data/seed.dart` (value **2**). On load, if device version is lower, `refreshBuiltInResponses()` runs.

**Cold start:** Deep link / tile / widget all route into the same sequence screen. Measure on S24+ for ≤1.5 s target.

---

## 5. Potential future features

Prioritized as a suggested roadmap, not a commitment.

### Phase 2 — Friction & faster activation

| Feature | Notes |
|---------|--------|
| **Accessibility-based friction** | Optional delay / interstitial after abort |
| **Draw-over / bubble overlay** | Always-reachable floating Rip-Cord |
| **Lock-screen / notification quick action** | Sub-2s activation when phone is in hand |
| **Device Admin / app timers** | Temporary cooldown (optional, aggressive) |
| **Volume / side key remapping** | Accessibility; Samsung constraints |

### Phase 2.5 — Reinforcement & engagement

| Feature | Notes |
|---------|--------|
| **Token economy shop** | Spend points on themes / friction reductions |
| **Schedules & shaping** | Free-period goals without ML |
| **Custom audio packs** | User-recorded cues beyond TTS / chime |
| **More guided pattern UIs** | e.g. grounding / movement visual pacers |
| **Streak insurance / freezes** | Optional point cost |

### Phase 3 — Insights (still local-first)

| Feature | Notes |
|---------|--------|
| **Charts** | Success rate, free-period trend, time-of-day |
| **Export enhancements** | JSON backup/restore |
| **Tags / urge context** | Boredom, anxiety, FOMO labels |
| **Free-period timer widget** | 2×1 “time since last success” |

### Phase 4 — Platform & quality

| Feature | Notes |
|---------|--------|
| **Play Store packaging** | Real keystore, privacy policy, Data safety |
| **iOS port** | Widgets + Shortcuts |
| **Instrumented UI tests** | Activate → complete → log |
| **Perf budget** | Tile → first frame on S24+ |
| **Upgrade storage** | Drift/SQLite if needed |
| **Plugin hygiene** | `flutter_tts` / `share_plus` KGP warnings |
| **OnBackInvokedCallback** | Predictive back in manifest |

### Explicitly low priority / out of scope unless requested

- Social / leaderboards  
- Cloud sync without strong E2E story  
- Automatic surveillance of app launches  
- Clinical claims / medical positioning  

---

## 6. Known gaps & tech debt

1. **Release builds use debug signing** — fine for personal sideload; not for Play Store.  
2. **No automated UI/e2e tests** — unit tests cover reinforcement, free period, seed size, breath patterns, deep-link parse.  
3. **audioplayers may pull INTERNET in merged manifest** — core features do not call the network; audit before store privacy claims.  
4. **High-contrast theme** is a simple ColorScheme variant, not full WCAG audit.  
5. **cmdline-tools path inconsistency** (`latest` vs `latest-2`) — harmless SDK warnings.  
6. **Breath chime + TTS** — TTS intentionally off during breath-guided sequences to avoid overlap.  

---

## 7. Acceptance criteria (MVP) — checklist

| Criterion | Status |
|-----------|--------|
| User can add QS tile and widget; activate in ≤2 taps | Implemented; installed on S24+ |
| Completing sequence awards points and updates streak | Done |
| All data remains on-device | Done |
| Works offline and after reboot | Expected; smoke-tested via sideload install |
| Settings customize replacement text and sequence length | Done |
| ~100 varied prompts with random selection | Done (library version 2) |
| Breathing prompts have timed visual + chime | Done |
| About / Exit on main screens | Done |

---

## 8. Suggested next session (concrete)

1. Smoke-test tile, widget, breath animation, and haptics on physical S24+.  
2. Measure activation latency from cold start (tile/widget).  
3. Create a proper upload keystore if distributing beyond personal use.  
4. Pick one Phase 2 item (notification quick action or 2×1 free-period widget).  

---

## 9. Contact / ownership

Built as a Grok Build session from the functional specification for an operant-conditioning phone habit interruption tool. Source of truth for behavior: original spec + this handoff + `README.md`.

When continuing work, start from **`C:\Users\tyler\rip-cord`** and re-run `flutter doctor` if the shell environment was reset.
