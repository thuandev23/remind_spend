package com.example.remind_spend.service

import org.junit.Assert.*
import org.junit.Test

class NotificationProcessorTest {

    // ── buildIdempotencyKey ─────────────────────────────────────────────────

    @Test
    fun `same package, amount, within 5s window produce same key`() {
        val key1 = NotificationProcessor.buildIdempotencyKey("com.VCB", 50_000L, 1_000L)
        val key2 = NotificationProcessor.buildIdempotencyKey("com.VCB", 50_000L, 4_999L)
        assertEquals(key1, key2)
    }

    @Test
    fun `notifications in different 5s windows produce different keys`() {
        val key1 = NotificationProcessor.buildIdempotencyKey("com.VCB", 50_000L, 4_999L)  // window 0
        val key2 = NotificationProcessor.buildIdempotencyKey("com.VCB", 50_000L, 5_000L)  // window 1
        assertNotEquals(key1, key2)
    }

    @Test
    fun `different packages produce different keys`() {
        val key1 = NotificationProcessor.buildIdempotencyKey("com.VCB", 50_000L, 1_000L)
        val key2 = NotificationProcessor.buildIdempotencyKey("com.mbmobile", 50_000L, 1_000L)
        assertNotEquals(key1, key2)
    }

    @Test
    fun `different amounts produce different keys`() {
        val key1 = NotificationProcessor.buildIdempotencyKey("com.VCB", 50_000L, 1_000L)
        val key2 = NotificationProcessor.buildIdempotencyKey("com.VCB", 100_000L, 1_000L)
        assertNotEquals(key1, key2)
    }

    @Test
    fun `key is 64 lowercase hex characters (SHA-256)`() {
        val key = NotificationProcessor.buildIdempotencyKey("com.VCB", 50_000L, 1_000L)
        assertEquals(64, key.length)
        assertTrue("Key must be lowercase hex: $key", key.all { it.isDigit() || it in 'a'..'f' })
    }

    @Test
    fun `key is deterministic for identical inputs`() {
        val key1 = NotificationProcessor.buildIdempotencyKey("com.mservice.momotransfer", 200_000L, 12_345_678L)
        val key2 = NotificationProcessor.buildIdempotencyKey("com.mservice.momotransfer", 200_000L, 12_345_678L)
        assertEquals(key1, key2)
    }

    @Test
    fun `key changes at exact 5s window boundary`() {
        // t=9999ms → window 1; t=10000ms → window 2
        val key1 = NotificationProcessor.buildIdempotencyKey("com.VCB", 50_000L, 9_999L)
        val key2 = NotificationProcessor.buildIdempotencyKey("com.VCB", 50_000L, 10_000L)
        assertNotEquals(key1, key2)
    }

    @Test
    fun `IDEMPOTENCY_TTL_MS equals 24 hours`() {
        assertEquals(24L * 60 * 60 * 1_000, NotificationProcessor.IDEMPOTENCY_TTL_MS)
    }

    // ── Regression: hash collision resistance ────────────────────────────────

    @Test
    fun `package_1_2 vs package 1_2 do not produce same key`() {
        // Guard against naive string concat without delimiter: "pkg" + "12" + "0" = "pkg120"
        // vs "pkg1" + "2" + "0" = "pkg120" — could collide without clear delimiters.
        // Our format "${pkg}_${amount}_${window}" uses underscores, so these are distinct.
        val key1 = NotificationProcessor.buildIdempotencyKey("com.bank", 120L, 0L)
        val key2 = NotificationProcessor.buildIdempotencyKey("com.bank1", 20L, 0L)
        assertNotEquals(key1, key2)
    }
}
