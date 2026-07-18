# OfflinePocket

A security-first, offline-only digital wallet for Android. Store physical cards and identity documents — credit cards, debit cards, passports, driving licences, national IDs — with on-device OCR scanning, AES-256-GCM encryption, and biometric access control. No cloud sync, no account required. All data stays on your device — no network connections are made by this app.

---

## Features

### Biometric Authentication
- Fingerprint or face unlock on every app launch
- Re-prompts when the app returns to the foreground
- Device PIN, pattern, or password accepted as fallback when biometrics are unavailable

### Card & Document Storage
- Store any physical card or ID document as a structured entry
- Each entry has a label, a category, and a list of key-value fields
- Sensitive fields (card numbers, PAN, etc.) are masked by default with a reveal toggle
- Fields are validated against per-category patterns (e.g. card number format, expiry date)
- Custom fields can be added freely to any card
- Date fields show a calendar picker; expiry dates use MM/YY format

### Supported Categories

| Category | Fields |
|---|---|
| Credit Card | Card Number, Cardholder Name, Expiry Date, CVV |
| Debit Card | Card Number, Cardholder Name, Expiry Date, CVV |
| Prepaid Card | Card Number, Expiry Date |
| Passport | Passport Number, Full Name, Date of Birth, Nationality, Issue Date, Expiry Date |
| Driving Licence | Licence Number, Full Name, Date of Birth, Issue Date, Expiry Date |
| National ID | ID Number, Full Name, Date of Birth, Issue Date, Expiry Date |
| Generic ID | ID Number, Full Name |

### Card Scanning (OCR)
- Two-step camera flow: scan front, then back (back is optional)
- Card-shaped guide overlay on the viewfinder
- Preview each side with a Retake option before accepting
- On-device OCR via Google ML Kit — no network calls, no data sent anywhere
- Extracted fields auto-filled into the form; unrecognised text shown as chips to manually assign
- Chips can be used as the card label or added as a custom field value

### Image Storage & Encryption
- Scanned images are moved immediately from the camera cache to the app's private documents directory — never visible in the gallery, never lost on a cache clear
- Images are encrypted in-place with AES-256-GCM after OCR completes
- Decryption runs in a background isolate so the UI thread is never blocked
- Decrypted bytes are cached for the session — each image decrypts once regardless of how many times it is displayed

### Image Viewing
- Side-by-side front/back thumbnails on the Add Card and Card Detail screens
- Tap any thumbnail to open a fullscreen gallery
- Swipe left/right in the gallery to navigate between front and back
- Pinch-to-zoom in fullscreen view
- Individual images can be removed using the × button on the thumbnail

### Edit Card
- Tap the pencil icon on any Card Detail screen to edit the entry
- All fields, field names, category, and label are editable
- Tap "Re-scan Card" to replace images; skipping the back scan keeps the existing back image
- Replaced or removed image files are deleted from disk after the database write succeeds

### Share
- Share icon in the Card Detail screen AppBar
- Bottom sheet offers two options:
  - **Share card image** — shares the actual scanned front/back photos via the system share sheet (only shown if images exist)
  - **Share as text** — formats all field values as plain text with the category header and an OfflinePocket footer; a confirmation dialog is shown when the card contains sensitive fields
- Images are decrypted to temporary files, shared, then immediately deleted
- Once data leaves OfflinePocket via the system share sheet, it is outside the app's encryption model

### Dark / Light / System Theme
- Follows the phone's system dark/light setting by default
- Toggle in the home screen top-right cycles through: System → Light → Dark
- Preference is persisted across app restarts

### Screen Protection
- `FLAG_SECURE` is set on the app window — screenshots are blocked and the app appears blank in the Android task switcher, preventing credential exposure via screen capture or multitasking previews

### Auto-lock
- App locks and requires re-authentication after 5 minutes in the background
- Timeout is configurable via `security_idle_timeout_seconds` in `assets/config.json`

### Clipboard Auto-clear
- Copying a sensitive field (card number, CVV, etc.) schedules an automatic clipboard clear
- Clears after 45 seconds if you stay in the app, or when you return to OfflinePocket if you've been away longer
- Non-sensitive fields copy normally with no timer
- Timeout is configurable via `clipboard_clear_timeout_seconds` in `assets/config.json`

### Clipboard Paste Compatibility
- Card numbers are stripped of spaces and dashes before being written to the clipboard
- Ensures correct pasting into payment forms that enforce a digit-only maxlength

### Onboarding Carousel
- Shown once per app version after first authentication
- 4 slides covering core features: storage, scanning, security, and backup
- Re-appears after every app update so new features can be highlighted
- Skip button available on all slides; Get Started on the last

### Backup & Restore
- Export an encrypted `.opbackup` file containing all cards and scanned images
- Password-based encryption: AES-256-GCM with a PBKDF2-SHA256 derived key (100,000 iterations, 16-byte random salt)
- The file is opaque without the password — card numbers cannot be read from the file alone
- Share the file to Google Drive, email, or any storage app via the system share sheet
- Restore by opening the `.opbackup` file from Drive or any file manager — OfflinePocket is registered as the handler and opens the restore flow automatically
- Cards already on the device (matched by ID) are skipped; only new cards are imported
- Scanned images are included in the backup, decrypted on export and re-encrypted with the new device's keystore key on restore

---

## Security Architecture

| Layer | Mechanism |
|---|---|
| Access control | Android Biometric API via `local_auth` (PIN/pattern as fallback) |
| Encryption algorithm | AES-256-GCM (authenticated encryption) |
| Key storage | Android Keystore via `flutter_secure_storage` |
| Database | SQLCipher (database-level encryption) + field-level AES-256-GCM |
| Image storage | App private documents dir, AES-256-GCM encrypted |
| Backup encryption | AES-256-GCM + PBKDF2-SHA256 (100K iterations, 16-byte salt) |
| OCR | On-device only via Google ML Kit, no network |
| Network | None — no outbound connections, no telemetry |

No plaintext field values are ever written to disk. The encryption key is hardware-backed via the Android Keystore and cannot be extracted from the device.

Backup files are self-contained and portable. Images are decrypted from the device keystore during export and re-encrypted with the destination device's keystore key on restore. Without the backup password, the `.opbackup` file is opaque ciphertext.

---

## Tech Stack

| Tool | Version |
|---|---|
| Flutter | 3.44.2 stable |
| Dart | 3.12.2 |
| State management | Riverpod 2.x (AsyncNotifier pattern) |
| Database | Drift + SQLite |
| Encryption | PointyCastle (AES-256-GCM, PBKDF2) |
| Key storage | flutter_secure_storage (Android Keystore) |
| OCR | google_mlkit_text_recognition |
| Camera | camera plugin |
| Navigation | go_router |
| Sharing | share_plus |
| App version | package_info_plus |

---

## Project Structure

```
lib/
  core/
    config/         # AppConfig, CategoryConfig, FieldConfig
    crypto/         # AES-256-GCM encrypt/decrypt
    keystore/       # Android Keystore key management
    ocr/            # OcrService (ML Kit), FieldExtractor
    services/       # ImageService, BackupService, ClipboardService
  data/
    local/db/       # Drift database, tables, DAOs
    repositories/   # CardRepositoryImpl
  domain/
    entities/       # CardEntry, DocumentField
    repositories/   # CardRepository interface
    usecases/       # save, get, delete, update
  presentation/
    providers/      # Riverpod providers (cards, theme)
    screens/
      auth/         # AuthGate (biometric gate)
      home/         # HomeScreen, AddCardScreen (also used for edit)
      card_detail/  # CardDetailScreen
      scanner/      # CardScannerScreen
      onboarding/   # OnboardingScreen (per-version carousel)
      backup/       # BackupScreen (export & restore)
    widgets/        # MaskedField, EncryptedImage, FullscreenGallery
```

---

## Building from Source

### Prerequisites
- Flutter 3.44+ with Android SDK

### Build

```bash
# Debug
flutter run

# Release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Install to connected device (preserves app data)
flutter run --release
```

> **Note:** Always use `flutter run --release` to update an existing install. `flutter install` uninstalls the app first, wiping all stored data.

---

## Releases

Pre-built APKs are available on the [Releases](https://github.com/melvinjjoseph/offlinePocket/releases) page. All releases from v2.0.0 onward are signed with a stable release keystore.

To sideload on Android:
1. Download the `.apk` file
2. Enable **Install unknown apps** for your browser or file manager in Android settings
3. Open the downloaded file and tap Install

---

## Privacy Policy

OfflinePocket collects no data. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the full policy.

---

## Roadmap

- [x] Search and filter cards
- [ ] iOS support
- [ ] iCloud / Google Drive auto-backup
