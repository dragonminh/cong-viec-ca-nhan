import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Lớp này sẽ quản lý trạng thái của theme
class ThemeProvider with ChangeNotifier {
  static const THEME_STATUS = "THEME_STATUS";

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  // Đọc lựa chọn theme đã lưu từ bộ nhớ
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(THEME_STATUS) ?? 'system';

    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners(); // Thông báo cho các widget khác để cập nhật
  }

  // Lưu lựa chọn theme mới và thông báo thay đổi
  Future<void> setTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = themeMode;

    if (themeMode == ThemeMode.light) {
      prefs.setString(THEME_STATUS, 'light');
    } else if (themeMode == ThemeMode.dark) {
      prefs.setString(THEME_STATUS, 'dark');
    } else {
      prefs.setString(THEME_STATUS, 'system');
    }
    notifyListeners();
  }
}
