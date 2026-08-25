import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const delegate = _AppStringsDelegate();

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  bool get isRussian => locale.languageCode == 'ru';

  String text(String key) {
    final values = isRussian ? _ru : _en;
    return values[key] ?? _en[key] ?? key;
  }

  String error(Object error) {
    final raw = error.toString();
    final match = RegExp(r'\(([^)]+)\)').firstMatch(raw);
    final code = match?.group(1) ?? raw;
    return errorCode(code);
  }

  String errorCode(String code) {
    return text('error_$code') == 'error_$code'
        ? text('error_unknown')
        : text('error_$code');
  }

  static const _en = <String, String>{
    'app_name': 'Steam Mobile Authenticator',
    'accounts': 'Codes',
    'confirmations': 'Confirmations',
    'inventory': 'Inventory',
    'history': 'Activity',
    'settings': 'Settings',
    'import': 'Import maFile',
    'import_help': 'Choose one or more .maFile files. For an encrypted SDA vault, choose manifest.json and its .maFile files together.',
    'password': 'SDA vault password',
    'password_hint': 'The password is used only for this import.',
    'imported': 'Accounts imported: ',
    'cancel': 'Cancel',
    'continue': 'Continue',
    'delete': 'Delete',
    'delete_title': 'Delete account?',
    'delete_body': 'This removes the authenticator data from this device. Make sure you have a backup and the revocation code.',
    'no_accounts': 'No accounts yet',
    'no_accounts_body': 'Import an SDA-compatible .maFile to start.',
    'no_confirmations': 'Nothing is waiting for confirmation',
    'refresh': 'Refresh',
    'accept': 'Accept',
    'decline': 'Decline',
    'copied': 'Code copied',
    'tap_to_copy': 'Tap the code to copy',
    'select_account': 'Select an account',
    'session_missing': 'This maFile can generate codes, but it has no current Steam session for confirmations.',
    'theme': 'Appearance',
    'theme_system': 'System',
    'theme_light': 'Light',
    'theme_dark': 'AMOLED',
    'language': 'Language',
    'language_system': 'System',
    'language_en': 'English',
    'language_ru': 'Русский',
    'security': 'Security',
    'biometric_lock': 'Device authentication',
    'biometric_lock_body': 'Require Face ID, fingerprint, PIN or passcode.',
    'biometric_reason': 'Unlock your Steam authenticator',
    'unlock': 'Unlock',
    'auth_unavailable': 'Device authentication is unavailable.',
    'automation': 'Automation',
    'auto_trades': 'Auto-accept trades',
    'auto_market': 'Auto-accept market listings',
    'auto_warning_title': 'Enable automatic acceptance?',
    'auto_warning_body': 'This can approve unwanted or malicious transactions without review. Enable it only for accounts and devices you fully control.',
    'enable': 'Enable',
    'interval': 'Check interval',
    'minutes_15': 'Every 15 minutes',
    'minutes_30': 'Every 30 minutes',
    'minutes_60': 'Every hour',
    'background_note': 'Android and iOS decide when background tasks run. iOS may delay or skip checks; keep the app open for predictable processing.',
    'last_run': 'Last background check',
    'never': 'Never',
    'accepted_count': 'accepted',
    'storage': 'Data',
    'storage_body': 'maFiles and session tokens are stored only in Android Keystore / iOS Keychain. No analytics or third-party servers.',
    'disclaimer': 'Unofficial community app. Not affiliated with Valve or Steam. Back up every maFile and revocation code before use.',
    'details': 'Details',
    'items': 'Items',
    'done': 'Done',
    'save': 'Save',
    'approve': 'Approve',
    'inventory_empty': 'Refresh to load Steam, CS2, Dota 2 and TF2 inventories and calculate their market estimate.',
    'calculate_inventory': 'Calculate value',
    'pricing_items': 'Loading market prices',
    'inventory_assets': 'Assets',
    'valued_assets': 'Priced',
    'inventory_partial': 'Estimate is incomplete: private inventories, non-marketable items and Steam rate limits have no public price.',
    'history_empty': 'Actions, incoming confirmations, automatic decisions, QR logins and backups will appear here.',
    'session_health_healthy': 'Session active',
    'session_health_refreshable': 'Session can refresh',
    'session_health_expired': 'Session expired',
    'session_health_missing': 'Codes only',
    'session_health_checking': 'Checking session',
    'session_health_error': 'Check failed',
    'session_status_title': 'Steam session status',
    'session_health_healthy_body':
        'Steam accepted the current session. Online features can use it.',
    'session_health_refreshable_body': 'The access token needs renewal. The app will use the refresh token automatically.',
    'session_health_expired_body': 'The refresh token expired or Steam rejected it. Online features need a fresh Steam session.',
    'session_health_missing_body': 'The maFile contains authenticator secrets, but no Steam session tokens. Codes work, while confirmations, QR login and profile loading are unavailable.',
    'session_health_checking_body':
        'The app is contacting Steam and validating the saved tokens.',
    'session_health_error_body': 'Steam could not verify the saved session. The exact safe-to-display reason is shown below.',
    'session_error_cause': 'Reason',
    'session_codes_unaffected': 'Steam Guard codes are generated locally and are not affected by this status.',
    'session_reimport_advice': 'To restore online features, import an up-to-date maFile with a valid session. Keep a backup and recovery code before replacing data.',
    'dry_run': 'Safe test mode',
    'dry_run_body': 'Evaluate rules and write decisions to Activity without accepting anything.',
    'disable_dry_run_title': 'Allow real automatic actions?',
    'disable_dry_run_body': 'Allowed-partner and item-count checks still protect trades. Market confirmations do not expose enough structured value data and will be accepted whenever market automation is enabled.',
    'enable_live_actions': 'Allow real actions',
    'partner_allowlist': 'Allowed trade partners',
    'allowlist_empty': 'Empty — trades cannot be auto-accepted',
    'allowlist_help': 'One 17-digit SteamID64 per line. A trade is skipped unless its partner can be verified and appears here.',
    'max_trade_items': 'Maximum items per trade',
    'notifications': 'Notifications',
    'incoming_notifications': 'Incoming confirmations',
    'incoming_notifications_body':
        'Notify about newly detected trades and market actions.',
    'notification_previews': 'Show counts on lock screen',
    'notification_previews_body':
        'Off hides trade and market counts in notification text.',
    'notification_denied': 'Notification permission was not granted.',
    'inventory_settings': 'Inventory valuation',
    'currency': 'Market currency',
    'export_backup': 'Export encrypted backup',
    'backup_encrypted_body':
        'AES-256-GCM backup of accounts, settings and activity history.',
    'restore_backup': 'Restore encrypted backup',
    'restore_backup_body': 'Merge accounts and history from a .smabackup file.',
    'backup_password': 'Backup password',
    'repeat_password': 'Repeat password',
    'password_8': 'Use at least 8 characters.',
    'password_mismatch': 'Passwords do not match.',
    'backup_saved': 'Encrypted backup saved.',
    'backup_restored': 'Accounts restored:',
    'qr_login': 'Scan Steam QR',
    'qr_session_required':
        'Import or add an account with an active Steam session first.',
    'approve_as': 'Approve using account',
    'qr_help':
        'Scan the QR code shown by Steam on the device you are signing in to.',
    'paste_link': 'Paste QR link',
    'approve_login': 'Approve this sign-in?',
    'qr_verify_warning': 'Verify the device, IP and location. Never approve a request you did not start.',
    'qr_approved': 'Steam sign-in approved.',
    'add_authenticator': 'Add authenticator',
    'enroll_intro': 'Sign in to Steam to attach a new mobile authenticator. The account must have a verified phone number and no existing authenticator.',
    'steam_login': 'Steam account name',
    'steam_password': 'Steam password',
    'sign_in': 'Sign in',
    'credentials_private':
        'The password is sent only to Steam over HTTPS and is never stored.',
    'approve_in_steam':
        'Approve this sign-in in your existing Steam app, then continue.',
    'enter_guard_code':
        'Enter the code from your current Steam Guard authenticator.',
    'enter_email_code': 'Enter the code Steam sent to your email.',
    'guard_code': 'Steam Guard code',
    'waiting_steam': 'Waiting for Steam authorization…',
    'save_recovery_title': 'Save the recovery code now',
    'save_recovery_body': 'This code is required to remove or recover the authenticator. Store it outside this device before continuing.',
    'recovery_saved_check': 'I saved the recovery code in a safe place',
    'enter_sms': 'Enter the SMS activation code sent by Steam.',
    'sms_code': 'SMS code',
    'activate': 'Activate authenticator',
    'authenticator_ready': 'Authenticator is active',
    'error_no_files': 'No readable files were selected.',
    'error_password_required':
        'Enter the password for the encrypted SDA vault.',
    'error_wrong_password': 'Wrong password or damaged encrypted maFile.',
    'error_manifest_required': 'This does not look like plain JSON. Select manifest.json together with encrypted maFiles.',
    'error_invalid_manifest': 'manifest.json is invalid.',
    'error_invalid_mafile': 'The selected maFile is invalid.',
    'error_no_accounts':
        'No matching accounts were found in the selected files.',
    'error_session_required': 'The Steam session is missing or expired.',
    'error_refresh_expired':
        'The refresh token expired. Sign in again using a compatible client.',
    'error_refresh_failed': 'Steam could not refresh this session.',
    'error_identity_secret_missing':
        'identity_secret is missing from this maFile.',
    'error_device_id_missing': 'device_id is missing from this maFile.',
    'error_steam_id_missing': 'SteamID is missing from the maFile session.',
    'error_network_error':
        'Could not reach Steam. Check the network and try again.',
    'error_invalid_response': 'Steam returned an unexpected response.',
    'error_steam_rejected': 'Steam rejected the confirmation request.',
    'error_action_failed': 'Steam did not apply the requested action.',
    'error_details_failed': 'Steam could not load the transaction details.',
    'error_profile_failed': 'Steam could not load this profile.',
    'error_inventory_private': 'This Steam inventory is private.',
    'error_inventory_unavailable':
        'Steam inventory is temporarily unavailable.',
    'error_market_rate_limited': 'Steam limited market price requests. The visible total is partial; try again later.',
    'error_backup_password_short':
        'Use a backup password with at least 8 characters.',
    'error_backup_wrong_password':
        'Wrong backup password or modified backup file.',
    'error_backup_invalid': 'This is not a valid encrypted SMA backup.',
    'error_backup_version':
        'This backup was created by an unsupported app version.',
    'error_qr_invalid': 'This is not a valid Steam sign-in QR code.',
    'error_login_unavailable': 'Steam sign-in is temporarily unavailable.',
    'error_login_network': 'Could not reach Steam sign-in. Check the connection, VPN, DNS or ad blocker and try again.',
    'error_login_rate_limited': 'Steam temporarily limited sign-in attempts. Wait a few minutes before trying again.',
    'error_login_invalid_response': 'Steam returned an unexpected sign-in response. Update the app or try again later.',
    'error_login_encryption_failed':
        'Could not securely encrypt the Steam password.',
    'error_login_bad_credentials':
        'Steam rejected the account name or password.',
    'error_login_bad_guard': 'Steam rejected the Guard code.',
    'error_login_poll_failed': 'Could not check Steam sign-in status.',
    'error_login_timeout': 'Steam sign-in timed out. Start again.',
    'error_enroll_phone_required':
        'Add and verify a phone number on this Steam account first.',
    'error_enroll_authenticator_present':
        'This account already has a mobile authenticator.',
    'error_enroll_failed': 'Steam could not begin authenticator enrollment.',
    'error_enroll_bad_sms': 'Steam rejected the SMS activation code.',
    'error_enroll_finalize_failed':
        'Steam could not activate the authenticator.',
    'error_enroll_time_failed':
        'Could not synchronize authenticator codes with Steam.',
    'error_unknown': 'Something went wrong. No secret data was logged.',
  };

  static const _ru = <String, String>{
    'app_name': 'Steam Mobile Authenticator',
    'accounts': 'Коды',
    'confirmations': 'Подтверждения',
    'inventory': 'Инвентарь',
    'history': 'История',
    'settings': 'Настройки',
    'import': 'Импорт maFile',
    'import_help': 'Выбери один или несколько .maFile. Для зашифрованного хранилища SDA выбери одновременно manifest.json и связанные .maFile.',
    'password': 'Пароль хранилища SDA',
    'password_hint': 'Пароль используется только во время импорта.',
    'imported': 'Импортировано аккаунтов: ',
    'cancel': 'Отмена',
    'continue': 'Продолжить',
    'delete': 'Удалить',
    'delete_title': 'Удалить аккаунт?',
    'delete_body': 'Данные аутентификатора будут удалены с устройства. Убедись, что у тебя есть резервная копия и код отзыва.',
    'no_accounts': 'Аккаунтов пока нет',
    'no_accounts_body': 'Импортируй совместимый с SDA файл .maFile.',
    'no_confirmations': 'Нет ожидающих подтверждений',
    'refresh': 'Обновить',
    'accept': 'Принять',
    'decline': 'Отклонить',
    'copied': 'Код скопирован',
    'tap_to_copy': 'Нажми на код, чтобы скопировать',
    'select_account': 'Выбери аккаунт',
    'session_missing': 'Этот maFile генерирует коды, но в нём нет актуальной сессии Steam для подтверждений.',
    'theme': 'Оформление',
    'theme_system': 'Системное',
    'theme_light': 'Светлое',
    'theme_dark': 'AMOLED',
    'language': 'Язык',
    'language_system': 'Системный',
    'language_en': 'English',
    'language_ru': 'Русский',
    'security': 'Безопасность',
    'biometric_lock': 'Защита устройства',
    'biometric_lock_body': 'Запрашивать Face ID, отпечаток, PIN или пароль.',
    'biometric_reason': 'Разблокируй Steam-аутентификатор',
    'unlock': 'Разблокировать',
    'auth_unavailable': 'Проверка владельца устройства недоступна.',
    'automation': 'Автоматизация',
    'auto_trades': 'Автопринятие трейдов',
    'auto_market': 'Автопринятие лотов маркета',
    'auto_warning_title': 'Включить автопринятие?',
    'auto_warning_body': 'Нежелательная или мошенническая операция может пройти без просмотра. Включай только на полностью контролируемых аккаунтах и устройствах.',
    'enable': 'Включить',
    'interval': 'Интервал проверки',
    'minutes_15': 'Каждые 15 минут',
    'minutes_30': 'Каждые 30 минут',
    'minutes_60': 'Каждый час',
    'background_note': 'Android и iOS сами выбирают время фоновых задач. iOS может задержать или пропустить проверку; для предсказуемой работы оставь приложение открытым.',
    'last_run': 'Последняя фоновая проверка',
    'never': 'Никогда',
    'accepted_count': 'принято',
    'storage': 'Данные',
    'storage_body': 'maFiles и токены сессий хранятся только в Android Keystore / iOS Keychain. Нет аналитики и сторонних серверов.',
    'disclaimer': 'Неофициальное приложение сообщества, не связанное с Valve или Steam. До использования сохрани резервные копии maFile и кодов отзыва.',
    'details': 'Подробнее',
    'items': 'Предметы',
    'done': 'Готово',
    'save': 'Сохранить',
    'approve': 'Подтвердить',
    'inventory_empty': 'Обнови данные, чтобы загрузить инвентари Steam, CS2, Dota 2 и TF2 и рассчитать их рыночную оценку.',
    'calculate_inventory': 'Рассчитать стоимость',
    'pricing_items': 'Загрузка рыночных цен',
    'inventory_assets': 'Предметов',
    'valued_assets': 'Оценено',
    'inventory_partial': 'Оценка неполная: у закрытых инвентарей, нерыночных предметов и при лимите Steam нет публичной цены.',
    'history_empty': 'Здесь появятся действия, входящие подтверждения, решения автоматики, QR-входы и резервные копии.',
    'session_health_healthy': 'Сессия активна',
    'session_health_refreshable': 'Сессию можно обновить',
    'session_health_expired': 'Сессия истекла',
    'session_health_missing': 'Только коды',
    'session_health_checking': 'Проверка сессии',
    'session_health_error': 'Не удалось проверить',
    'session_status_title': 'Состояние сессии Steam',
    'session_health_healthy_body':
        'Steam принял текущую сессию. Сетевые функции могут её использовать.',
    'session_health_refreshable_body': 'Access-токен нужно обновить. Приложение автоматически использует refresh-токен.',
    'session_health_expired_body': 'Refresh-токен истёк или Steam его отклонил. Для сетевых функций нужна свежая сессия Steam.',
    'session_health_missing_body': 'В maFile есть секреты аутентификатора, но нет токенов сессии Steam. Коды работают, а подтверждения, QR-вход и загрузка профиля недоступны.',
    'session_health_checking_body':
        'Приложение связывается со Steam и проверяет сохранённые токены.',
    'session_health_error_body': 'Steam не удалось проверить сохранённую сессию. Ниже показана точная безопасная причина.',
    'session_error_cause': 'Причина',
    'session_codes_unaffected':
        'Коды Steam Guard генерируются локально и не зависят от этого статуса.',
    'session_reimport_advice': 'Чтобы восстановить сетевые функции, импортируй актуальный maFile с рабочей сессией. Перед заменой сохрани резервную копию и recovery code.',
    'dry_run': 'Безопасный тестовый режим',
    'dry_run_body':
        'Проверять правила и писать решения в историю, ничего не принимая.',
    'disable_dry_run_title': 'Разрешить реальные автоматические действия?',
    'disable_dry_run_body': 'Трейды останутся защищены списком партнёров и лимитом предметов. Подтверждения маркета не отдают достаточно структурированных данных о цене и будут приниматься при включённой автоматизации маркета.',
    'enable_live_actions': 'Разрешить действия',
    'partner_allowlist': 'Разрешённые партнёры',
    'allowlist_empty': 'Пусто — трейды не будут приняты автоматически',
    'allowlist_help': 'Один 17-значный SteamID64 в строке. Трейд пропускается, если партнёра нельзя проверить или его нет в списке.',
    'max_trade_items': 'Максимум предметов в трейде',
    'notifications': 'Уведомления',
    'incoming_notifications': 'Входящие подтверждения',
    'incoming_notifications_body':
        'Уведомлять о новых трейдах и операциях маркета.',
    'notification_previews': 'Показывать счётчики на экране блокировки',
    'notification_previews_body':
        'Если выключено, типы и число операций скрыты в тексте уведомления.',
    'notification_denied': 'Разрешение на уведомления не выдано.',
    'inventory_settings': 'Оценка инвентаря',
    'currency': 'Валюта маркета',
    'export_backup': 'Экспорт зашифрованной копии',
    'backup_encrypted_body': 'AES-256-GCM копия аккаунтов, настроек и истории.',
    'restore_backup': 'Восстановить резервную копию',
    'restore_backup_body': 'Объединить аккаунты и историю из файла .smabackup.',
    'backup_password': 'Пароль резервной копии',
    'repeat_password': 'Повтори пароль',
    'password_8': 'Используй не меньше 8 символов.',
    'password_mismatch': 'Пароли не совпадают.',
    'backup_saved': 'Зашифрованная копия сохранена.',
    'backup_restored': 'Восстановлено аккаунтов:',
    'qr_login': 'Сканировать QR Steam',
    'qr_session_required':
        'Сначала импортируй или добавь аккаунт с активной сессией Steam.',
    'approve_as': 'Подтвердить от аккаунта',
    'qr_help': 'Отсканируй QR-код, показанный Steam на устройстве, куда выполняется вход.',
    'paste_link': 'Вставить QR-ссылку',
    'approve_login': 'Подтвердить этот вход?',
    'qr_verify_warning': 'Проверь устройство, IP и местоположение. Никогда не подтверждай вход, который ты не начинал.',
    'qr_approved': 'Вход в Steam подтверждён.',
    'add_authenticator': 'Добавить аутентификатор',
    'enroll_intro': 'Войди в Steam, чтобы подключить новый мобильный аутентификатор. На аккаунте должен быть подтверждённый телефон и не должно быть другого аутентификатора.',
    'steam_login': 'Логин Steam',
    'steam_password': 'Пароль Steam',
    'sign_in': 'Войти',
    'credentials_private':
        'Пароль отправляется только Steam по HTTPS и нигде не сохраняется.',
    'approve_in_steam':
        'Подтверди вход в текущем приложении Steam, затем продолжи.',
    'enter_guard_code': 'Введи код из текущего Steam Guard.',
    'enter_email_code': 'Введи код, который Steam прислал на почту.',
    'guard_code': 'Код Steam Guard',
    'waiting_steam': 'Ожидание авторизации Steam…',
    'save_recovery_title': 'Сохрани код восстановления сейчас',
    'save_recovery_body': 'Этот код нужен для удаления или восстановления аутентификатора. Сохрани его вне этого устройства до продолжения.',
    'recovery_saved_check': 'Я сохранил код восстановления в безопасном месте',
    'enter_sms': 'Введи код активации из SMS от Steam.',
    'sms_code': 'Код из SMS',
    'activate': 'Активировать аутентификатор',
    'authenticator_ready': 'Аутентификатор активирован',
    'error_no_files': 'Не удалось прочитать выбранные файлы.',
    'error_password_required': 'Введи пароль зашифрованного хранилища SDA.',
    'error_wrong_password': 'Неверный пароль или повреждённый maFile.',
    'error_manifest_required': 'Это не открытый JSON. Выбери manifest.json вместе с зашифрованными maFiles.',
    'error_invalid_manifest': 'Некорректный manifest.json.',
    'error_invalid_mafile': 'Выбранный maFile некорректен.',
    'error_no_accounts': 'В выбранных файлах не найдено подходящих аккаунтов.',
    'error_session_required': 'Сессия Steam отсутствует или истекла.',
    'error_refresh_expired':
        'Refresh-токен истёк. Выполни вход через совместимый клиент.',
    'error_refresh_failed': 'Steam не смог обновить сессию.',
    'error_identity_secret_missing': 'В maFile отсутствует identity_secret.',
    'error_device_id_missing': 'В maFile отсутствует device_id.',
    'error_steam_id_missing': 'В сессии maFile отсутствует SteamID.',
    'error_network_error': 'Не удалось связаться со Steam. Проверь сеть.',
    'error_invalid_response': 'Steam вернул неожиданный ответ.',
    'error_steam_rejected': 'Steam отклонил запрос подтверждений.',
    'error_action_failed': 'Steam не выполнил действие.',
    'error_details_failed': 'Steam не смог загрузить детали операции.',
    'error_profile_failed': 'Steam не смог загрузить профиль.',
    'error_inventory_private': 'Этот инвентарь Steam закрыт.',
    'error_inventory_unavailable': 'Инвентарь Steam временно недоступен.',
    'error_market_rate_limited': 'Steam ограничил запросы цен. Показанная сумма неполная; повтори позже.',
    'error_backup_password_short':
        'Пароль резервной копии должен быть не короче 8 символов.',
    'error_backup_wrong_password':
        'Неверный пароль или файл резервной копии изменён.',
    'error_backup_invalid': 'Это невалидная зашифрованная копия SMA.',
    'error_backup_version':
        'Копия создана неподдерживаемой версией приложения.',
    'error_qr_invalid': 'Это не QR-код входа Steam.',
    'error_login_unavailable': 'Вход Steam временно недоступен.',
    'error_login_network': 'Не удалось связаться со входом Steam. Проверь интернет, VPN, DNS или блокировщик и повтори.',
    'error_login_rate_limited': 'Steam временно ограничил попытки входа. Подожди несколько минут перед повтором.',
    'error_login_invalid_response': 'Steam вернул неожиданный ответ входа. Обнови приложение или повтори позже.',
    'error_login_encryption_failed':
        'Не удалось безопасно зашифровать пароль Steam.',
    'error_login_bad_credentials': 'Steam отклонил логин или пароль.',
    'error_login_bad_guard': 'Steam отклонил код Guard.',
    'error_login_poll_failed': 'Не удалось проверить статус входа Steam.',
    'error_login_timeout': 'Истекло время входа Steam. Начни заново.',
    'error_enroll_phone_required':
        'Сначала добавь и подтверди номер телефона в Steam.',
    'error_enroll_authenticator_present':
        'На аккаунте уже есть мобильный аутентификатор.',
    'error_enroll_failed': 'Steam не смог начать подключение аутентификатора.',
    'error_enroll_bad_sms': 'Steam отклонил код из SMS.',
    'error_enroll_finalize_failed':
        'Steam не смог активировать аутентификатор.',
    'error_enroll_time_failed': 'Не удалось синхронизировать коды со Steam.',
    'error_unknown':
        'Произошла ошибка. Секретные данные не записывались в журнал.',
  };
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const <String>['en', 'ru'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) => SynchronousFuture(
    AppStrings(
      locale.languageCode == 'ru' ? const Locale('ru') : const Locale('en'),
    ),
  );

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
