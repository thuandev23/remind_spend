package com.example.remind_spend.security

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

// Instrumented test — cần Android Keystore (emulator hoặc real device)
@RunWith(AndroidJUnit4::class)
class SecurityManagerTest {

    private lateinit var manager: SecurityManager

    @Before
    fun setup() {
        manager = SecurityManager()
    }

    @Test
    fun encrypt_then_decrypt_returns_original() {
        val original = "Giao dịch -50,000 VND"
        val encrypted = manager.encrypt(original)
        val decrypted = manager.decrypt(encrypted)
        assertEquals(original, decrypted)
    }

    @Test
    fun encrypted_output_is_not_plaintext() {
        val original = "secret_data_12345"
        val encrypted = manager.encrypt(original)
        assertFalse(encrypted.contains(original))
    }

    @Test
    fun each_encrypt_produces_different_ciphertext() {
        val text = "same_input"
        val enc1 = manager.encrypt(text)
        val enc2 = manager.encrypt(text)
        // IV khác nhau mỗi lần → ciphertext phải khác
        assertNotEquals(enc1, enc2)
        // Nhưng decrypt đều ra cùng plaintext
        assertEquals(text, manager.decrypt(enc1))
        assertEquals(text, manager.decrypt(enc2))
    }

    @Test
    fun getDatabasePassphrase_returns_32_bytes() {
        val passphrase = manager.getDatabasePassphrase()
        assertEquals(32, passphrase.size)
    }

    @Test
    fun getDatabasePassphrase_is_stable_across_calls() {
        val p1 = manager.getDatabasePassphrase()
        val p2 = manager.getDatabasePassphrase()
        assertArrayEquals(p1, p2)
    }

    @Test
    fun decrypt_invalid_format_throws_exception() {
        try {
            manager.decrypt("not_valid_format_no_colon")
            fail("Should have thrown IllegalArgumentException")
        } catch (e: IllegalArgumentException) {
            assertTrue(e.message?.contains("Invalid encrypted format") == true)
        }
    }

    @Test
    fun encrypt_empty_string() {
        val encrypted = manager.encrypt("")
        val decrypted = manager.decrypt(encrypted)
        assertEquals("", decrypted)
    }

    @Test
    fun encrypt_unicode_vietnamese_text() {
        val text = "Số dư tài khoản: 5.000.000 đồng"
        val encrypted = manager.encrypt(text)
        val decrypted = manager.decrypt(encrypted)
        assertEquals(text, decrypted)
    }
}
