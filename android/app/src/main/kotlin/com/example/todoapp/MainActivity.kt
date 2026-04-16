package com.example.todoapp

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.provider.Settings.Secure
import android.content.ComponentName
import com.example.todoapp.autofill.VaultAutofillService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channel = "todoapp/system"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "isAutofillEnabledForApp" -> {
            result.success(isAutofillEnabledForThisApp())
          }

          "openAutofillSettings" -> {
            try {
              openAutofillSettings()
              result.success(true)
            } catch (t: Throwable) {
              result.error("OPEN_SETTINGS_FAILED", t.message, null)
            }
          }

          else -> result.notImplemented()
        }
      }
  }

  private fun isAutofillEnabledForThisApp(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
    // Some projects compile with older compileSdk where Secure.AUTOFILL_SERVICE
    // is not available as a constant, so use the raw key string instead.
    val enabled = Secure.getString(contentResolver, "autofill_service") ?: return false
    val cn = ComponentName(packageName, VaultAutofillService::class.java.name).flattenToString()
    return enabled == cn
  }

  private fun openAutofillSettings() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
      return
    }
    // Opens the system screen where the user can select an Autofill provider.
    // Android does not allow enabling silently; user must confirm in Settings.
    val intent = Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE)
      // Required on many devices to open the correct screen.
      .setData(Uri.parse("package:$packageName"))
      .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    startActivity(intent)
  }
}
