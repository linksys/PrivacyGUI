package com.example.sms_receiver_plugin

import android.app.Activity
import android.content.*
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat.startActivityForResult
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry

/** SmsReceiverPlugin */
class SmsReceiverPlugin : FlutterPlugin,  ActivityAware,
    EventChannel.StreamHandler,
    PluginRegistry.ActivityResultListener {

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: EventChannel
    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null

    private val SMS_CONSENT_REQUEST = 2  // Set to an unused request code

    private var smsVerificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (SmsRetriever.SMS_RETRIEVED_ACTION == intent.action) {
                val extras = intent.extras
                val smsRetrieverStatus = extras?.get(SmsRetriever.EXTRA_STATUS) as Status
                Log.d("SMS retriever", "receive sms")
                when (smsRetrieverStatus.statusCode) {
                    CommonStatusCodes.SUCCESS -> {
                        // Get consent intent
                        extras.getParcelable<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT)
                            ?.let { smsIntent ->
                                activity?.let { activity ->
                                    try {
                                        // Start activity to show consent dialog to user, activity must be started in
                                        // 5 minutes, otherwise you'll receive another TIMEOUT intent
                                        startActivityForResult(
                                            activity,
                                            smsIntent,
                                            SMS_CONSENT_REQUEST,
                                            null
                                        )
                                    } catch (e: ActivityNotFoundException) {
                                        // Handle the exception ...
                                    }
                                }
                            }

                    }
                    CommonStatusCodes.TIMEOUT -> {
                        // Time out occurred, handle the error.
                    }
                }
            }
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = EventChannel(flutterPluginBinding.binaryMessenger, "sms_receiver_plugin")
        channel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setStreamHandler(null)
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            // ...
            SMS_CONSENT_REQUEST -> {
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
                    eventSink?.success(message)
                } else {
                    // Consent denied. User can type OTC manually.
                }
                return true
            }
        }
        return false
    }

    // Activity aware
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d("SMS retriever", "onAttachedToActivity")
        println("SMS retriever: onAttachedToActivity")

        activity = binding.activity
        binding.addActivityResultListener(this)
        val intentFilter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
        activity?.registerReceiver(
            smsVerificationReceiver,
            intentFilter,
            SmsRetriever.SEND_PERMISSION,
            null
        )
        activity?.let { activity ->
            // Start listening for SMS User Consent broadcasts from senderPhoneNumber
            // The Task<Void> will be successful if SmsRetriever was able to start
            // SMS User Consent, and will error if there was an error starting.
            val task = SmsRetriever.getClient(activity).startSmsUserConsent(null)
            task.addOnSuccessListener {
                Log.d("SMS retriever", "success listening!")
            }
            task.addOnFailureListener { Log.d("SMS retriever", "failed listening!") }
        }

    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity?.unregisterReceiver(smsVerificationReceiver)
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        val intentFilter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
        activity?.registerReceiver(
            smsVerificationReceiver,
            intentFilter,
            SmsRetriever.SEND_PERMISSION,
            null
        )
    }

    override fun onDetachedFromActivity() {
        activity?.unregisterReceiver(smsVerificationReceiver)
        activity = null
    }

    // Stream handler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
    }
}
