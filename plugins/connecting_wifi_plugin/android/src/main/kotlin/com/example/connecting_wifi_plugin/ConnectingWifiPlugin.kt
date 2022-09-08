package com.example.connecting_wifi_plugin

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** ConnectingWifiPlugin */
class ConnectingWifiPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var activity : Activity? = null

  private val WIFI_TAG = "WIFI CHANNEL"

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.linksys.native.channel.wifi.connect")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "connectToWiFi") {
      val ssid = call.argument<String>("ssid") ?: ""
      val password = call.argument<String>("password") ?: ""
      val security = call.argument<String>("security") ?: "OPEN"
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        startWifiQRCodeScanner(activity?.baseContext, ssid, password, result)
      } else {
        startWifiConfiguration(activity?.baseContext, ssid, password, security, result)
      }
    } else if (call.method == "checkAndroidVersionUnderTen") {
      result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.Q)
    } else if (call.method == "isAndroidTenAndSupportEasyConnect") {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        result.success(isSupportEasyConnected())
      } else {
        result.success(false)
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  @RequiresApi(api = Build.VERSION_CODES.Q)
  private fun isSupportEasyConnected(): Boolean {
    val wifiManager: WifiManager =
      activity?.applicationContext?.getSystemService(Context.WIFI_SERVICE) as WifiManager
    return wifiManager.isEasyConnectSupported
  }

  @RequiresApi(api = Build.VERSION_CODES.Q)
  private fun startWifiQRCodeScanner(context: Context?, ssid: String, password: String, result: Result) {
    val INTENT_ACTION_WIFI_QR_SCANNER = "android.settings.WIFI_DPP_ENROLLEE_QR_CODE_SCANNER"
    val wifiManager: WifiManager =
      context?.applicationContext?.getSystemService(Context.WIFI_SERVICE) as WifiManager
    if (wifiManager.isEasyConnectSupported) {
      val intent = Intent(INTENT_ACTION_WIFI_QR_SCANNER)
      activity?.startActivityForResult(intent, 5000)
      result.success(true)
    } else {
      Log.d(WIFI_TAG, "Not Support Easy Connect, fall back to wifi suggestion")
      startWifiSuggestion(context, ssid, password, result)
    }
  }

  @SuppressLint("MissingPermission")
  @RequiresApi(api = Build.VERSION_CODES.Q)
  private fun startWifiSuggestion(
    context: Context?,
    ssid: String,
    password: String,
    result: Result
  ) {
    // Optional (Wait for post connection broadcast to one of your suggestions)
    val intentFilter = IntentFilter(WifiManager.ACTION_WIFI_NETWORK_SUGGESTION_POST_CONNECTION)

    val broadcastReceiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context, intent: Intent) {
        Log.d("test", "onReceive: ${intent.action}")

        if (!intent.action.equals(WifiManager.ACTION_WIFI_NETWORK_SUGGESTION_POST_CONNECTION)) {
          return
        }
        // do post connect processing here
//                print("onReceive: Post connect processing")
//                result.success(true)
      }
    }
    context?.registerReceiver(broadcastReceiver, intentFilter)

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
      context?.applicationContext?.getSystemService(Context.WIFI_SERVICE) as WifiManager

    val status = wifiManager.addNetworkSuggestions(suggestionsList)
    if (status != WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS) {
      // do error handling here
      result.success(false)
    } else {
      result.success(true)
    }
  }


  @Suppress("DEPRECATION")
  private fun startWifiConfiguration(
    context: Context?,
    ssid: String,
    password: String,
    security: String,
    result: Result
  ) {
    var networks: List<WifiConfiguration>? = null
    var conf: WifiConfiguration? = null
    var found = false
    var netId = -1
    var maxPriority = 0
    val wifiManager =
      context?.applicationContext?.getSystemService(Context.WIFI_SERVICE) as WifiManager
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

    if ("WEP" == security) {
      conf.wepKeys[0] = password
      conf.wepTxKeyIndex = 0
      conf.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.SHARED)
      conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.WEP40)
      conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.WEP104)
      conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.CCMP)
      conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
    } else if ("WPA" == security) {
      conf.preSharedKey = "\"" + password + "\""
      conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.TKIP)
      conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.CCMP)
      conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK)
      conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_EAP)
      conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.TKIP)
      conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.CCMP)
      conf.allowedProtocols.set(WifiConfiguration.Protocol.RSN)
      conf.allowedProtocols.set(WifiConfiguration.Protocol.WPA)
    } else if ("OPEN" == security) {
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
      wifiManager.disableNetwork(netId)
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

  // Activity aware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  // Activity result plugin
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    return false
  }
}
