# OfflinePocket — Development Progress

Tracks features built, bugs fixed, and decisions made across versions.

---

## v3.1.0 — Onboarding rebuild

### Six-slide carousel
`onboarding_screen.dart` was rewritten against a second set of Stitch mockups (`Design/onboarding_*`). The old version was four text-and-circle-icon slides; the new one is six purpose-built visuals: Your Private Vault, Intelligent Scanning, True Privacy, Local Activity Log, Encrypted Backups, Secure Your Pocket.

The slides share `_SlideScaffold` (visual → mono badge → title → body → feature chips) so vertical rhythm stays identical while each hero visual is bespoke. Every slide is scrollable inside a `ConstrainedBox(minHeight: viewport)`, which keeps the content optically centred on tall devices without clipping on short ones.

Visuals are drawn, not shipped as images — the animated scan line on the Scanning slide, the terminal window on the Activity Log slide, and two `CustomPainter`s (`_DotGridPainter` for the background grid, `_DashedRRectPainter` for the dashed frames). Nothing new was added to `assets/`.

Colors come from `context.neon` and `ColorScheme` throughout, so the carousel renders correctly in the light theme too.

### Version badge reads the real version
The mockup hardcodes `V1.0.4 SECURE NODE`. It now reads `PackageInfo.version`, so the badge can't drift out of sync with the shipped build.

### Replay from Settings
New **ABOUT → How OfflinePocket Works** action card. It clears `onboardingSeenProvider` and routes to `/onboarding`; finishing the tour re-sets the flag and the router's redirect returns to `/home`. Previously the carousel was reachable only by an app-version bump.

### Two rendering constraints worth recording
- The audit-log meta line drops to 10sp with ellipsis guards. At the theme's 12sp JetBrains Mono, the longest pair (`TIMESTAMP: 12:48:33.450` + `SYNC: LOCAL_ONLY`) overflows on narrow devices.
- The `SHA-256:` sub-line is upright, not italic. Only the 400/500 uprights of JetBrains Mono are bundled, so an italic request renders upright regardless; reduced alpha carries the distinction instead.

### Settings header logo
The Settings tab drew `Icons.shield_outlined` directly while every other header used `assets/icon/logo.png`, so the app appeared to have two different marks. All headers now share the asset at 32×32, with the shield as an `errorBuilder` fallback.

---

## v3.0.0 — Redesign

### Visual system
Full reskin to a dark, neon-cyan design (originating from a Google Stitch mockup, kept in `Design/`). `lib/presentation/theme/app_theme.dart` is now the single source of truth: the exact palette from the mockup's tokens, plus a derived teal light variant so the Dark/Light/System toggle still works.

Material has no slot for the design's glow/panel-border/accent tokens, so those live in a `NeonTheme` `ThemeExtension`, read via `context.neon`. Screens never hardcode colors.

`Geist` (sans) and `JetBrains Mono` (labels) are bundled as asset fonts in `assets/fonts/`. They are **not** fetched from Google Fonts at runtime — the app makes no network calls, so webfonts were never an option.

### Navigation restructure
The single home screen was replaced by `MainShell`, a bottom-nav shell with **Vault / Activity / Settings**. The former `home_screen.dart` was deleted.

The 7 config categories are folded into 3 browsing buckets on the dashboard (`vault_buckets.dart`): Payment (credit/debit/prepaid), Government (national ID/licence/generic), Travel (passport). Cards in unrecognised categories still surface under "Other" so nothing can be hidden by the grouping.

### Card detail
Rebuilt around a gradient hero card plus per-field panels with individual reveal/copy. Short fields (expiry, CVV) pair into two-column rows.

Two layout bugs found on-device and fixed:
- The secure-clipboard footer filled the entire screen. `Scaffold.bottomNavigationBar` passes a full-height max constraint, and the inner `Column` defaulted to `MainAxisSize.max`, so it greedily consumed all of it. Fixed with `MainAxisSize.min`.
- Paired compact fields (expiry/CVV) rendered as nothing. `CrossAxisAlignment.stretch` requires a bounded height, and inside a `ListView` the height is unbounded — in release builds this fails silently instead of asserting. Fixed by wrapping the row in `IntrinsicHeight`.

### User-configurable security timeouts
Auto-lock and clipboard-clear timeouts are now set in Settings and persisted (`settings_provider.dart`). `config.json` supplies the defaults; user choices override them. Stored in `SharedPreferences` alongside theme/onboarding — these are non-sensitive preferences, so they don't belong in the encrypted card database.

### Purge All Data
Irreversible wipe, behind a type-`PURGE`-to-confirm dialog that spells out what is destroyed and explicitly notes that already-exported backups are **not** affected and stay readable with their original password.

`purgeAll()` deletes the database rows **first**, so no row can ever reference a file that failed to delete; then removes the `card_images` directory; then drops the Keystore key, which renders any residual ciphertext undecryptable.

**Why not "Rotate Master Keys"** (also in the mockup): rejected. The key never leaves the device, so rotation doesn't evict an attacker who already extracted it; AES-GCM nonce limits are ~9 orders of magnitude away at this scale; and crucially it would not protect the one thing users would reach for it to protect — a leaked `.opbackup`, which is encrypted with a separate PBKDF2 key derived from the backup password. A full re-encryption pass also risks partial failure, and `getAll()` wipes the database on `InvalidCipherTextException`, so a botched rotation could destroy the vault.

### Honest hardware reporting
The settings panel previously hardcoded "StrongBox / Secure Enclave Active". It now queries `PackageManager.FEATURE_STRONGBOX_KEYSTORE` over a platform channel and reports what the device actually says. An unverified security claim is worse than none.

### Activity log
Local-only audit trail (`activity_events` table, schema v3 → v4).

Events are grouped by category, with **egress** ranked highest — sharing is the only action that moves data outside the app's encryption boundary, so it is the most audit-worthy thing the app does. Logged: share as text, share image, backup export (all egress), plus unlock, failed unlock, backup restore, purge.

Design decisions:
- Stores `cardId` as a **reference**, never the label. Labels resolve at render time, so a deleted card degrades to "a deleted card" rather than leaking the name of something erased.
- Never logs field values, clipboard contents, or backup passwords.
- All three share paths check `ShareResult.status` and log **only on success** — a share the user backs out of is never recorded as a leak. Destination comes from `result.raw`, parsed past generic package segments so `com.instagram.android` reads "Instagram" rather than "android".
- Retention: 30-day age cutoff, then a 500-event cap, pruned on insert.
- `purgeAll()` clears the log too, then records a single purge event — the purge is recorded, but nothing about the vault's contents survives it.
- Disableable via a Settings toggle; `local_auth` returns a plain bool, so a dismissed prompt and a rejected biometric are indistinguishable and the entry is worded neutrally rather than implying an intrusion.

### Versioning fix
`pubspec.yaml` had never moved off `1.0.0+1` — releases were tagged but the installed app always reported 1.0.0. Now `3.0.0+2`.

---

## v2.1.2 / v2.1.3

### Expiry date: month + year picker
Card expiry fields on Credit, Debit, and Prepaid cards now open a compact dialog with separate month and year dropdowns instead of the full calendar. The full calendar (with day selection) is still used for date-of-birth and issue/expiry dates on passports, licences, and national IDs — those use DD/MM/YYYY and need the day. Detection is based on the field's regex: a 2-digit year pattern (`[0-9]{2}$` without `{4}`) routes to the month/year picker; all other date fields keep the calendar.

### Numeric keyboard for Card Number and CVV
Card Number and CVV fields bring up the numeric keypad on both the Add Card and Edit Card screens. Detection is regex-based: any field whose regex allows only digits (no `[A-Z]` or `[a-z]`) gets `TextInputType.number`. This correctly targets Card Number and CVV while leaving Passport Number and Licence Number (which start with a letter) on the full keyboard.

The edit-mode fix (v2.1.3): in edit mode, fields were loaded with `regex: null` because the stored card data doesn't carry the config regex. Fixed by looking up the matching `FieldConfig` from `AppConfig` (by category + field name) in `initState` and using its regex.

---

## Post-v2.0.0 (unreleased)

### Clipboard paste compatibility
Sensitive field values (card numbers, CVVs) are now stripped of spaces and dashes before being written to the clipboard. Payment forms that enforce a digit-only `maxLength` were silently truncating the pasted value because the stored number included spaces.

### Onboarding carousel
A 4-slide `PageView` carousel shown after authentication. Runs once per app version — `onboarding_last_version` (a string) is persisted in `SharedPreferences` and compared to the current version from `package_info_plus`. Showing on every update means new features can be announced in the carousel slides.

### Backup & restore
Encrypted `.opbackup` export/import.

**Format:** `OPBACKUP` magic (8 bytes) + version byte + 16-byte PBKDF2 salt + AES-256-GCM ciphertext. The JSON payload includes all card fields plus base64-encoded plaintext image bytes (images are decrypted from the device keystore before export).

**Export:** Password + confirm dialog → PBKDF2 key derivation (SHA-256, 100K iterations) → AES-256-GCM encrypt → temp file → system share sheet. User picks destination (Drive, email, etc.).

**Import:** `.opbackup` MIME type registered in `AndroidManifest.xml` → OfflinePocket appears as handler when file is opened from any file manager or Drive. `MainActivity` reads the intent bytes and stores them; Flutter polls via `MethodChannel` at startup and on resume. `HomeScreen` detects a pending backup on mount and navigates to `BackupScreen` automatically.

**Restore conflict handling:** Cards matched by UUID. Cards already on the device are skipped (backup is likely older than current device state). Only new cards are inserted. Result snackbar shows added vs skipped counts.

**Image portability:** Images are encrypted with the device keystore (hardware-backed, non-exportable). On export they are decrypted to plaintext bytes and included in the encrypted JSON. On restore they are written to disk and re-encrypted with the new device's keystore key.

**Why not Google Drive API:** Requires OAuth, a Google Cloud project, and a network permission — contrary to the app's offline-only design. Share sheet to Drive achieves the same result without any of that.

**Why file_picker was dropped:** `file_picker`'s AAR was compiled against SDK 34; `flutter_plugin_android_lifecycle` requires `compileSdk 36` in AGP 9. No supported workaround exists. Android intent filter covers the import side without needing a file picker.

### Restore duplicate handling
Cards are matched by UUID on restore. Cards already present on the device are skipped rather than overwritten — the backup is likely older than the current device state. The result snackbar reports how many cards were added vs skipped.

UUID was kept as the identity key rather than switching to a content-based key (card number hash, etc.) because: not all card types have a card number; card numbers change on expiry/replacement; hashing content means any edit creates a new identity and causes duplicates on the next restore. The edge case (manually re-entering the same card on a new device before restoring) is rare enough that the simplicity of UUID identity is the right trade-off.

### Restore loading dialog + background isolate
PBKDF2 with 100K iterations runs on the main thread and blocks the UI entirely — the spinner couldn't even animate. Fixed by moving the `BackupService.restore()` call into a background isolate via `compute()`. `CryptoService` is stateless (pure PointyCastle, no Android Keystore) so it can be constructed fresh inside the isolate.

The small `CircularProgressIndicator` inside the Restore card section was also not prominent enough. Replaced with a non-dismissible `AlertDialog` overlay that appears immediately after the password is confirmed and stays until the restore completes or fails.

### Search
Inline search in the home screen AppBar. Tap the search icon → AppBar title becomes a `TextField` with autofocus. Results filter as you type against card label, category name, and field key names (not field values, to avoid displaying sensitive data in the list). Matching cards are shown as a flat list; the grouped view returns when the query is empty. Back button/gesture closes search without navigating away (`PopScope` with `canPop: !_isSearching`).

### Cold-start intent bug fix
Opening a `.opbackup` from Drive left the user on the home screen without triggering the restore flow.

Two issues:
1. `readBackupIntent()` was called after `super.onCreate()`, but Flutter's `main()` calls `consumePendingBackup` via `MethodChannel` *during* `super.onCreate()`. Fix: moved `readBackupIntent()` before `super.onCreate()`.
2. `ref.listen` in `HomeScreen` only fires on *changes*, not the initial provider value. Since `pendingBackupProvider` is set via a `ProviderScope` override in `main()` before any widget mounts, the listener never fired. Fix: converted `HomeScreen` to `ConsumerStatefulWidget` and checked the initial value in `initState` via `addPostFrameCallback`.

---

## v2.0.0

- Firebase removed entirely; app makes zero network connections
- `FLAG_SECURE` set on app window — screenshots blocked, app blank in task switcher
- Package renamed to `com.melvinjjoseph.offlinepocket`
- Share-as-text shows confirmation dialog when card contains sensitive fields
- Privacy policy added
- Release APK signed with stable release keystore (not debug key)

---

## v1.2.0

- Auto-lock: app locks after 5 minutes in background, configurable via `assets/config.json`
- Clipboard auto-clear: sensitive fields clear clipboard after 45 seconds or on app resume

---

## v1.1.0

- Edit card: all fields, label, category, and images editable after creation
- Dark / Light / System theme toggle, persisted across restarts
- OCR field extraction improvements
- Image performance: decryption cached per session, runs in background isolate

---

## v1.0.0 — Initial release

- Biometric authentication (fingerprint/face, PIN fallback)
- Card & document storage with AES-256-GCM field encryption
- Categories: Credit, Debit, Prepaid, Passport, Driving Licence, National ID, Generic ID
- Card scanning via Google ML Kit OCR (on-device, no network)
- Scanned images encrypted and stored in app private directory
- Fullscreen image gallery with pinch-to-zoom and swipe navigation
- Share card as text or image via system share sheet
- SQLCipher encrypted database
