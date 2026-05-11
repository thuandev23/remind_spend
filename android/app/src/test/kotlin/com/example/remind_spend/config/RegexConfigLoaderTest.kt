package com.example.remind_spend.config

import org.junit.Assert.*
import org.junit.Test

class RegexConfigLoaderTest {

    // ── findRulesForPackage ──────────────────────────────────────────────────

    @Test
    fun `findRulesForPackage returns both debit and credit rules for VCB`() {
        val rules = RegexConfigLoader.findRulesForPackage("com.VCB")
        assertTrue(rules.isNotEmpty())
        assertTrue("vcb credit rule missing", rules.any { it.bankId == "vcb" && it.sign == "credit" })
        assertTrue("vcb debit rule missing",  rules.any { it.bankId == "vcb" && it.sign == "debit"  })
    }

    @Test
    fun `findRulesForPackage is case-insensitive`() {
        val rules = RegexConfigLoader.findRulesForPackage("COM.VCB")
        assertTrue(rules.isNotEmpty())
        assertTrue(rules.all { it.bankId == "vcb" })
    }

    @Test
    fun `findRulesForPackage returns empty list for unknown package`() {
        val rules = RegexConfigLoader.findRulesForPackage("com.unknown.app")
        assertTrue(rules.isEmpty())
    }

    @Test
    fun `findRulesForPackage returns MoMo rules`() {
        val rules = RegexConfigLoader.findRulesForPackage("com.mservice.momotransfer")
        assertTrue(rules.isNotEmpty())
        assertTrue(rules.all { it.bankId == "momo" })
    }

    @Test
    fun `findRulesForPackage returns BIDV rules`() {
        val rules = RegexConfigLoader.findRulesForPackage("com.BIDV.SmartBanking")
        assertTrue(rules.isNotEmpty())
        assertTrue(rules.all { it.bankId == "bidv" })
    }

    @Test
    fun `findRulesForPackage returns Vietinbank rules`() {
        val rules = RegexConfigLoader.findRulesForPackage("com.VietinBank.iPay")
        assertTrue(rules.isNotEmpty())
        assertTrue(rules.all { it.bankId == "vtb" })
    }

    // ── parseAmount — VCB debit ──────────────────────────────────────────────

    private fun debitRule(packageName: String) =
        RegexConfigLoader.findRulesForPackage(packageName).first { it.sign == "debit" }

    private fun creditRule(packageName: String) =
        RegexConfigLoader.findRulesForPackage(packageName).first { it.sign == "credit" }

    @Test
    fun `parseAmount VCB GD debit format`() {
        val amount = RegexConfigLoader.parseAmount("GD: -50,000VND TK...", debitRule("com.VCB"))
        assertEquals(50000L, amount)
    }

    @Test
    fun `parseAmount VCB Debit format`() {
        val amount = RegexConfigLoader.parseAmount("Debit: 1,500,000 VND", debitRule("com.VCB"))
        assertEquals(1500000L, amount)
    }

    @Test
    fun `parseAmount VCB GD credit format`() {
        val amount = RegexConfigLoader.parseAmount("GD: +250,000 VND tu NGUYEN VAN A", creditRule("com.VCB"))
        assertEquals(250000L, amount)
    }

    @Test
    fun `parseAmount VCB Credit format`() {
        val amount = RegexConfigLoader.parseAmount("Credit: 500,000 VND", creditRule("com.VCB"))
        assertEquals(500000L, amount)
    }

    @Test
    fun `parseAmount VCB debit does NOT match credit text`() {
        val amount = RegexConfigLoader.parseAmount("GD: +250,000 VND", debitRule("com.VCB"))
        assertNull(amount)
    }

    @Test
    fun `parseAmount VCB credit does NOT match debit text`() {
        val amount = RegexConfigLoader.parseAmount("GD: -250,000 VND", creditRule("com.VCB"))
        assertNull(amount)
    }

    // ── parseAmount — MB ─────────────────────────────────────────────────────

    @Test
    fun `parseAmount MB chi debit`() {
        val amount = RegexConfigLoader.parseAmount("TK 01234 chi 200,000 đ luc 14:30", debitRule("com.mbmobile"))
        assertEquals(200000L, amount)
    }

    @Test
    fun `parseAmount MB giao dich debit`() {
        val amount = RegexConfigLoader.parseAmount("giao dịch 300,000đ thanh cong", debitRule("com.mbmobile"))
        assertEquals(300000L, amount)
    }

    @Test
    fun `parseAmount MB nhan credit`() {
        val amount = RegexConfigLoader.parseAmount("TK 01234 nhận 250,000đ tu NGUYEN VAN A", creditRule("com.mbmobile"))
        assertEquals(250000L, amount)
    }

    @Test
    fun `parseAmount MB cong credit`() {
        val amount = RegexConfigLoader.parseAmount("TK 01234 cộng 100,000đ tu NGUYEN VAN A", creditRule("com.mbmobile"))
        assertEquals(100000L, amount)
    }

    // ── parseAmount — TCB ─────────────────────────────────────────────────────

    @Test
    fun `parseAmount TCB GD debit`() {
        val amount = RegexConfigLoader.parseAmount("GD: -75,000VND tai POS", debitRule("com.techcombank.mb.portal"))
        assertEquals(75000L, amount)
    }

    @Test
    fun `parseAmount TCB GD credit`() {
        val amount = RegexConfigLoader.parseAmount("GD: +75,000VND tu NGUYEN", creditRule("com.techcombank.mb.portal"))
        assertEquals(75000L, amount)
    }

    // ── parseAmount — BIDV ────────────────────────────────────────────────────

    @Test
    fun `parseAmount BIDV giam debit`() {
        val amount = RegexConfigLoader.parseAmount("TK...giam 250,000VND. So du: 5,000,000VND", debitRule("com.BIDV.SmartBanking"))
        assertEquals(250000L, amount)
    }

    @Test
    fun `parseAmount BIDV tang credit`() {
        val amount = RegexConfigLoader.parseAmount("TK...tang 250,000VND. So du: 5,250,000VND", creditRule("com.BIDV.SmartBanking"))
        assertEquals(250000L, amount)
    }

    @Test
    fun `parseAmount BIDV cong credit`() {
        val amount = RegexConfigLoader.parseAmount("TK...cong 500,000VND tu NGUYEN VAN A", creditRule("com.BIDV.SmartBanking"))
        assertEquals(500000L, amount)
    }

    // ── parseAmount — Vietinbank ──────────────────────────────────────────────

    @Test
    fun `parseAmount Vietinbank giam debit dot separator`() {
        // Vietinbank uses dot as thousand separator
        val amount = RegexConfigLoader.parseAmount("TK 0123456789 Giam 250.000 VND. SD 5.000.000 VND", debitRule("com.VietinBank.iPay"))
        assertEquals(250000L, amount)
    }

    @Test
    fun `parseAmount Vietinbank tang credit dot separator`() {
        val amount = RegexConfigLoader.parseAmount("TK 0123456789 Tang 250.000 VND. SD 5.250.000 VND", creditRule("com.VietinBank.iPay"))
        assertEquals(250000L, amount)
    }

    // ── parseAmount — MoMo ───────────────────────────────────────────────────

    @Test
    fun `parseAmount MoMo ban da chi debit`() {
        val amount = RegexConfigLoader.parseAmount("Bạn đã chi 50.000đ cho dịch vụ X", debitRule("com.mservice.momotransfer"))
        assertEquals(50000L, amount)
    }

    @Test
    fun `parseAmount MoMo thanh toan debit`() {
        val amount = RegexConfigLoader.parseAmount("thanh toán 100,000đ", debitRule("com.mservice.momotransfer"))
        assertEquals(100000L, amount)
    }

    @Test
    fun `parseAmount MoMo nhan credit`() {
        val amount = RegexConfigLoader.parseAmount("Bạn nhận 80,000đ từ NGUYEN VAN A", creditRule("com.mservice.momotransfer"))
        assertEquals(80000L, amount)
    }

    @Test
    fun `parseAmount MoMo hoan tien credit`() {
        val amount = RegexConfigLoader.parseAmount("hoàn tiền 30,000đ đơn hàng #123", creditRule("com.mservice.momotransfer"))
        assertEquals(30000L, amount)
    }

    // ── parseAmount — edge cases ─────────────────────────────────────────────

    @Test
    fun `parseAmount returns null for unrecognized text`() {
        val amount = RegexConfigLoader.parseAmount("Thông báo bảo mật tài khoản", debitRule("com.VCB"))
        assertNull(amount)
    }

    @Test
    fun `parseAmount handles large amount correctly`() {
        val amount = RegexConfigLoader.parseAmount("Debit: 100,000,000 VND", debitRule("com.VCB"))
        assertEquals(100000000L, amount)
    }

    @Test
    fun `parseAmount strips dots and commas before parsing`() {
        // Vietinbank dot separator: "250.000" → strip → 250000
        val amount = RegexConfigLoader.parseAmount("Giam 10.500.000 VND", debitRule("com.VietinBank.iPay"))
        assertEquals(10500000L, amount)
    }

    // ── hardcoded rules completeness ─────────────────────────────────────────

    @Test
    fun `all hardcoded rules have non-empty patterns`() {
        RegexConfigLoader.hardcodedRules.forEach { rule ->
            assertTrue("${rule.bankId}/${rule.sign} has no patterns", rule.patterns.isNotEmpty())
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

    @Test
    fun `each bank has both debit and credit rules`() {
        val banksWithBothSigns = setOf("vcb", "mb", "tcb", "bidv", "vtb", "momo", "zalopay")
        for (bankId in banksWithBothSigns) {
            val signs = RegexConfigLoader.hardcodedRules
                .filter { it.bankId == bankId }
                .map { it.sign }
                .toSet()
            assertTrue("$bankId missing credit rule", "credit" in signs)
            assertTrue("$bankId missing debit rule",  "debit"  in signs)
        }
    }

    // ── updateActiveRules ────────────────────────────────────────────────────

    @Test
    fun `updateActiveRules overrides hardcoded rules`() {
        val custom = listOf(
            BankRule("custom_bank", listOf("com.custom"), listOf("([0-9]+)"), 1, "debit")
        )
        RegexConfigLoader.updateActiveRules(custom)
        try {
            val rules = RegexConfigLoader.findRulesForPackage("com.custom")
            assertTrue(rules.isNotEmpty())
            assertEquals("custom_bank", rules.first().bankId)

            val vcbRules = RegexConfigLoader.findRulesForPackage("com.VCB")
            assertTrue("VCB rules should be gone after override", vcbRules.isEmpty())
        } finally {
            RegexConfigLoader.updateActiveRules(RegexConfigLoader.hardcodedRules)
        }
    }

    @Test
    fun `updateActiveRules with empty list causes findRulesForPackage to return empty`() {
        RegexConfigLoader.updateActiveRules(emptyList())
        try {
            val rules = RegexConfigLoader.findRulesForPackage("com.VCB")
            assertTrue(rules.isEmpty())
        } finally {
            RegexConfigLoader.updateActiveRules(RegexConfigLoader.hardcodedRules)
        }
    }
}
