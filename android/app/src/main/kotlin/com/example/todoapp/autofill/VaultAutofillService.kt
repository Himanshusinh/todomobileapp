package com.example.todoapp.autofill

import android.app.PendingIntent
import android.app.assist.AssistStructure
import android.content.Intent
import android.os.Build
import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.FillCallback
import android.service.autofill.FillContext
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.SaveCallback
import android.service.autofill.SaveInfo
import android.service.autofill.SaveRequest
import android.util.Patterns
import android.view.View
import android.view.autofill.AutofillId
import android.widget.RemoteViews
import com.example.todoapp.R

class VaultAutofillService : AutofillService() {
  override fun onFillRequest(
    request: FillRequest,
    cancellationSignal: CancellationSignal,
    callback: FillCallback
  ) {
    try {
      val contexts = request.fillContexts
      val latestCtx = contexts.lastOrNull()
      val structure = latestCtx?.structure
      if (structure == null) {
        callback.onSuccess(null)
        return
      }

      val parsed = ParsedFields.fromStructure(structure)
      if (parsed.usernameId == null && parsed.passwordId == null) {
        callback.onSuccess(null)
        return
      }

      val authIntent = Intent(this, VaultAutofillAuthActivity::class.java).apply {
        putExtra(EXTRA_USERNAME_ID, parsed.usernameId)
        putExtra(EXTRA_PASSWORD_ID, parsed.passwordId)
        putExtra(EXTRA_PACKAGE_NAME, structure.activityComponent?.packageName ?: "")
        putExtra(EXTRA_WEB_DOMAIN, parsed.webDomain ?: "")
      }

      val flags =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
          PendingIntent.FLAG_MUTABLE
        else 0
      val pendingIntent = PendingIntent.getActivity(
        this,
        1001,
        authIntent,
        PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_UPDATE_CURRENT or flags
      )

      val presentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
        setTextViewText(android.R.id.text1, "Unlock Vault to autofill")
      }

      val response = FillResponse.Builder()
        .setAuthentication(
          listOfNotNull(parsed.usernameId, parsed.passwordId).toTypedArray(),
          pendingIntent.intentSender,
          presentation
        )
        .build()

      callback.onSuccess(response)
    } catch (t: Throwable) {
      callback.onFailure(t.message)
    }
  }

  override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
    try {
      val contexts = request.fillContexts
      val latest = contexts.lastOrNull()?.structure
      if (latest == null) {
        callback.onSuccess()
        return
      }
      val parsed = ParsedFields.fromStructure(latest)
      // Launch Flutter UI to confirm save/update. The Activity will talk to Flutter and persist.
      val intent = Intent(this, VaultAutofillSaveActivity::class.java).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        putExtra(EXTRA_PACKAGE_NAME, latest.activityComponent?.packageName ?: "")
        putExtra(EXTRA_WEB_DOMAIN, parsed.webDomain ?: "")
        putExtra(EXTRA_SAVED_USERNAME, parsed.capturedUsername ?: "")
        putExtra(EXTRA_SAVED_PASSWORD, parsed.capturedPassword ?: "")
      }
      startActivity(intent)
      callback.onSuccess()
    } catch (_: Throwable) {
      callback.onSuccess()
    }
  }

  private data class ParsedFields(
    val usernameId: AutofillId?,
    val passwordId: AutofillId?,
    val capturedUsername: String?,
    val capturedPassword: String?,
    val webDomain: String?,
  ) {
    companion object {
      fun fromStructure(structure: AssistStructure): ParsedFields {
        val windowCount = structure.windowNodeCount
        var usernameId: AutofillId? = null
        var passwordId: AutofillId? = null
        var capturedUsername: String? = null
        var capturedPassword: String? = null
        var webDomain: String? = null

        for (i in 0 until windowCount) {
          val windowNode = structure.getWindowNodeAt(i)
          val root = windowNode.rootViewNode
          if (webDomain.isNullOrEmpty()) {
            webDomain = root.webDomain
          }
          traverse(root) { node ->
            val hints = node.autofillHints
            val id = node.autofillId
            val inputType = node.inputType
            val cls = node.className ?: ""
            val isText = cls.contains("EditText", ignoreCase = true) ||
              cls.contains("TextField", ignoreCase = true) ||
              cls.contains("TextInput", ignoreCase = true)

            if (!isText || id == null) return@traverse

            val hintStr = hints?.joinToString(" ")?.lowercase() ?: ""
            val idEntry = node.idEntry?.lowercase() ?: ""
            val contentDesc = node.contentDescription?.toString()?.lowercase() ?: ""

            val maybeValue = node.text?.toString()
            val looksLikeEmail = maybeValue != null && Patterns.EMAIL_ADDRESS.matcher(maybeValue).matches()

            val isPasswordLike =
              hintStr.contains(View.AUTOFILL_HINT_PASSWORD) ||
                idEntry.contains("password") ||
                contentDesc.contains("password") ||
                ((inputType and android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD) ==
                  android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD) ||
                ((inputType and android.text.InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD) ==
                  android.text.InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD)

            val isUsernameLike =
              hintStr.contains(View.AUTOFILL_HINT_USERNAME) ||
                hintStr.contains(View.AUTOFILL_HINT_EMAIL_ADDRESS) ||
                idEntry.contains("email") ||
                idEntry.contains("user") ||
                contentDesc.contains("email") ||
                contentDesc.contains("user") ||
                looksLikeEmail

            if (passwordId == null && isPasswordLike) {
              passwordId = id
              capturedPassword = maybeValue
            } else if (usernameId == null && isUsernameLike) {
              usernameId = id
              capturedUsername = maybeValue
            }
          }
        }

        return ParsedFields(
          usernameId = usernameId,
          passwordId = passwordId,
          capturedUsername = capturedUsername,
          capturedPassword = capturedPassword,
          webDomain = webDomain
        )
      }

      private fun traverse(node: AssistStructure.ViewNode, block: (AssistStructure.ViewNode) -> Unit) {
        block(node)
        val children = node.childCount
        for (i in 0 until children) {
          traverse(node.getChildAt(i), block)
        }
      }
    }
  }

  companion object {
    const val EXTRA_USERNAME_ID = "vault_username_id"
    const val EXTRA_PASSWORD_ID = "vault_password_id"
    const val EXTRA_PACKAGE_NAME = "vault_package_name"
    const val EXTRA_WEB_DOMAIN = "vault_web_domain"
    const val EXTRA_SAVED_USERNAME = "vault_saved_username"
    const val EXTRA_SAVED_PASSWORD = "vault_saved_password"
  }
}

