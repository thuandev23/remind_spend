package com.example.remind_spend.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import net.sqlcipher.database.SupportFactory

@Database(
    entities = [PendingTransaction::class, IdempotencyEntry::class, RegexConfigEntry::class],
    version = 3,
    exportSchema = true
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun pendingTransactionDao(): PendingTransactionDao
    abstract fun idempotencyCacheDao(): IdempotencyCacheDao
    abstract fun regexConfigDao(): RegexConfigDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL(
                    "ALTER TABLE regex_config_cache ADD COLUMN package_names_json TEXT NOT NULL DEFAULT '[]'"
                )
                database.execSQL(
                    "ALTER TABLE regex_config_cache ADD COLUMN amount_group INTEGER NOT NULL DEFAULT 1"
                )
                database.execSQL(
                    "ALTER TABLE regex_config_cache ADD COLUMN sign TEXT NOT NULL DEFAULT 'debit'"
                )
            }
        }

        // Drop + recreate regex_config_cache with composite PK (bank_id, sign).
        // Safe: the table is a pure cache — Tier 3 hardcoded rules always cover cold start.
        val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("DROP TABLE IF EXISTS regex_config_cache")
                database.execSQL("""
                    CREATE TABLE regex_config_cache (
                        bank_id TEXT NOT NULL,
                        sign TEXT NOT NULL,
                        package_names_json TEXT NOT NULL,
                        patterns_json TEXT NOT NULL,
                        amount_group INTEGER NOT NULL DEFAULT 1,
                        version INTEGER NOT NULL,
                        fetched_at INTEGER NOT NULL,
                        PRIMARY KEY (bank_id, sign)
                    )
                """.trimIndent())
            }
        }

        fun getInstance(context: Context, passphrase: ByteArray): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: buildDatabase(context, passphrase).also { INSTANCE = it }
            }
        }

        private fun buildDatabase(context: Context, passphrase: ByteArray): AppDatabase {
            val factory = SupportFactory(passphrase)
            return Room.databaseBuilder(
                context.applicationContext,
                AppDatabase::class.java,
                "remind_spend.db"
            )
                .openHelperFactory(factory)
                .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
                .enableMultiInstanceInvalidation()
                // Không dùng fallbackToDestructiveMigration — mất queue = mất data user
                .build()
        }

        fun destroyInstance() {
            INSTANCE?.close()
            INSTANCE = null
        }
    }
}
