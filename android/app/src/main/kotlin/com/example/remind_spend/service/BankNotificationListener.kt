package com.example.remind_spend.service

import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.example.remind_spend.config.RegexConfigLoader
import com.example.remind_spend.db.AppDatabase
import com.example.remind_spend.db.IdempotencyEntry
import com.example.remind_spend.db.PendingTransaction
import com.example.remind_spend.security.SecurityManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class BankNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "BankNotifListener"
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val securityManager by lazy { SecurityManager() }
    private val db by lazy {
        AppDatabase.getInstance(applicationContext, securityManager.getDatabasePassphrase())
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        serviceScope.launch {
            runCatching {
                RegexConfigLoader.updateFromConfig(db)
            }.onFailure { e ->
                Log.w(TAG, "Config load failed on connect: $e")
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

        val idempotencyKey = NotificationProcessor.buildIdempotencyKey(packageName, amount, sbn.postTime)

        serviceScope.launch {
            runCatching {
                val nowMs = System.currentTimeMillis()

                // Purge stale entries before checking — keeps table lean
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
            // Prefer bigText (expanded) over text (collapsed) for richer content
            (extras.getCharSequence("android.bigText")
                ?: extras.getCharSequence("android.text"))
                ?.let { append(it) }
        }.trim()
    }
}
