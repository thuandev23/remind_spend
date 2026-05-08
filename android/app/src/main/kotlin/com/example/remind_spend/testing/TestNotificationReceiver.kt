package com.example.remind_spend.testing

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.remind_spend.config.RegexConfigLoader
import com.example.remind_spend.db.AppDatabase
import com.example.remind_spend.db.IdempotencyEntry
import com.example.remind_spend.db.PendingTransaction
import com.example.remind_spend.security.SecurityManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * ADB-triggered receiver để test pipeline mà không cần cài APK ngân hàng thật.
 * Chỉ nhận được qua `adb shell am broadcast` (yêu cầu android.permission.DUMP).
 *
 * Usage:
 *   adb shell am broadcast \
 *     -a com.example.remind_spend.TEST_NOTIF \
 *     --es pkg "com.mbmobile" \
 *     --es text "chi 120,000đ Số dư: 5,000,000đ"
 */
class TestNotificationReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION = "com.example.remind_spend.TEST_NOTIF"
        private const val TAG = "TestNotifReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val pkg  = intent.getStringExtra("pkg")  ?: run { Log.w(TAG, "Missing extra: pkg");  return }
        val text = intent.getStringExtra("text") ?: run { Log.w(TAG, "Missing extra: text"); return }

        val rule = RegexConfigLoader.findRuleForPackage(pkg) ?: run {
            Log.w(TAG, "No rule for package: $pkg")
            return
        }

        val amount = RegexConfigLoader.parseAmount(text, rule) ?: run {
            Log.w(TAG, "No amount matched — pkg=$pkg text=${text.take(80)}")
            return
        }

        val sm   = SecurityManager(context)
        val db   = AppDatabase.getInstance(context, sm.getDatabasePassphrase())
        val nowMs = System.currentTimeMillis()
        val id    = "test_${pkg}_$nowMs"

        CoroutineScope(Dispatchers.IO).launch {
            runCatching {
                db.idempotencyCacheDao().put(
                    IdempotencyEntry(key = id, expiresAt = nowMs + 86_400_000L)
                )
                val rowId = db.pendingTransactionDao().enqueue(
                    PendingTransaction(
                        id               = id,
                        packageName      = pkg,
                        bankId           = rule.bankId,
                        rawAmount        = amount,
                        sign             = rule.sign,
                        encryptedContent = sm.encrypt(text),
                        timestampMs      = nowMs,
                        createdAt        = nowMs
                    )
                )
                if (rowId != -1L) {
                    Log.i(TAG, "Enqueued: bankId=${rule.bankId} amount=${amount}đ sign=${rule.sign}")
                } else {
                    Log.d(TAG, "Duplicate ignored: $id")
                }
            }.onFailure { e ->
                Log.e(TAG, "Failed to enqueue test tx", e)
            }
        }
    }
}
