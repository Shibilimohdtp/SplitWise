import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SharedPreferences? _prefs;
  String _currency = 'INR';
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _isInitialized = false;
  String? _error;

  String get currency => _currency;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _currency = _prefs?.getString('currency') ?? 'INR';
      _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
      _notificationsEnabled = _prefs?.getBool('notificationsEnabled') ?? true;
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print("Error initializing settings: $e");
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    await _prefs?.setString('currency', currency);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    await _prefs?.setBool('isDarkMode', isDarkMode);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool('notificationsEnabled', value);
    notifyListeners();
  }
}
