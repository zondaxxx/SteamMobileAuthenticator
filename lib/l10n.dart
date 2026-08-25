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
    return text('error_$code') == 'error_$code'
        ? text('error_unknown')
        : text('error_$code');
  }

  static const _en = <String, String>{
    'app_name': 'Steam Mobile Authenticator',
    'accounts': 'Codes',
    'confirmations': 'Confirmations',
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
    'select_account': 'Select an account',
    'session_missing': 'This maFile can generate codes, but it has no current Steam session for confirmations.',
    'theme': 'Appearance',
    'theme_system': 'System',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
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
    'error_unknown': 'Something went wrong. No secret data was logged.',
  };

  static const _ru = <String, String>{
    'app_name': 'Steam Mobile Authenticator',
    'accounts': 'Коды',
    'confirmations': 'Подтверждения',
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
    'select_account': 'Выбери аккаунт',
    'session_missing': 'Этот maFile генерирует коды, но в нём нет актуальной сессии Steam для подтверждений.',
    'theme': 'Оформление',
    'theme_system': 'Системное',
    'theme_light': 'Светлое',
    'theme_dark': 'Тёмное',
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
