# OfflinePocket — Development Progress

Tracks features built, bugs fixed, and decisions made across versions.

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
