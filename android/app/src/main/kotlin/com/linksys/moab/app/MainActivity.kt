package com.linksys.moab.app

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.*
import android.content.pm.PackageManager
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import com.linksys.moab.poc.moab_poc.plugins.UniversalLinkPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterFragmentActivity() {

    private val OTP_CHANNEL = "com.linksys.native.channel.otp"
    private var otpResult: MethodChannel.Result? = null

    @RequiresApi(Build.VERSION_CODES.Q)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OTP_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "otp") {
                val intentFilter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
                registerReceiver(smsVerificationReceiver, intentFilter, SmsRetriever.SEND_PERMISSION, null )

                // Start listening for SMS User Consent broadcasts from senderPhoneNumber
                // The Task<Void> will be successful if SmsRetriever was able to start
                // SMS User Consent, and will error if there was an error starting.
                val task = SmsRetriever.getClient(this@MainActivity).startSmsUserConsent(null)
                task.addOnSuccessListener {
                    Log.d("SMS retriever", "success listening!")
                    otpResult = result;
                }
                task.addOnFailureListener { Log.d("SMS retriever", "failed listening!") }

            } else {
                result.notImplemented()
            }
        }
    }

    ///////////////////////
    private val SMS_CONSENT_REQUEST = 2  // Set to an unused request code
    private val smsVerificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (SmsRetriever.SMS_RETRIEVED_ACTION == intent.action) {
                val extras = intent.extras
                val smsRetrieverStatus = extras?.get(SmsRetriever.EXTRA_STATUS) as Status

                when (smsRetrieverStatus.statusCode) {
                    CommonStatusCodes.SUCCESS -> {
                        // Get consent intent
                        val consentIntent =
                            extras.getParcelable<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT)
                        try {
                            // Start activity to show consent dialog to user, activity must be started in
                            // 5 minutes, otherwise you'll receive another TIMEOUT intent
                            startActivityForResult(consentIntent, SMS_CONSENT_REQUEST)
                        } catch (e: ActivityNotFoundException) {
                            // Handle the exception ...
                        }
                    }
                    CommonStatusCodes.TIMEOUT -> {
                        // Time out occurred, handle the error.
                    }
                }
            }
        }
    }

    public override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            // ...
            SMS_CONSENT_REQUEST ->
                // Obtain the phone number from the result
                if (resultCode == Activity.RESULT_OK && data != null) {
                    // Get SMS message content
                    val message = data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE)
                    // Extract one-time code from the message and complete verification
                    // `message` contains the entire text of the SMS message, so you will need
                    // to parse the string.
//                    val oneTimeCode = parseOneTimeCode(message) // define this function
                    Log.d("SMS retriever", "Get Message: $message")
                    // send one time code to the server
                    otpResult?.success(message)
                } else {
                    // Consent denied. User can type OTC manually.
                }
        }
    }
}
