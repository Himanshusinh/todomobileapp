import 'dart:io';

import 'package:flutter/services.dart';

class VaultAutofillChannel {
  VaultAutofillChannel._();

  static const MethodChannel _ch = MethodChannel('todoapp/vault_autofill');

  static bool get isSupported => Platform.isAndroid;

  static Future<void> finishWithCredential({
    required String username,
    required String password,
  }) async {
    await _ch.invokeMethod('finishWithCredential', {
      'username': username,
      'password': password,
    });
  }

  static Future<void> finish() async {
    await _ch.invokeMethod('finish');
  }

  static Future<void> cancel() async {
    await _ch.invokeMethod('cancel');
  }
}

