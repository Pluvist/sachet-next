import 'package:flutter/material.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ThemeProvider extends ChangeNotifier {
  AppSettings get _appSettings => AppGlobal.appSettings;

  bool get isMD3 => _appSettings.isMD3 ?? true;
  bool get isUsingDynamicColors => false;
  int get themeMode => _appSettings.themeMode ?? 0;
  Color get themeColor =>
      colorFromHex(_appSettings.themeColor ?? "#FF3482FF") ?? Color(0xFF3482FF);
  bool get isPredictiveBack => _appSettings.isPredictiveBack ?? true;

  String get pageTransition => 'cupertino';
  PageTransitionsBuilder get transitionBuilder =>
      const CupertinoPageTransitionsBuilder();

  void setIsMD3(bool ismd3) {
    if (ismd3 != isMD3) {
      _appSettings.isMD3 = ismd3;
      AppGlobal.saveAppSettings();
      notifyListeners();
    }
  }

  void setThemeMode(int mode) {
    if (mode != themeMode) {
      _appSettings.themeMode = mode;
      AppGlobal.saveAppSettings();
      notifyListeners();
    }
  }

  void setThemeColor(Color color) {
    if (colorToHex(color) != _appSettings.themeColor) {
      _appSettings.themeColor = colorToHex(color);
      AppGlobal.saveAppSettings();
      notifyListeners();
    }
  }

  void setPageTransition(String storageKey) {
    if (pageTransition != storageKey) {
      _appSettings.pageTransition = storageKey;
      AppGlobal.saveAppSettings();
      notifyListeners();
    }
  }

  void setPredictiveBack(bool value) {
    if (isPredictiveBack != value) {
      _appSettings.isPredictiveBack = value;
      AppGlobal.saveAppSettings();
      notifyListeners();
    }
  }
}

const intAndThemeMode = {
  0: "跟随系统",
  1: '明亮',
  2: '黑暗',
};
