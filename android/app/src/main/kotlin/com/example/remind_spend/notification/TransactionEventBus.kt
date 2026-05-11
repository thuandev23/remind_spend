package com.example.remind_spend.notification

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/// Singleton bus: BankNotificationListener → NativeBridgePlugin → Flutter.
///
/// BankNotificationListener runs in a background coroutine; EventSink must be
/// called on the main thread. This object handles the dispatch automatically.
object TransactionEventBus {

    @Volatile
    private var _sink: EventChannel.EventSink? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    fun setSink(sink: EventChannel.EventSink?) {
        _sink = sink
    }

    fun notifyNewTransaction() {
        val sink = _sink ?: return
        mainHandler.post { sink.success("new_transaction") }
    }
}
