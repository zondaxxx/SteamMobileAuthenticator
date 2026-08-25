# Security

## Threat model

`shared_secret`, `identity_secret`, access/refresh tokens and the revocation code are account credentials. The app stores each imported account as a separate encrypted Android Keystore / iOS Keychain item. iCloud Keychain synchronization and Android backup are disabled. The app has no analytics endpoint and sends account traffic only to `api.steampowered.com`, `steamcommunity.com`, and Steam-hosted image URLs.

The optional UI lock is separate from background processing: the operating system may let a scheduled worker access secure storage after the device has been unlocked. This is required for background confirmations and means the UI lock is not a substitute for a secure, non-rooted device.

Automatic confirmation is deliberately opt-in and limited by confirmation type. It cannot establish whether a trade is economically safe. A compromised Steam session, device, dependency or upstream API can still cause loss.

## Operational guidance

- Keep an offline backup of every original `maFile` and revocation code.
- Do not use builds from unknown mirrors.
- Prefer a signed release produced from a reviewed commit.
- Never paste real maFiles or tokens into issues, screenshots, CI logs or crash reports.
- Disable auto-confirmation on high-value accounts.
- Treat rooted/jailbroken devices as outside the supported threat model.

## Reporting a vulnerability

Do not open a public issue containing credentials or a working exploit against a real account. Contact the repository owner privately and include only synthetic test data, affected commit, platform version and reproducible steps.
