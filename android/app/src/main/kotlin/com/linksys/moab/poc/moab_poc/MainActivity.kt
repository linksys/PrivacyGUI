package com.linksys.moab.poc.moab_poc

import android.annotation.SuppressLint
import android.app.Activity
import android.content.*
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import android.provider.Settings.ACTION_WIFI_ADD_NETWORKS
import android.provider.Settings.EXTRA_WIFI_NETWORK_LIST
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import java.util.regex.Matcher

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.linksys.native.channel.wifi.connect"
    private val OTP_CHANNEL = "com.linksys.native.channel.otp"

    private var otpResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "connectToWiFi") {
                startWifiQRCodeScanner(this, result)
            } else if (call.method == "wifiSuggestion") {
                val ssid = call.argument<String>("ssid") ?: ""
                val password = call.argument<String>("password") ?: ""
                startWifiSuggestion(this, ssid, password, result)
            } else if (call.method == "openWiFiPanel") {
                openWiFiPanel(this, result)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OTP_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "otp") {
                val intentFilter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
                registerReceiver(smsVerificationReceiver, intentFilter)

                // Start listening for SMS User Consent broadcasts from senderPhoneNumber
                // The Task<Void> will be successful if SmsRetriever was able to start
                // SMS User Consent, and will error if there was an error starting.
                val task = SmsRetriever.getClient(context).startSmsUserConsent(null)
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

    @RequiresApi(api = Build.VERSION_CODES.Q)
    private fun startWifiQRCodeScanner(context: Context, result: MethodChannel.Result) {
        val INTENT_ACTION_WIFI_QR_SCANNER = "android.settings.WIFI_DPP_ENROLLEE_QR_CODE_SCANNER"
        val wifiManager: WifiManager =
            context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (wifiManager.isEasyConnectSupported) {
            val intent = Intent(INTENT_ACTION_WIFI_QR_SCANNER)
            startActivityForResult(intent, 5000)
            result.success(true)
        } else {
            result.error("-1", "Not Support Easy Connect", null)
        }

    }

    @SuppressLint("MissingPermission")
    @RequiresApi(api = Build.VERSION_CODES.Q)
    private fun startWifiSuggestion(
        context: Context,
        ssid: String,
        password: String,
        result: MethodChannel.Result
    ) {
        // Optional (Wait for post connection broadcast to one of your suggestions)
        val intentFilter = IntentFilter(WifiManager.ACTION_WIFI_NETWORK_SUGGESTION_POST_CONNECTION);

        val broadcastReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                Log.d("test", "onReceive: ${intent.action}")

                if (!intent.action.equals(WifiManager.ACTION_WIFI_NETWORK_SUGGESTION_POST_CONNECTION)) {
                    return;
                }
                // do post connect processing here
//                print("onReceive: Post connect processing")
//                result.success(true)
            }
        }
        context.registerReceiver(broadcastReceiver, intentFilter)

        val builder = WifiNetworkSuggestion.Builder()
            .setSsid(ssid)
            .setIsUserInteractionRequired(true)
            .setIsInitialAutojoinEnabled(true)
        if (password.isNotEmpty()) {
            builder.setWpa2Passphrase(password)
        }
        val suggestionsList = listOf(builder.build())

        val wifiManager =
            context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

        val status = wifiManager.addNetworkSuggestions(suggestionsList)
        if (status != WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS) {
            // do error handling here
            result.success(false)
        } else {
            result.success(true)
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun openWiFiPanel(context: Context, result: MethodChannel.Result) {
        startActivity(Intent(android.provider.Settings.Panel.ACTION_WIFI))
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
