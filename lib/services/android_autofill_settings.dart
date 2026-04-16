import 'dart:io';

import 'package:flutter/services.dart';

/// Android-only helpers for enabling this app as the system Autofill provider.
class AndroidAutofillSettings {
  AndroidAutofillSettings._();

  static const MethodChannel _ch = MethodChannel('todoapp/system');

  static bool get isSupported => Platform.isAndroid;

  static Future<bool> isAutofillEnabledForApp() async {
    if (!isSupported) return true;
    final v = await _ch.invokeMethod<bool>('isAutofillEnabledForApp');
    return v ?? false;
  }

  static Future<void> openAutofillSettings() async {
    if (!isSupported) return;
    await _ch.invokeMethod('openAutofillSettings');
  }
}

