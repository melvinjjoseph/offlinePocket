# OfflinePocket

A security-first, **offline-only** digital wallet for Android. Store cards and identity documents — credit/debit cards, passports, licences, national IDs — with on-device OCR scanning, AES-256-GCM encryption, and biometric access control.

**No cloud. No account. No network calls — ever.**

---

## Features

**Encrypted vault** — Cards and documents stored with field-level AES-256-GCM on top of a SQLCipher database. Keys are hardware-backed via the Android Keystore and never leave the device.

**Biometric lock** — Fingerprint/face unlock on launch and on return to foreground, with device PIN as fallback. Auto-locks after a configurable idle timeout.

**Card scanning** — Two-step front/back capture with on-device OCR (Google ML Kit). Fields are auto-filled; scanned images are encrypted at rest and never touch the gallery.

**Smart fields** — Per-category validation, masked sensitive values with tap-to-reveal, month/year picker for card expiry, and numeric keypads where appropriate.

**Clipboard protection** — Copied sensitive values auto-clear after a configurable timeout, with a retry on app resume to defeat Android's background-write restrictions.

**Activity log** — A local audit trail of every action that moves data out of the app — shares and backup exports — plus unlocks, failed unlocks, and purges. Records references only, never values.

**Encrypted backup & restore** — Export an `.opbackup` file protected by AES-256-GCM with a PBKDF2-SHA256 derived key (100k iterations). Share it anywhere; restore by simply opening the file. Cards already on the device are skipped.

**Screen protection** — `FLAG_SECURE` blocks screenshots and hides the app in the task switcher.

**Purge All Data** — Irreversible wipe of every card, image, and the encryption key, behind a type-to-confirm dialog.

**Themes** — Dark, light, or follow system.

**Guided tour** — A six-slide walkthrough of the security model on first launch, replayable any time from **Settings → How OfflinePocket Works**.

### Supported categories

Credit Card · Debit Card · Prepaid Card · Passport · Driving Licence · National ID · Generic ID

---

## Security Architecture

| Layer | Mechanism |
|---|---|
| Access control | Android Biometric API (`local_auth`), PIN/pattern fallback |
| Encryption | AES-256-GCM (authenticated) |
| Key storage | Android Keystore via `flutter_secure_storage` |
| Database | SQLCipher + field-level AES-256-GCM |
| Images | App-private storage, AES-256-GCM encrypted |
| Backups | AES-256-GCM + PBKDF2-SHA256 (100k iterations, 16-byte salt) |
| OCR | On-device (ML Kit) |
| Network | **None** |

No plaintext values are written to disk. Backup files are opaque without the password.

> **Note:** Data shared via the system share sheet leaves OfflinePocket's encryption model. The Activity log exists so those moments stay visible.

---

## Tech Stack

Flutter 3.44 · Riverpod · Drift/SQLite · SQLCipher · PointyCastle · ML Kit · go_router

---

## Project Structure

```
lib/
  core/          config, crypto, keystore, OCR, services
  data/          Drift database, DAOs, repositories
  domain/        entities, repository interfaces, use cases
  presentation/
    providers/   Riverpod state
    screens/     auth, home (shell + dashboard), card_detail,
                 scanner, activity, settings, backup, onboarding
    theme/       app_theme.dart — palette, type, NeonTheme extension
    widgets/     shared UI
```

---

## Building

```bash
flutter pub get
flutter build apk --release
```

> Use `flutter run --release` to update an existing install. `flutter install` uninstalls first, wiping stored data.

Releases are built automatically by GitHub Actions on any `v*` tag.

---

## Releases

Pre-built APKs are on the [Releases](https://github.com/melvinjjoseph/offlinePocket/releases) page, signed with a stable release keystore (v2.0.0+).

To sideload: download the `.apk`, enable **Install unknown apps** for your browser/file manager, then open it.

---

## Privacy

OfflinePocket collects nothing. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

---

## Roadmap

- [x] Search
- [x] Encrypted backup & restore
- [x] Activity log
- [ ] iOS support
