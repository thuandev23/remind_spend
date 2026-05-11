package com.example.remind_spend.db

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "pending_transactions")
data class PendingTransaction(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,

    @ColumnInfo(name = "package_name")
    val packageName: String,

    @ColumnInfo(name = "bank_id")
    val bankId: String,

    @ColumnInfo(name = "raw_amount")
    val rawAmount: Long,          // đơn vị: đồng — không bao giờ Float

    @ColumnInfo(name = "sign")
    val sign: String,             // "debit" | "credit"

    @ColumnInfo(name = "encrypted_content")
    val encryptedContent: String, // AES256-GCM encrypted blob

    @ColumnInfo(name = "timestamp_ms")
    val timestampMs: Long,

    @ColumnInfo(name = "created_at")
    val createdAt: Long,

    @ColumnInfo(name = "retry_count")
    val retryCount: Int = 0
)

@Entity(tableName = "idempotency_cache")
data class IdempotencyEntry(
    @PrimaryKey
    @ColumnInfo(name = "key")
    val key: String,

    @ColumnInfo(name = "expires_at")
    val expiresAt: Long           // epoch ms, TTL 24h → auto-purge
)

@Entity(tableName = "regex_config_cache", primaryKeys = ["bank_id", "sign"])
data class RegexConfigEntry(
    @ColumnInfo(name = "bank_id")
    val bankId: String,

    @ColumnInfo(name = "sign")
    val sign: String,              // "debit" | "credit" — part of composite PK

    @ColumnInfo(name = "package_names_json")
    val packageNamesJson: String,

    @ColumnInfo(name = "patterns_json")
    val patternsJson: String,

    @ColumnInfo(name = "amount_group")
    val amountGroup: Int = 1,

    @ColumnInfo(name = "version")
    val version: Int,

    @ColumnInfo(name = "fetched_at")
    val fetchedAt: Long
)
