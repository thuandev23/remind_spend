package com.example.remind_spend.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.concurrent.atomic.AtomicInteger

object LocalNotificationHelper {

    const val CHANNEL_ID = "bank_transactions"
    private const val TAG = "LocalNotifHelper"

    private val notifIdCounter = AtomicInteger(1000)

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Giao dịch ngân hàng",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Thông báo khi phát hiện giao dịch mới"
            setShowBadge(true)
        }
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(channel)
    }

    fun show(context: Context, bankId: String, amount: Long, sign: String) {
        val prefix = if (sign == "debit") "-" else "+"
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(bankId.uppercase())
            .setContentText("$prefix${formatAmount(amount)}đ")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(notifIdCounter.getAndIncrement(), notification)
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS not granted on Android 13+ — silent
            Log.d(TAG, "POST_NOTIFICATIONS not granted, skipping")
        }
    }

    fun showCustom(context: Context, title: String, body: String) {
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(notifIdCounter.getAndIncrement(), notification)
        } catch (e: SecurityException) {
            Log.d(TAG, "POST_NOTIFICATIONS not granted, skipping")
        }
    }

    private fun formatAmount(amount: Long): String = String.format("%,d", amount)
}
