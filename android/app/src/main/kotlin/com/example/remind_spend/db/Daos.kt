package com.example.remind_spend.db

import androidx.room.*

@Dao
interface PendingTransactionDao {

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun enqueue(tx: PendingTransaction): Long

    @Query("SELECT * FROM pending_transactions ORDER BY created_at ASC")
    suspend fun getAll(): List<PendingTransaction>

    @Query("DELETE FROM pending_transactions WHERE id IN (:ids)")
    suspend fun deleteByIds(ids: List<String>)

    // Atomic peek + delete — không có race condition
    @Transaction
    suspend fun dequeueAll(): List<PendingTransaction> {
        val items = getAll()
        if (items.isNotEmpty()) deleteByIds(items.map { it.id })
        return items
    }

    @Query("UPDATE pending_transactions SET retry_count = retry_count + 1 WHERE id = :id")
    suspend fun incrementRetry(id: String)

    @Query("SELECT COUNT(*) FROM pending_transactions")
    suspend fun count(): Long
}

@Dao
interface IdempotencyCacheDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun put(entry: IdempotencyEntry)

    @Query("SELECT COUNT(*) FROM idempotency_cache WHERE key = :key AND expires_at > :nowMs")
    suspend fun exists(key: String, nowMs: Long): Long

    @Query("DELETE FROM idempotency_cache WHERE expires_at <= :nowMs")
    suspend fun purgeExpired(nowMs: Long)
}

@Dao
interface RegexConfigDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entry: RegexConfigEntry)

    @Query("SELECT * FROM regex_config_cache")
    suspend fun getAll(): List<RegexConfigEntry>

    @Query("SELECT * FROM regex_config_cache WHERE bank_id = :bankId")
    suspend fun getByBank(bankId: String): List<RegexConfigEntry>
}
