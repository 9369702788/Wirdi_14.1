import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings, persisted and reactive via ChangeNotifier so
/// MaterialApp can rebuild its theme/text scale live without adding a
/// state-management package. Instantiate once and pass down; call
/// [load] before runApp so the first frame already has saved prefs.
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  String _reciterId = 'ar.alafasy';
  bool _loaded = false;

  /// null = follow system locale (falls back to Arabic if the system
  /// locale isn't one we support). Non-null = explicit user choice,
  /// persisted across launches.
  Locale? _locale;

  /// Locales the app ships real translations for. Order here also
  /// drives the order shown in the language picker.
  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('de'),
    Locale('tr'),
  ];

  static const List<String> _rtlLanguageCodes = ['ar'];

  bool _prayerReminderEnabled = false;
  int _prayerReminderMinutesBefore = 10;
  // 'off' | 'banner' | 'sound' | 'both'
  String _prayerReminderMode = 'adhan';
  String _adhanId = 'a9';
  bool _showTransliteration = false;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  String get reciterId => _reciterId;
  bool get loaded => _loaded;
  bool get prayerReminderEnabled => _prayerReminderEnabled;
  int get prayerReminderMinutesBefore => _prayerReminderMinutesBefore;
  String get prayerReminderMode => _prayerReminderMode;
  String get adhanId => _adhanId;
  bool get showTransliteration => _showTransliteration;

  /// The effective locale: explicit user choice, else the device locale
  /// if we support it, else Arabic (this app's original default).
  Locale get locale {
    if (_locale != null) return _locale!;
    final deviceLocale = PlatformDispatcher.instance.locale;
    final match = supportedLocales.firstWhere(
      (l) => l.languageCode == deviceLocale.languageCode,
      orElse: () => const Locale('ar'),
    );
    return match;
  }

  /// null means "follow system" — used by the settings UI to show the
  /// "System default" option as selected.
  Locale? get explicitLocale => _locale;

  TextDirection get textDirection =>
      _rtlLanguageCodes.contains(locale.languageCode) ? TextDirection.rtl : TextDirection.ltr;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final storedTheme = prefs.getString('settings_theme_mode');
    _themeMode = switch (storedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    _fontScale = prefs.getDouble('settings_font_scale') ?? 1.0;
    _reciterId = prefs.getString('settings_reciter_id') ?? 'ar.alafasy';
    _prayerReminderEnabled = prefs.getBool('settings_prayer_reminder_enabled') ?? false;
    _prayerReminderMinutesBefore = prefs.getInt('settings_prayer_reminder_minutes') ?? 10;
    _prayerReminderMode = prefs.getString('settings_prayer_reminder_mode') ?? 'adhan';
    _adhanId = prefs.getString('settings_adhan_id') ?? 'a9';
    _showTransliteration = prefs.getBool('settings_show_transliteration') ?? false;

    final storedLocale = prefs.getString('settings_locale');
    _locale = storedLocale == null ? null : Locale(storedLocale);

    _loaded = true;
    notifyListeners();
  }

  /// Pass null to reset to "follow system".
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove('settings_locale');
    } else {
      await prefs.setString('settings_locale', locale.languageCode);
    }
  }

  Future<void> setShowTransliteration(bool value) async {
    _showTransliteration = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_show_transliteration', value);
  }

  Future<void> setAdhanId(String id) async {
    _adhanId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_adhan_id', id);
  }

  Future<void> setReciterId(String id) async {
    _reciterId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_reciter_id', id);
  }

  Future<void> setPrayerReminderEnabled(bool enabled) async {
    _prayerReminderEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_prayer_reminder_enabled', enabled);
  }

  Future<void> setPrayerReminderMinutesBefore(int minutes) async {
    _prayerReminderMinutesBefore = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_prayer_reminder_minutes', minutes);
  }

  Future<void> setPrayerReminderMode(String mode) async {
    _prayerReminderMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_prayer_reminder_mode', mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_theme_mode', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('settings_font_scale', scale);
  }
}

/// Single app-wide instance. Simple top-level singleton — avoids pulling
/// in Provider/Riverpod purely to broadcast theme changes.
final AppSettings appSettings = AppSettings();
