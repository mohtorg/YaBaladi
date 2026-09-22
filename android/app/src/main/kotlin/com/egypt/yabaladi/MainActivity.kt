package com.egypt.yabaladi

import android.content.Context
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "ya_baladi/quick_auth"
    private val prefsName = "ya_baladi_security"
    private val enabledKey = "quick_auth_enabled"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeviceSupported" -> result.success(isDeviceSupported())
                "isEnabled" -> result.success(getSharedPreferences(prefsName, Context.MODE_PRIVATE).getBoolean(enabledKey, false))
                "setEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    getSharedPreferences(prefsName, Context.MODE_PRIVATE).edit().putBoolean(enabledKey, enabled).apply()
                    result.success(null)
                }
                "authenticate" -> authenticate(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun isDeviceSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val manager = getSystemService(BIOMETRIC_SERVICE) as BiometricManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            manager.canAuthenticate(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                    BiometricManager.Authenticators.DEVICE_CREDENTIAL
            ) == BiometricManager.BIOMETRIC_SUCCESS
        } else {
            @Suppress("DEPRECATION")
            manager.canAuthenticate() == BiometricManager.BIOMETRIC_SUCCESS
        }
    }

    private fun authenticate(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.success(false)
            return
        }

        val executor: Executor = mainExecutor
        val prompt = BiometricPrompt.Builder(this)
            .setTitle("يا بلدي")
            .setSubtitle("تأكيد الهوية للدخول السريع")
            .setDescription("استخدم بصمة الإصبع أو وسيلة قفل الهاتف المعتمدة على جهازك")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            prompt.setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                    BiometricManager.Authenticators.DEVICE_CREDENTIAL
            )
        } else {
            @Suppress("DEPRECATION")
            prompt.setDeviceCredentialAllowed(true)
        }

        prompt.build().authenticate(
            CancellationSignal(),
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult?) {
                    result.success(true)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence?) {
                    result.success(false)
                }

                override fun onAuthenticationFailed() {
                    // لا ننهي الطلب هنا؛ Android يسمح للمستخدم بالمحاولة مرة أخرى.
                }
            }
        )
    }
}
