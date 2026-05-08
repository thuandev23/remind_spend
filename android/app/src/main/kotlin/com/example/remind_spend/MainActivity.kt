package com.example.remind_spend

import com.example.remind_spend.bridge.NativeBridgePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var bridge: NativeBridgePlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        bridge = NativeBridgePlugin(
            context      = this,
            methodChannel = MethodChannel(messenger, NativeBridgePlugin.METHOD_CHANNEL),
            eventChannel  = EventChannel(messenger, NativeBridgePlugin.EVENT_CHANNEL)
        )
    }

    override fun onDestroy() {
        bridge?.destroy()
        super.onDestroy()
    }
}
