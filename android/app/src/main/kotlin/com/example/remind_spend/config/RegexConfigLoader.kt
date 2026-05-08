package com.example.remind_spend.config

import android.util.Log
import com.example.remind_spend.db.AppDatabase
import com.example.remind_spend.db.RegexConfigEntry
import org.json.JSONArray

data class BankRule(
    val bankId: String,
    val packageNames: List<String>,
    val patterns: List<String>,
    val amountGroup: Int,
    val sign: String   // "debit" | "credit"
)

object RegexConfigLoader {

    private const val TAG = "RegexConfigLoader"

    @Volatile
    private var _activeRules: List<BankRule>? = null

    // Tier 3: Hardcoded fallback — basic patterns cho ngân hàng VN phổ biến
    val hardcodedRules: List<BankRule> = listOf(
        BankRule(
            bankId = "vcb",
            packageNames = listOf("com.VCB"),
            patterns = listOf(
                "GD: ?-([0-9,.]+) ?VND",
                "Debit: ?([0-9,.]+) ?VND",
                "So du TK[^:]*: ?([0-9,.]+) ?VND",
                "So du: ?([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),
        BankRule(
            bankId = "mb",
            packageNames = listOf("com.mbmobile"),
            patterns = listOf(
                "(?:chi|giao dịch)[^0-9]*([0-9,.]+) ?đ",
                "Số dư: ?([0-9,.]+) ?đ",
                "So du: ?([0-9,.]+)"
            ),
            amountGroup = 1,
            sign = "debit"
        ),
        BankRule(
            bankId = "tcb",
            packageNames = listOf("com.techcombank.mb.portal"),
            patterns = listOf(
                "GD: ?-([0-9,.]+)VND",
                "([0-9,.]+) VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),
        BankRule(
            bankId = "acb",
            packageNames = listOf("com.acb"),
            patterns = listOf(
                "([0-9,.]+) VND",
                "([0-9,.]+)VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),
        BankRule(
            bankId = "momo",
            packageNames = listOf("com.mservice.momotransfer"),
            patterns = listOf(
                "(?:chi|thanh toán)[^0-9]*([0-9,.]+)đ",
                "Bạn đã (?:chi|gửi)[^0-9]*([0-9,.]+)(?:đ|VND)"
            ),
            amountGroup = 1,
            sign = "debit"
        ),
        BankRule(
            bankId = "zalopay",
            packageNames = listOf("com.vnpay.zalopay"),
            patterns = listOf(
                "(?:chi|thanh toán)[^0-9]*([0-9,.]+)(?:đ|VND)"
            ),
            amountGroup = 1,
            sign = "debit"
        )
    )

    fun updateActiveRules(rules: List<BankRule>) {
        _activeRules = rules
        Log.i(TAG, "Active rules updated: ${rules.size} rules")
    }

    suspend fun updateFromConfig(db: AppDatabase) {
        val entries = db.regexConfigDao().getAll()
        if (entries.isEmpty()) return
        val rules = entries.map { it.toBankRule() }
        updateActiveRules(rules)
        Log.i(TAG, "Tier 2: ${rules.size} rules loaded from Room")
    }

    fun findRuleForPackage(packageName: String): BankRule? =
        (_activeRules ?: hardcodedRules).firstOrNull { rule ->
            rule.packageNames.any { it.equals(packageName, ignoreCase = true) }
        }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private fun RegexConfigEntry.toBankRule() = BankRule(
        bankId = bankId,
        packageNames = parseJsonArray(packageNamesJson),
        patterns = parseJsonArray(patternsJson),
        amountGroup = amountGroup,
        sign = sign
    )

    private fun parseJsonArray(json: String): List<String> {
        val arr = JSONArray(json)
        return List(arr.length()) { i -> arr.getString(i) }
    }

    fun parseAmount(text: String, rule: BankRule): Long? {
        for (pattern in rule.patterns) {
            val match = Regex(pattern, RegexOption.IGNORE_CASE).find(text) ?: continue
            val groups = match.groupValues
            if (groups.size > rule.amountGroup) {
                val raw = groups[rule.amountGroup]
                    .replace(",", "")
                    .replace(".", "")
                    .trim()
                return raw.toLongOrNull()
            }
        }
        return null
    }
}
