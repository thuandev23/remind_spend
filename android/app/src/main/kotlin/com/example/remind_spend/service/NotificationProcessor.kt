package com.example.remind_spend.service

import java.security.MessageDigest

object NotificationProcessor {

    const val IDEMPOTENCY_TTL_MS = 24L * 60 * 60 * 1000   // 24h
    private const val DEDUP_WINDOW_MS = 5_000L              // 5s dedup window

    // Key = SHA256(packageName + "_" + amount + "_" + ⌊timestampMs / 5000⌋)
    // Notifications fired within 5s for the same pkg+amount are treated as duplicates.
    fun buildIdempotencyKey(packageName: String, amount: Long, timestampMs: Long): String {
        val window = timestampMs / DEDUP_WINDOW_MS
        val input = "${packageName}_${amount}_${window}"
        val hash = MessageDigest.getInstance("SHA-256")
            .digest(input.toByteArray(Charsets.UTF_8))
        return hash.joinToString("") { "%02x".format(it) }
    }
}
