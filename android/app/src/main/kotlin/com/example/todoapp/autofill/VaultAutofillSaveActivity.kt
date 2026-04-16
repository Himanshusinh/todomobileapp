package com.example.todoapp.autofill

import android.app.Activity
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Launched from onSaveRequest to confirm saving/updating credentials into Vault.
 * The actual save is performed on the Flutter side; when Flutter is done it calls "finish".
 */
class VaultAutofillSaveActivity : FlutterActivity() {
  override fun getInitialRoute(): String {
    val pkg = intent.getStringExtra(VaultAutofillService.EXTRA_PACKAGE_NAME) ?: ""
    val domain = intent.getStringExtra(VaultAutofillService.EXTRA_WEB_DOMAIN) ?: ""
    val u = intent.getStringExtra(VaultAutofillService.EXTRA_SAVED_USERNAME) ?: ""
    val p = intent.getStringExtra(VaultAutofillService.EXTRA_SAVED_PASSWORD) ?: ""
    return "/vault/autofill/save?pkg=$pkg&domain=$domain&u=$u&p=$p"
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setResult(Activity.RESULT_CANCELED)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "todoapp/vault_autofill"
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "finish" -> {
          setResult(Activity.RESULT_OK)
          finish()
          result.success(true)
        }
        "cancel" -> {
          setResult(Activity.RESULT_CANCELED)
          finish()
          result.success(true)
        }
        else -> result.notImplemented()
      }
    }
  }
}

