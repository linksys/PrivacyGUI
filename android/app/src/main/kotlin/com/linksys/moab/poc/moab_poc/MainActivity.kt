package com.linksys.moab.poc.moab_poc

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import android.provider.Settings.ACTION_WIFI_ADD_NETWORKS
import android.provider.Settings.EXTRA_WIFI_NETWORK_LIST
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.linksys.native.channel.wifi.connect"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
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
    }

    @RequiresApi(api = Build.VERSION_CODES.Q)
    private fun startWifiQRCodeScanner(context: Context, result: MethodChannel.Result) {
        val INTENT_ACTION_WIFI_QR_SCANNER = "android.settings.WIFI_DPP_ENROLLEE_QR_CODE_SCANNER"
        val wifiManager: WifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
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
    private fun startWifiSuggestion(context: Context, ssid: String, password: String, result: MethodChannel.Result) {
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

        val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

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
}
