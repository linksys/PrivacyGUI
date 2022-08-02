package com.linksys.universal_link_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry


/** UniversalLinkPlugin */
class UniversalLinkPlugin : FlutterPlugin, EventChannel.StreamHandler, ActivityAware,
    PluginRegistry.NewIntentListener {
    private val EVENTS_CHANNEL = "com.linksys.moab/universal_link"

    private var changeReceiver: BroadcastReceiver? = null
    private lateinit var context: Context



    private fun handleIntent(context: Context, intent: Intent) {
        val action = intent.action
        val dataString = intent.dataString

        if (Intent.ACTION_VIEW == action) {
            changeReceiver?.onReceive(context, intent)
        }
    }

    private fun register(messenger: BinaryMessenger, plugin: UniversalLinkPlugin) {
        val eventChannel = EventChannel(messenger, EVENTS_CHANNEL)
        eventChannel.setStreamHandler(plugin)
    }

    private fun createChangReceiver(events: EventChannel.EventSink): BroadcastReceiver {
        return object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val dataString = intent?.dataString

                if (dataString == null) {
                    events.error("UNAVAILABLE_LINK", "Universal link unavailable", null)
                } else {
                    events.success(dataString)
                }
            }
        }
    }

    // Flutter Plugin interface
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        print("onAttachedToEngine")
        this.context = binding.applicationContext
        register(binding.binaryMessenger, this)

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }
    //
    // Stream handler interface
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        changeReceiver = createChangReceiver(events)
    }

    override fun onCancel(arguments: Any?) {
        changeReceiver = null
    }
    //
    // Activity aware interface
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        this.handleIntent(context, binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        handleIntent(context, binding.activity.intent)
    }

    override fun onDetachedFromActivity() {
    }
    // New intent listener interface
    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(context, intent)
        return false
    }
}
