package com.example.remind_spend.security

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

// ─────────────────────────────────────────────────────────────────────────────
// SecurityManager — Fixed
//
// Bug cũ: getDatabasePassphrase() gọi encrypt() mỗi lần
//         → encrypt() tạo IV mới mỗi lần
//         → passphrase thay đổi mỗi lần app restart
//         → SQLCipher: "file is not a database"
//
// Fix: passphrase là 32 random bytes, generate 1 lần, lưu vào
//      EncryptedSharedPreferences (AES256-GCM, backed by Android Keystore).
//      Các lần sau chỉ đọc ra — không generate lại.
//
// Key hierarchy:
//   Android Keystore
//     └── MasterKey (AES256-GCM)
//           └── EncryptedSharedPreferences
//                 ├── db_passphrase  → 32 random bytes (Base64)  ← STABLE
//                 └── (các field encrypt khác nếu cần)
// ─────────────────────────────────────────────────────────────────────────────
class SecurityManager(context: Context) {

    companion object {
        private const val KEY_ALIAS        = "remind_spend_master_key_v1"
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val TRANSFORMATION   = "AES/GCM/NoPadding"
        private const val GCM_TAG_LENGTH   = 128
        private const val PREFS_NAME       = "remind_spend_secure_prefs"
        private const val PREF_DB_PASSPHRASE = "db_passphrase_v1"
    }

    // EncryptedSharedPreferences — dùng MasterKey từ Android Keystore
    private val encryptedPrefs by lazy {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    // Keystore key — chỉ dùng cho encrypt/decrypt content notification
    private val keyStore: KeyStore =
        KeyStore.getInstance(KEYSTORE_PROVIDER).also { it.load(null) }

    // ─── Database Passphrase ──────────────────────────────────────────────────
    // STABLE: generate 1 lần, lưu vào EncryptedSharedPreferences
    // Các lần sau đọc ra đúng passphrase cũ → SQLCipher mở được DB

    fun getDatabasePassphrase(): ByteArray {
        val existing = encryptedPrefs.getString(PREF_DB_PASSPHRASE, null)
        if (existing != null) {
            return Base64.decode(existing, Base64.NO_WRAP)
        }

        // Lần đầu: generate 32 random bytes
        val passphrase = ByteArray(32).also { SecureRandom().nextBytes(it) }
        encryptedPrefs.edit()
            .putString(PREF_DB_PASSPHRASE, Base64.encodeToString(passphrase, Base64.NO_WRAP))
            .apply()

        return passphrase
    }

    // ─── Field-level Encryption (cho notification content) ────────────────────
    // Dùng Keystore key riêng — không liên quan đến DB passphrase

    fun encrypt(plaintext: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateContentKey())
        val iv = cipher.iv
        val ciphertext = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        // Format: Base64(iv):Base64(ciphertext)
        return "${Base64.encodeToString(iv, Base64.NO_WRAP)}:${Base64.encodeToString(ciphertext, Base64.NO_WRAP)}"
    }

    fun decrypt(encrypted: String): String {
        val parts = encrypted.split(":")
        require(parts.size == 2) { "Invalid encrypted format" }
        val iv         = Base64.decode(parts[0], Base64.NO_WRAP)
        val ciphertext = Base64.decode(parts[1], Base64.NO_WRAP)
        val cipher     = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateContentKey(), GCMParameterSpec(GCM_TAG_LENGTH, iv))
        return String(cipher.doFinal(ciphertext), Charsets.UTF_8)
    }

    private fun getOrCreateContentKey(): SecretKey {
        // KEY_ALIAS riêng cho content encryption — không dùng chung với MasterKey
        val contentAlias = "${KEY_ALIAS}_content"
        keyStore.getKey(contentAlias, null)?.let { return it as SecretKey }

        val kg = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER)
        kg.init(
            KeyGenParameterSpec.Builder(
                contentAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .setUserAuthenticationRequired(false)
                .build()
        )
        return kg.generateKey()
    }
}