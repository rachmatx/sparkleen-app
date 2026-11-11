package com.sparkleen.sparkleen_mobile

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pending: MethodChannel.Result? = null
    private var prompt: BiometricPrompt? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sparkleen/security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "available" -> result.success(available())
                    "authenticate" -> authenticate(call.argument<String>("reason") ?: "Buka Sparkleen", result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun available(): Boolean = BiometricManager.from(this)
        .canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS

    private fun authenticate(reason: String, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("BIOMETRIC_BUSY", "Verifikasi sedang berjalan.", null)
            return
        }
        if (!available()) {
            result.error("BIOMETRIC_UNAVAILABLE", "Daftarkan biometrik kuat pada perangkat.", null)
            return
        }
        pending = result
        try {
            prompt = BiometricPrompt(this, ContextCompat.getMainExecutor(this),
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(authenticationResult: BiometricPrompt.AuthenticationResult) {
                        complete(true)
                    }
                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        if (errorCode == BiometricPrompt.ERROR_NEGATIVE_BUTTON ||
                            errorCode == BiometricPrompt.ERROR_USER_CANCELED ||
                            errorCode == BiometricPrompt.ERROR_CANCELED) complete(false)
                        else {
                            pending?.error("BIOMETRIC_FAILED", "Verifikasi perangkat belum berhasil.", null)
                            pending = null
                        }
                    }
                })
            val info = BiometricPrompt.PromptInfo.Builder()
                .setTitle("Verifikasi Sparkleen")
                .setSubtitle(reason.take(120))
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                .setNegativeButtonText("Batal")
                .setConfirmationRequired(true)
                .build()
            prompt?.authenticate(info)
        } catch (_: Exception) {
            pending?.error("BIOMETRIC_UNAVAILABLE", "Verifikasi perangkat tidak tersedia.", null)
            pending = null
        }
    }

    private fun complete(success: Boolean) {
        val callback = pending
        pending = null
        callback?.success(success)
    }

    override fun onStop() {
        // A verification interrupted by backgrounding must never authorize payment.
        prompt?.cancelAuthentication()
        complete(false)
        super.onStop()
    }

    override fun onDestroy() {
        prompt?.cancelAuthentication()
        complete(false)
        super.onDestroy()
    }
}
