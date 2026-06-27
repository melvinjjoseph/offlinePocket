# Privacy Policy — OfflinePocket

**Last updated:** 2026-06-28

---

## Summary

OfflinePocket does not collect, transmit, or share any personal data. Everything stays on your device.

---

## Data Collection

OfflinePocket collects **no data whatsoever**. The app makes **no network connections** of any kind. There is no analytics, no crash reporting, no telemetry, no advertising SDK, and no third-party tracking.

## Data Storage

All data you enter into OfflinePocket is stored exclusively on your device in a local encrypted database. Specifically:

- **Card fields** are encrypted with AES-256-GCM before being written to the SQLite database. SQLCipher provides an additional layer of database-level encryption.
- **Encryption keys** are stored in the Android Keystore and are hardware-backed. They cannot be extracted from the device.
- **Scanned card images** are moved immediately to the app's private documents directory (never visible in the photo gallery) and encrypted with AES-256-GCM.
- **No plaintext** field values are ever written to disk.

## Data Sharing

OfflinePocket does not share data with any third party. The only way data leaves the app is if **you explicitly use the Share feature**:

- **Share as text** — sends card field values in plain text to whichever app you choose (messaging, email, notes, etc.). A confirmation dialog is shown before sharing any card that contains sensitive fields. Once shared, the data is outside OfflinePocket's control.
- **Share card image** — shares the decrypted image via the Android system share sheet. Temporary files used for sharing are deleted immediately after the share sheet is dismissed.

## Clipboard

When you copy a sensitive field (card number, CVV, passport number, etc.), OfflinePocket automatically clears your clipboard after a timeout (default: 45 seconds). This prevents other apps from reading sensitive values from the clipboard after you are done.

## Permissions

OfflinePocket requests the following Android permissions:

| Permission | Purpose |
|---|---|
| Camera | Scanning physical cards with the built-in OCR feature |
| Biometric / Device Credentials | Authenticating you before granting access to the app |

No permission is used for any purpose other than its stated function above.

## Changes to This Policy

If this policy changes in a meaningful way (for example, if a network feature is ever added), the change will be documented in the app's GitHub release notes and this file will be updated.

## Contact

This app is maintained by Melvin Joseph. Issues and questions can be raised at https://github.com/melvinjjoseph/offlinePocket/issues.
