# Privacy

Steam Mobile Authenticator does not operate a backend, collect analytics, show ads or send telemetry.

Imported account data stays in Android Keystore-backed encrypted storage or iOS Keychain. The app contacts Steam directly to align time, refresh an imported session, list confirmations and apply an action selected by the user or explicitly enabled automation. Confirmation images can be loaded from HTTPS URLs returned by Steam.

The file picker reads only files selected by the user. An SDA vault password is held only long enough to decrypt the selected import and is not persisted.

Uninstalling the app normally removes its Android data. iOS Keychain items can survive app reinstallation according to Apple platform behavior; remove accounts inside the app before uninstalling when device disposal is a concern.
