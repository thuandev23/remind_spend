package com.example.remind_spend.db

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

// Instrumented test — cần emulator hoặc real device
@RunWith(AndroidJUnit4::class)
class AppDatabaseTest {

    private lateinit var db: AppDatabase
    private lateinit var txDao: PendingTransactionDao
    private lateinit var idempotencyDao: IdempotencyCacheDao

    @Before
    fun setup() {
        // In-memory DB — không cần SQLCipher passphrase trong test
        db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()

        txDao = db.pendingTransactionDao()
        idempotencyDao = db.idempotencyCacheDao()
    }

    @After
    fun teardown() {
        db.close()
    }

    // ── PendingTransactionDao ─────────────────────────────────────────────────

    @Test
    fun enqueue_and_getAll() = runTest {
        val tx = makeTx("key1", 50000L)
        txDao.enqueue(tx)
        val all = txDao.getAll()
        assertEquals(1, all.size)
        assertEquals("key1", all[0].id)
        assertEquals(50000L, all[0].rawAmount)
    }

    @Test
    fun enqueue_duplicate_idempotency_key_is_ignored() = runTest {
        val tx1 = makeTx("same_key", 50000L)
        val tx2 = makeTx("same_key", 99999L)  // same key, different amount
        txDao.enqueue(tx1)
        txDao.enqueue(tx2)  // IGNORE strategy — không insert
        val all = txDao.getAll()
        assertEquals(1, all.size)
        assertEquals(50000L, all[0].rawAmount)  // giá trị gốc giữ nguyên
    }

    @Test
    fun dequeueAll_is_atomic_and_clears_queue() = runTest {
        txDao.enqueue(makeTx("k1", 10000L))
        txDao.enqueue(makeTx("k2", 20000L))

        val dequeued = txDao.dequeueAll()
        assertEquals(2, dequeued.size)

        // Queue phải trống sau dequeue
        assertEquals(0L, txDao.count())
    }

    @Test
    fun dequeueAll_on_empty_queue_returns_empty_list() = runTest {
        val result = txDao.dequeueAll()
        assertTrue(result.isEmpty())
    }

    @Test
    fun enqueue_preserves_order_by_created_at() = runTest {
        txDao.enqueue(makeTx("k1", 100L, createdAt = 1000L))
        txDao.enqueue(makeTx("k2", 200L, createdAt = 500L))
        txDao.enqueue(makeTx("k3", 300L, createdAt = 2000L))

        val all = txDao.getAll()
        assertEquals(listOf("k2", "k1", "k3"), all.map { it.id })
    }

    // ── IdempotencyCacheDao ───────────────────────────────────────────────────

    @Test
    fun idempotency_exists_returns_true_for_valid_entry() = runTest {
        val nowMs = System.currentTimeMillis()
        idempotencyDao.put(IdempotencyEntry("key_abc", nowMs + 86_400_000L))
        val count = idempotencyDao.exists("key_abc", nowMs)
        assertEquals(1L, count)
    }

    @Test
    fun idempotency_exists_returns_false_for_expired_entry() = runTest {
        val pastMs = System.currentTimeMillis() - 1000L
        idempotencyDao.put(IdempotencyEntry("key_expired", pastMs))
        val count = idempotencyDao.exists("key_expired", System.currentTimeMillis())
        assertEquals(0, count)
    }

    @Test
    fun purgeExpired_removes_only_expired_entries() = runTest {
        val nowMs = System.currentTimeMillis()
        idempotencyDao.put(IdempotencyEntry("valid", nowMs + 86_400_000L))
        idempotencyDao.put(IdempotencyEntry("expired1", nowMs - 1000L))
        idempotencyDao.put(IdempotencyEntry("expired2", nowMs - 5000L))

        idempotencyDao.purgeExpired(nowMs)

        assertEquals(1, idempotencyDao.exists("valid", nowMs))
        assertEquals(0L, idempotencyDao.exists("expired1", nowMs))
        assertEquals(0L, idempotencyDao.exists("expired2", nowMs))
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun makeTx(
        id: String,
        amount: Long,
        createdAt: Long = System.currentTimeMillis()
    ) = PendingTransaction(
        id = id,
        packageName = "com.VCB",
        bankId = "vcb",
        rawAmount = amount,
        sign = "debit",
        encryptedContent = "encrypted_blob_$id",
        timestampMs = createdAt,
        createdAt = createdAt
    )
}
