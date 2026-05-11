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

    // Tier 3: Hardcoded fallback — credit rules listed before debit so more-specific
    // sign patterns are tried first within the same bank.
    val hardcodedRules: List<BankRule> = listOf(

        // ── VCB (Vietcombank) ─────────────────────────────────────────────────
        BankRule(
            bankId = "vcb",
            packageNames = listOf("com.VCB"),
            patterns = listOf(
                "GD: ?\\+([0-9,.]+) ?VND",
                "Credit:? ?([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "vcb",
            packageNames = listOf("com.VCB"),
            patterns = listOf(
                "GD: ?-([0-9,.]+) ?VND",
                "Debit:? ?([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── MB Bank ───────────────────────────────────────────────────────────
        BankRule(
            bankId = "mb",
            packageNames = listOf("com.mbmobile"),
            patterns = listOf(
                "nh[aậ]n[^0-9]*([0-9,.]+) ?(?:đ|d)\\b",
                "c[oộ]ng[^0-9]*([0-9,.]+) ?(?:đ|d)\\b"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "mb",
            packageNames = listOf("com.mbmobile"),
            patterns = listOf(
                "chi[^0-9]*([0-9,.]+) ?(?:đ|d)\\b",
                "giao d[iị]ch[^0-9]*([0-9,.]+) ?(?:đ|d)\\b"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── Techcombank ───────────────────────────────────────────────────────
        BankRule(
            bankId = "tcb",
            packageNames = listOf("com.techcombank.mb.portal"),
            patterns = listOf(
                "GD: ?\\+([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "tcb",
            packageNames = listOf("com.techcombank.mb.portal"),
            patterns = listOf(
                "GD: ?-([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── ACB ───────────────────────────────────────────────────────────────
        BankRule(
            bankId = "acb",
            packageNames = listOf("com.acb"),
            patterns = listOf(
                "[Gg]hi c[oó][^0-9]*([0-9,.]+) ?VND",
                "[Ss]o ti[eề]n: ?\\+([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "acb",
            packageNames = listOf("com.acb"),
            patterns = listOf(
                "[Gg]hi n[oợ][^0-9]*([0-9,.]+) ?VND",
                "[Ss]o ti[eề]n: ?-([0-9,.]+) ?VND",
                "([0-9,.]+) VND",
                "([0-9,.]+)VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── BIDV ──────────────────────────────────────────────────────────────
        BankRule(
            bankId = "bidv",
            packageNames = listOf("com.BIDV.SmartBanking"),
            patterns = listOf(
                "(?:t[aă]ng|[Cc][oộ]ng|nh[aậ]n)[^0-9]*([0-9,.]+) ?VND",
                "Credit[^0-9]*([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "bidv",
            packageNames = listOf("com.BIDV.SmartBanking"),
            patterns = listOf(
                "(?:gi[aả]m|[Tt]r[uừ])[^0-9]*([0-9,.]+) ?VND",
                "Debit[^0-9]*([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── Vietinbank ────────────────────────────────────────────────────────
        BankRule(
            bankId = "vtb",
            packageNames = listOf("com.VietinBank.iPay"),
            patterns = listOf(
                "[Tt][aă]ng[^0-9]*([0-9,.]+) ?VND",
                "Credit[^0-9]*([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "vtb",
            packageNames = listOf("com.VietinBank.iPay"),
            patterns = listOf(
                "[Gg]i[aả]m[^0-9]*([0-9,.]+) ?VND",
                "Debit[^0-9]*([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── MoMo ─────────────────────────────────────────────────────────────
        BankRule(
            bankId = "momo",
            packageNames = listOf("com.mservice.momotransfer"),
            patterns = listOf(
                "nh[aậ]n[^0-9]*([0-9,.]+) ?(?:đ|d|VND)",
                "ho[aà]n ti[eề]n[^0-9]*([0-9,.]+) ?(?:đ|d|VND)"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "momo",
            packageNames = listOf("com.mservice.momotransfer"),
            patterns = listOf(
                "(?:chi|thanh to[aá]n)[^0-9]*([0-9,.]+)(?:đ|d)",
                "B[aạ]n [dđ][aã] (?:chi|g[uử]i)[^0-9]*([0-9,.]+)(?:đ|d|VND)"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── ZaloPay ───────────────────────────────────────────────────────────
        BankRule(
            bankId = "zalopay",
            packageNames = listOf("com.vnpay.zalopay"),
            patterns = listOf(
                "nh[aậ]n[^0-9]*([0-9,.]+) ?(?:đ|d|VND)",
                "ho[aà]n[^0-9]*([0-9,.]+) ?(?:đ|d|VND)"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "zalopay",
            packageNames = listOf("com.vnpay.zalopay"),
            patterns = listOf(
                "(?:chi|thanh to[aá]n)[^0-9]*([0-9,.]+)(?:đ|d|VND)"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── VPBank ────────────────────────────────────────────────────────────
        BankRule(
            bankId = "vpb",
            packageNames = listOf("com.vpbank.digitalhub.myvpbank", "vn.com.vpbank.vpbankonline"),
            patterns = listOf(
                "\\+([0-9,.]+) ?VND",
                "c[oộ]ng[^0-9]*([0-9,.]+) ?VND",
                "nh[aậ]n[^0-9]*([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "vpb",
            packageNames = listOf("com.vpbank.digitalhub.myvpbank", "vn.com.vpbank.vpbankonline"),
            patterns = listOf(
                "-([0-9,.]+) ?VND",
                "tr[uừ][^0-9]*([0-9,.]+) ?VND",
                "([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── Agribank ─────────────────────────────────────────────────────────
        BankRule(
            bankId = "agr",
            packageNames = listOf("com.viettel.agribank.app", "vn.agribank.app"),
            patterns = listOf(
                "[Tt][aă]ng[^0-9]*([0-9,.]+) ?(?:đ|d|VND)",
                "nh[aậ]n[^0-9]*([0-9,.]+) ?(?:đ|d|VND)",
                "\\+([0-9,.]+) ?(?:đ|d|VND)"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "agr",
            packageNames = listOf("com.viettel.agribank.app", "vn.agribank.app"),
            patterns = listOf(
                "[Gg]i[aả]m[^0-9]*([0-9,.]+) ?(?:đ|d|VND)",
                "tr[uừ][^0-9]*([0-9,.]+) ?(?:đ|d|VND)",
                "-([0-9,.]+) ?(?:đ|d|VND)"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── TPBank ────────────────────────────────────────────────────────────
        BankRule(
            bankId = "tpb",
            packageNames = listOf("com.tpbank.digitalmobile", "vn.tpb.mobilebanking"),
            patterns = listOf(
                "\\+([0-9,.]+) ?VND",
                "nh[aậ]n[^0-9]*([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "tpb",
            packageNames = listOf("com.tpbank.digitalmobile", "vn.tpb.mobilebanking"),
            patterns = listOf(
                "-([0-9,.]+) ?VND",
                "([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── Sacombank ─────────────────────────────────────────────────────────
        BankRule(
            bankId = "scb",
            packageNames = listOf("com.sacombank.sacomPay", "vn.sacombank.mbanking"),
            patterns = listOf(
                "\\+([0-9,.]+) ?VND",
                "nh[aậ]n[^0-9]*([0-9,.]+) ?VND",
                "c[oộ]ng[^0-9]*([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "scb",
            packageNames = listOf("com.sacombank.sacomPay", "vn.sacombank.mbanking"),
            patterns = listOf(
                "-([0-9,.]+) ?VND",
                "tr[uừ][^0-9]*([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "debit"
        ),

        // ── OCB ───────────────────────────────────────────────────────────────
        BankRule(
            bankId = "ocb",
            packageNames = listOf("com.ocb.emoneyapp", "vn.ocb.omniapp"),
            patterns = listOf(
                "\\+([0-9,.]+) ?VND",
                "[Cc][oộ]ng[^0-9]*([0-9,.]+) ?VND"
            ),
            amountGroup = 1,
            sign = "credit"
        ),
        BankRule(
            bankId = "ocb",
            packageNames = listOf("com.ocb.emoneyapp", "vn.ocb.omniapp"),
            patterns = listOf(
                "-([0-9,.]+) ?VND",
                "[Tt]r[uừ][^0-9]*([0-9,.]+) ?VND"
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

    // Returns ALL rules whose packageNames match — caller tries each in order
    // until a pattern matches. Credit rules are listed before debit in hardcodedRules
    // so the more-specific sign pattern wins when both could theoretically match.
    fun findRulesForPackage(packageName: String): List<BankRule> =
        (_activeRules ?: hardcodedRules).filter { rule ->
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
