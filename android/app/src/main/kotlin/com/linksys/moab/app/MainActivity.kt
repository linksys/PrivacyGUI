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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.linksys.native.channel.wifi.connect"
    private val OTP_CHANNEL = "com.linksys.native.channel.otp"
    private val WIFI_TAG = "WIFI CHANNEL"

    private var otpResult: MethodChannel.Result? = null

    @RequiresApi(Build.VERSION_CODES.Q)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "connectToWiFi") {
                val ssid = call.argument<String>("ssid") ?: ""
                val password = call.argument<String>("password") ?: ""
                val security = call.argument<String>("security") ?: "OPEN"
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startWifiQRCodeScanner(this, ssid, password, result)
                } else {
                    startWifiConfiguration(this, ssid, password, security, result)
                }
            } else if (call.method == "checkAndroidVersionUnderTen") {
                result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.Q)
            } else if (call.method == "isAndroidTenAndSupportEasyConnect") {
                var isAndroidTen = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                val wifiManager: WifiManager =
                    this.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                var supportEasyConnect = wifiManager.isEasyConnectSupported
                result.success(isAndroidTen && supportEasyConnect)
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

    @RequiresApi(api = Build.VERSION_CODES.Q)
    private fun startWifiQRCodeScanner(context: Context, ssid: String, password: String, result: MethodChannel.Result) {
        val INTENT_ACTION_WIFI_QR_SCANNER = "android.settings.WIFI_DPP_ENROLLEE_QR_CODE_SCANNER"
        val wifiManager: WifiManager =
            context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (wifiManager.isEasyConnectSupported) {
            val intent = Intent(INTENT_ACTION_WIFI_QR_SCANNER)
            startActivityForResult(intent, 5000)
            result.success(true)
        } else {
            Log.d(WIFI_TAG, "Not Support Easy Connect, fall back to wifi suggestion")
            startWifiSuggestion(context, ssid, password, result)
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

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
            builder.setIsInitialAutojoinEnabled(true)
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

    private fun startWifiConfiguration(
        context: Context,
        ssid: String,
        password: String,
        security: String,
        result: MethodChannel.Result
    ) {
        var networks: List<WifiConfiguration>? = null
        var conf: WifiConfiguration? = null
        var found = false
        var netId = -1
        var maxPriority = 0
        val wifiManager =
            context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (!wifiManager.isWifiEnabled) {
            Log.d(WIFI_TAG, "Enabling Wi-Fi")
            if (!wifiManager.setWifiEnabled(true)) {
                result.error("-1", "Can't not enable Wi-Fi", null)
                return
            }
            Thread.sleep(3000)
        }
        try {
            if (ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                networks = wifiManager.configuredNetworks

            }
        } catch (e: SecurityException) {
            e.message?.let { Log.e(WIFI_TAG, it) }
        }

        if (null != networks) {
            for (network in networks) {
                if (network.SSID != null && network.SSID == "\"" + ssid + "\"") {
                    conf = network
                    found = true
                    netId = network.networkId
                    if (network.priority > maxPriority) {
                        maxPriority = network.priority
                    }
                }
            }
        }

        if (conf == null) {
            conf = WifiConfiguration()
        } else {
            conf.allowedAuthAlgorithms.clear()
            conf.allowedGroupCiphers.clear()
            conf.allowedKeyManagement.clear()
            conf.allowedPairwiseCiphers.clear()
            conf.allowedProtocols.clear()
        }
        conf.SSID = "\"" + ssid + "\""
        conf.priority = maxPriority + 1

        if ("WEP".equals(security)) {
            conf.wepKeys[0] = password
            conf.wepTxKeyIndex = 0
            conf.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.SHARED)
            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.WEP40)
            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.WEP104)
            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.CCMP)
            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
        } else if ("WPA".equals(security)) {
            conf.preSharedKey = "\"" + password + "\""
            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.TKIP)
            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.CCMP)
            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK)
            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_EAP)
            conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.TKIP)
            conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.CCMP)
            conf.allowedProtocols.set(WifiConfiguration.Protocol.RSN)
            conf.allowedProtocols.set(WifiConfiguration.Protocol.WPA)
        } else if ("OPEN".equals(security)) {
            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
        }

        conf.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.OPEN)
        conf.status = WifiConfiguration.Status.ENABLED

        if (!found) {
            Log.d(WIFI_TAG, "Adding new network \"$ssid\"")
            netId = wifiManager.addNetwork(conf)
        }
        if (netId == -1) {
            Log.d(WIFI_TAG, "Updating network configuration for \"$ssid\"")
            netId = wifiManager.updateNetwork(conf)
        }
        if (netId == -1) {
            Log.d(WIFI_TAG, "Exiting, we can't find a network id")
            result.error("-1", "Can't find a network id", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) { // API 26
            wifiManager.disableNetwork(netId);
        }

        wifiManager.enableNetwork(netId, true)
        if (!wifiManager.saveConfiguration()) {
            result.error("-2", "Can't save wifi configuration", null)
            return
        }
        if (!wifiManager.reconnect()) {
            result.error("-2", "Can't reconnect to the wifi that set", null)
            return
        }
        result.success(true)
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
