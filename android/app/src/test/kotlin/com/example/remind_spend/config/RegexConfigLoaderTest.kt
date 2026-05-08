package com.example.remind_spend.config

import org.junit.Assert.*
import org.junit.Test

class RegexConfigLoaderTest {

    // ── findRuleForPackage ───────────────────────────────────────────────────

    @Test
    fun `findRuleForPackage returns correct rule for VCB`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.VCB")
        assertNotNull(rule)
        assertEquals("vcb", rule!!.bankId)
    }

    @Test
    fun `findRuleForPackage is case-insensitive`() {
        val rule = RegexConfigLoader.findRuleForPackage("COM.VCB")
        assertNotNull(rule)
        assertEquals("vcb", rule!!.bankId)
    }

    @Test
    fun `findRuleForPackage returns null for unknown package`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.unknown.app")
        assertNull(rule)
    }

    @Test
    fun `findRuleForPackage returns MoMo rule`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.mservice.momotransfer")
        assertNotNull(rule)
        assertEquals("momo", rule!!.bankId)
    }

    // ── parseAmount — VCB ───────────────────────────────────────────────────

    @Test
    fun `parseAmount VCB GD debit format`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.VCB")!!
        val amount = RegexConfigLoader.parseAmount("GD: -50,000VND TK...", rule)
        assertEquals(50000L, amount)
    }

    @Test
    fun `parseAmount VCB Debit format`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.VCB")!!
        val amount = RegexConfigLoader.parseAmount("Debit: 1,500,000 VND", rule)
        assertEquals(1500000L, amount)
    }

    @Test
    fun `parseAmount VCB so du format`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.VCB")!!
        val amount = RegexConfigLoader.parseAmount("So du TK 1234: 5,000,000VND", rule)
        assertEquals(5000000L, amount)
    }

    // ── parseAmount — MB ─────────────────────────────────────────────────────

    @Test
    fun `parseAmount MB chi format`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.mbmobile")!!
        val amount = RegexConfigLoader.parseAmount("Giao dịch chi: 200,000 đ tai ...", rule)
        assertEquals(200000L, amount)
    }

    @Test
    fun `parseAmount MB so du format`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.mbmobile")!!
        val amount = RegexConfigLoader.parseAmount("Số dư: 5.000.000 đ", rule)
        // dấu chấm bị strip → 5000000
        assertEquals(5000000L, amount)
    }

    // ── parseAmount — MoMo ───────────────────────────────────────────────────

    @Test
    fun `parseAmount MoMo ban da chi format`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.mservice.momotransfer")!!
        val amount = RegexConfigLoader.parseAmount("Bạn đã chi 50.000đ cho dịch vụ X", rule)
        assertEquals(50000L, amount)
    }

    @Test
    fun `parseAmount MoMo thanh toan format`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.mservice.momotransfer")!!
        val amount = RegexConfigLoader.parseAmount("thanh toán 100,000đ", rule)
        assertEquals(100000L, amount)
    }

    // ── parseAmount — edge cases ─────────────────────────────────────────────

    @Test
    fun `parseAmount returns null for unrecognized text`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.VCB")!!
        val amount = RegexConfigLoader.parseAmount("Thông báo bảo mật tài khoản", rule)
        assertNull(amount)
    }

    @Test
    fun `parseAmount handles large amount correctly`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.VCB")!!
        val amount = RegexConfigLoader.parseAmount("Debit: 100,000,000 VND", rule)
        assertEquals(100000000L, amount)
    }

    @Test
    fun `parseAmount strips dots and commas before parsing`() {
        val rule = RegexConfigLoader.findRuleForPackage("com.mbmobile")!!
        // "So du: 10.500.000" → strip dots → 10500000
        val amount = RegexConfigLoader.parseAmount("So du: 10.500.000", rule)
        assertEquals(10500000L, amount)
    }

    // ── hardcoded rules completeness ─────────────────────────────────────────

    @Test
    fun `all hardcoded rules have non-empty patterns`() {
        RegexConfigLoader.hardcodedRules.forEach { rule ->
            assertTrue("${rule.bankId} has no patterns", rule.patterns.isNotEmpty())
        }
    }

    @Test
    fun `all hardcoded rules have valid sign`() {
        val validSigns = setOf("debit", "credit")
        RegexConfigLoader.hardcodedRules.forEach { rule ->
            assertTrue("${rule.bankId} has invalid sign: ${rule.sign}", rule.sign in validSigns)
        }
    }

    @Test
    fun `all hardcoded rules have non-empty packageNames`() {
        RegexConfigLoader.hardcodedRules.forEach { rule ->
            assertTrue("${rule.bankId} has no package names", rule.packageNames.isNotEmpty())
        }
    }

    // ── updateActiveRules ────────────────────────────────────────────────────

    @Test
    fun `updateActiveRules overrides hardcoded rules`() {
        val custom = listOf(
            BankRule(
                bankId = "custom_bank",
                packageNames = listOf("com.custom"),
                patterns = listOf("([0-9]+)"),
                amountGroup = 1,
                sign = "debit"
            )
        )
        RegexConfigLoader.updateActiveRules(custom)
        try {
            val rule = RegexConfigLoader.findRuleForPackage("com.custom")
            assertNotNull(rule)
            assertEquals("custom_bank", rule!!.bankId)

            // Hardcoded rule should no longer be found
            val vcbRule = RegexConfigLoader.findRuleForPackage("com.VCB")
            assertNull(vcbRule)
        } finally {
            // Restore hardcoded rules to avoid polluting other tests
            RegexConfigLoader.updateActiveRules(RegexConfigLoader.hardcodedRules)
        }
    }

    @Test
    fun `updateActiveRules with empty list causes findRuleForPackage to return null`() {
        RegexConfigLoader.updateActiveRules(emptyList())
        try {
            val rule = RegexConfigLoader.findRuleForPackage("com.VCB")
            assertNull(rule)
        } finally {
            RegexConfigLoader.updateActiveRules(RegexConfigLoader.hardcodedRules)
        }
    }
}
