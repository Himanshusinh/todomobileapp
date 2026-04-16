package com.example.todoapp.autofill

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.service.autofill.Dataset
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import com.example.todoapp.R
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Shown by Android Autofill authentication. This is a Flutter-backed UI that lets the user
 * unlock Vault + pick a credential. When a credential is chosen, we return a Dataset via
 * EXTRA_AUTHENTICATION_RESULT.
 */
class VaultAutofillAuthActivity : FlutterActivity() {
  private var usernameId: AutofillId? = null
  private var passwordId: AutofillId? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    usernameId =
      intent.getParcelableExtra(VaultAutofillService.EXTRA_USERNAME_ID)
    passwordId =
      intent.getParcelableExtra(VaultAutofillService.EXTRA_PASSWORD_ID)
  }

  override fun getInitialRoute(): String {
    val pkg = intent.getStringExtra(VaultAutofillService.EXTRA_PACKAGE_NAME) ?: ""
    val domain = intent.getStringExtra(VaultAutofillService.EXTRA_WEB_DOMAIN) ?: ""
    return "/vault/autofill/pick?pkg=$pkg&domain=$domain"
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "todoapp/vault_autofill"
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "finishWithCredential" -> {
          val u = call.argument<String>("username") ?: ""
          val p = call.argument<String>("password") ?: ""
          finishWithDataset(u, p)
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

  private fun finishWithDataset(username: String, password: String) {
    val uId = usernameId
    val pId = passwordId
    if (uId == null && pId == null) {
      setResult(Activity.RESULT_CANCELED)
      finish()
      return
    }

    val presentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
      setTextViewText(android.R.id.text1, username.ifEmpty { "Vault login" })
    }

    val datasetBuilder = Dataset.Builder(presentation)
    if (uId != null) datasetBuilder.setValue(uId, AutofillValue.forText(username))
    if (pId != null) datasetBuilder.setValue(pId, AutofillValue.forText(password))

    val reply = Intent().apply {
      putExtra(android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT, datasetBuilder.build())
    }
    setResult(Activity.RESULT_OK, reply)
    finish()
  }
}

