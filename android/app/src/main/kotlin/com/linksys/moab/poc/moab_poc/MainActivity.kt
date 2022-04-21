package com.linksys.moab.poc.moab_poc

import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.linksys.native.channel.wifi.connect"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "connectToWiFi") {
                startWifiQRCodeScanner(this)
            } else {
                result.notImplemented()
            }
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.Q)
    private fun startWifiQRCodeScanner(context: Context) {
        val INTENT_ACTION_WIFI_QR_SCANNER = "android.settings.WIFI_DPP_ENROLLEE_QR_CODE_SCANNER"
        val wifiManager: WifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (wifiManager.isEasyConnectSupported) {
            val intent = Intent(INTENT_ACTION_WIFI_QR_SCANNER)
            startActivityForResult(intent, 5000)
        }
    }
}
