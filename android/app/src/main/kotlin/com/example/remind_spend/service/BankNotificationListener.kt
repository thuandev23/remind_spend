package com.example.remind_spend.service

import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.example.remind_spend.config.RegexConfigLoader
import com.example.remind_spend.db.AppDatabase
import com.example.remind_spend.db.IdempotencyEntry
import com.example.remind_spend.db.PendingTransaction
import com.example.remind_spend.notification.LocalNotificationHelper
import com.example.remind_spend.security.SecurityManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.io.File

class BankNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "BankNotifListener"
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    // SecurityManager nhận context — không dùng object singleton
    private val securityManager by lazy { SecurityManager(applicationContext) }

    private val db by lazy {
        val passphrase = securityManager.getDatabasePassphrase()
        try {
            AppDatabase.getInstance(applicationContext, passphrase)
        } catch (e: Exception) {
            // Nếu DB corrupt (do bug cũ passphrase thay đổi) → xóa và tạo lại
            Log.e(TAG, "DB open failed, wiping and recreating: ${e.message}")
            wipeDatabase()
            AppDatabase.getInstance(applicationContext, passphrase)
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "Listener connected")
        serviceScope.launch {
            runCatching {
                RegexConfigLoader.updateFromConfig(db)
            }.onFailure { e ->
                Log.w(TAG, "Config load failed on connect: $e")
                // Không crash — tiếp tục dùng hardcoded fallback
            }
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        val packageName = sbn.packageName ?: return
        val rule = RegexConfigLoader.findRuleForPackage(packageName) ?: return

        val text = extractText(sbn.notification?.extras)
        if (text.isEmpty()) return

        val amount = RegexConfigLoader.parseAmount(text, rule) ?: run {
            Log.w(TAG, "No regex match: pkg=$packageName text=${text.take(80)}")
            return
        }

        val idempotencyKey = NotificationProcessor.buildIdempotencyKey(
            packageName, amount, sbn.postTime
        )

        serviceScope.launch {
            runCatching {
                val nowMs = System.currentTimeMillis()

                db.idempotencyCacheDao().purgeExpired(nowMs)

                if (db.idempotencyCacheDao().exists(idempotencyKey, nowMs) > 0L) {
                    Log.d(TAG, "Duplicate dropped: $idempotencyKey")
                    return@launch
                }

                db.idempotencyCacheDao().put(
                    IdempotencyEntry(
                        key = idempotencyKey,
                        expiresAt = nowMs + NotificationProcessor.IDEMPOTENCY_TTL_MS
                    )
                )

                val rowId = db.pendingTransactionDao().enqueue(
                    PendingTransaction(
                        id = idempotencyKey,
                        packageName = packageName,
                        bankId = rule.bankId,
                        rawAmount = amount,
                        sign = rule.sign,
                        encryptedContent = securityManager.encrypt(text),
                        timestampMs = sbn.postTime,
                        createdAt = nowMs
                    )
                )
                if (rowId != -1L) {
                    Log.i(TAG, "Enqueued: ${rule.bankId} ${amount}đ [${rule.sign}]")
                    LocalNotificationHelper.show(applicationContext, rule.bankId, amount, rule.sign)
                }
            }.onFailure { e ->
                Log.e(TAG, "Failed to process notification", e)
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) = Unit

    override fun onDestroy() {
        serviceScope.cancel()
        super.onDestroy()
    }

    private fun extractText(extras: Bundle?): String {
        extras ?: return ""
        return buildString {
            extras.getCharSequence("android.title")?.let { append(it); append(" ") }
            (extras.getCharSequence("android.bigText")
                ?: extras.getCharSequence("android.text"))
                ?.let { append(it) }
        }.trim()
    }

    // Xóa DB file bị corrupt — chỉ dùng khi open fail
    // Data trong queue bị mất, nhưng không crash app
    private fun wipeDatabase() {
        AppDatabase.destroyInstance()
        val dbFile = applicationContext.getDatabasePath("remind_spend.db")
        listOf(dbFile, File("${dbFile.path}-shm"), File("${dbFile.path}-wal"))
            .forEach { it.delete() }
        Log.w(TAG, "Database wiped due to open failure")
    }
}