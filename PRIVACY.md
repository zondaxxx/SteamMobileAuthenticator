# Privacy

Steam Mobile Authenticator does not operate a backend, collect analytics, show ads or send telemetry.

Imported or newly enrolled account data stays in Android Keystore-backed encrypted storage or iOS Keychain. The app contacts Steam directly to align time, sign in or enroll when requested, refresh a session, load profiles and inventories, query Community Market prices, inspect/list confirmations and apply an action selected by the user or explicitly enabled automation. Profile, confirmation and inventory images can be loaded from Steam-hosted HTTPS URLs.

The camera is accessed only while the QR scanner screen is open. Notification permission is requested only after the user enables incoming confirmation notifications. The app does not use push-notification or analytics servers; a platform background task contacts Steam directly.

The file picker reads only files selected by the user and writes an encrypted backup only to a user-selected location. SDA vault and portable-backup passwords are held only long enough to decrypt or encrypt the selected data and are not persisted. A `.smabackup` contains secrets encrypted with its user-selected password and must still be handled as sensitive data.

Uninstalling the app normally removes its Android data. iOS Keychain items can survive app reinstallation according to Apple platform behavior; remove accounts inside the app before uninstalling when device disposal is a concern.
