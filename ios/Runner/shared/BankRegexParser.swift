import Foundation

struct ParsedTransaction: Equatable {
    let bankId: String
    let amountVnd: Int64
    let sign: String    // "debit" | "credit"
}

/// Tier-3 hardcoded regex rules — mirrors Android RegexConfigLoader.hardcodedRules.
/// Credit patterns are listed before debit so the more-specific sign pattern wins.
enum BankRegexParser {

    private struct Rule {
        let bankId: String
        let patterns: [(regex: String, sign: String)]
    }

    private static let rules: [Rule] = [

        // ── VCB (Vietcombank) ─────────────────────────────────────────────────
        Rule(bankId: "vcb", patterns: [
            ("GD: ?\\+([0-9,.]+) ?VND",           "credit"),
            ("Credit:? ?([0-9,.]+) ?VND",          "credit"),
            ("GD: ?-([0-9,.]+) ?VND",              "debit"),
            ("Debit:? ?([0-9,.]+) ?VND",           "debit")
        ]),

        // ── MB Bank ───────────────────────────────────────────────────────────
        Rule(bankId: "mb", patterns: [
            ("nh[aậ]n[^0-9]*([0-9,.]+) ?(?:đ|d)\\b",     "credit"),
            ("c[oộ]ng[^0-9]*([0-9,.]+) ?(?:đ|d)\\b",      "credit"),
            ("chi[^0-9]*([0-9,.]+) ?(?:đ|d)\\b",           "debit"),
            ("giao d[iị]ch[^0-9]*([0-9,.]+) ?(?:đ|d)\\b", "debit")
        ]),

        // ── Techcombank ───────────────────────────────────────────────────────
        Rule(bankId: "tcb", patterns: [
            ("GD: ?\\+([0-9,.]+) ?VND",  "credit"),
            ("GD: ?-([0-9,.]+) ?VND",    "debit")
        ]),

        // ── ACB ───────────────────────────────────────────────────────────────
        // Broad "([0-9,.]+) VND" omitted on iOS — no package-name filter here
        // so it would match balance lines from any bank's SMS.
        Rule(bankId: "acb", patterns: [
            ("[Gg]hi c[oó][^0-9]*([0-9,.]+) ?VND",   "credit"),
            ("[Ss]o ti[eề]n: ?\\+([0-9,.]+) ?VND",    "credit"),
            ("[Gg]hi n[oợ][^0-9]*([0-9,.]+) ?VND",    "debit"),
            ("[Ss]o ti[eề]n: ?-([0-9,.]+) ?VND",       "debit")
        ]),

        // ── BIDV ──────────────────────────────────────────────────────────────
        Rule(bankId: "bidv", patterns: [
            ("(?:t[aă]ng|[Cc][oộ]ng|nh[aậ]n)[^0-9]*([0-9,.]+) ?VND",  "credit"),
            ("Credit[^0-9]*([0-9,.]+) ?VND",                             "credit"),
            ("(?:gi[aả]m|[Tt]r[uừ])[^0-9]*([0-9,.]+) ?VND",            "debit"),
            ("Debit[^0-9]*([0-9,.]+) ?VND",                              "debit")
        ]),

        // ── Vietinbank ────────────────────────────────────────────────────────
        Rule(bankId: "vtb", patterns: [
            ("[Tt][aă]ng[^0-9]*([0-9,.]+) ?VND",  "credit"),
            ("Credit[^0-9]*([0-9,.]+) ?VND",        "credit"),
            ("[Gg]i[aả]m[^0-9]*([0-9,.]+) ?VND",   "debit"),
            ("Debit[^0-9]*([0-9,.]+) ?VND",          "debit")
        ]),

        // ── MoMo ─────────────────────────────────────────────────────────────
        Rule(bankId: "momo", patterns: [
            ("nh[aậ]n[^0-9]*([0-9,.]+) ?(?:đ|d|VND)",          "credit"),
            ("ho[aà]n ti[eề]n[^0-9]*([0-9,.]+) ?(?:đ|d|VND)",  "credit"),
            ("(?:chi|thanh toán)[^0-9]*([0-9,.]+)(?:đ|d)",      "debit"),
            ("Bạn đã (?:chi|gửi)[^0-9]*([0-9,.]+)(?:đ|VND)",   "debit")
        ]),

        // ── ZaloPay ───────────────────────────────────────────────────────────
        Rule(bankId: "zalopay", patterns: [
            ("nh[aậ]n[^0-9]*([0-9,.]+) ?(?:đ|d|VND)",   "credit"),
            ("ho[aà]n[^0-9]*([0-9,.]+) ?(?:đ|d|VND)",    "credit"),
            ("(?:chi|thanh toán)[^0-9]*([0-9,.]+)(?:đ|VND)", "debit")
        ]),

        // ── VPBank ────────────────────────────────────────────────────────────
        // Patterns anchored to "VPBank" keyword — safe without package-name filter.
        Rule(bankId: "vpb", patterns: [
            ("VPBank[^+0-9]*\\+([0-9,.]+) ?VND",          "credit"),
            ("VPBank[^0-9]*c[oộ]ng[^0-9]*([0-9,.]+) ?VND", "credit"),
            ("VPBank[^\\-0-9]*-([0-9,.]+) ?VND",           "debit"),
            ("VPBank[^0-9]*tr[uừ][^0-9]*([0-9,.]+) ?VND",  "debit")
        ]),

        // ── Agribank ─────────────────────────────────────────────────────────
        Rule(bankId: "agr", patterns: [
            ("Agribank[^0-9]*[Tt][aă]ng[^0-9]*([0-9,.]+) ?(?:đ|d|VND)", "credit"),
            ("Agribank[^+0-9]*\\+([0-9,.]+) ?(?:đ|d|VND)",               "credit"),
            ("Agribank[^0-9]*[Gg]i[aả]m[^0-9]*([0-9,.]+) ?(?:đ|d|VND)", "debit"),
            ("Agribank[^\\-0-9]*-([0-9,.]+) ?(?:đ|d|VND)",               "debit")
        ]),

        // ── TPBank ────────────────────────────────────────────────────────────
        Rule(bankId: "tpb", patterns: [
            ("TP ?Bank[^+0-9]*\\+([0-9,.]+) ?VND",          "credit"),
            ("TP ?Bank[^0-9]*nh[aậ]n[^0-9]*([0-9,.]+) ?VND", "credit"),
            ("TP ?Bank[^\\-0-9]*-([0-9,.]+) ?VND",           "debit"),
            ("TP ?Bank[^0-9]*tr[uừ][^0-9]*([0-9,.]+) ?VND",  "debit")
        ]),

        // ── Sacombank ─────────────────────────────────────────────────────────
        Rule(bankId: "scb", patterns: [
            ("Sacombank[^+0-9]*\\+([0-9,.]+) ?VND",          "credit"),
            ("Sacombank[^0-9]*nh[aậ]n[^0-9]*([0-9,.]+) ?VND", "credit"),
            ("Sacombank[^\\-0-9]*-([0-9,.]+) ?VND",           "debit"),
            ("Sacombank[^0-9]*tr[uừ][^0-9]*([0-9,.]+) ?VND",  "debit")
        ]),

        // ── OCB ───────────────────────────────────────────────────────────────
        Rule(bankId: "ocb", patterns: [
            ("OCB[^+0-9]*\\+([0-9,.]+) ?VND",           "credit"),
            ("OCB[^0-9]*[Cc][oộ]ng[^0-9]*([0-9,.]+) ?VND", "credit"),
            ("OCB[^\\-0-9]*-([0-9,.]+) ?VND",            "debit"),
            ("OCB[^0-9]*[Tt]r[uừ][^0-9]*([0-9,.]+) ?VND", "debit")
        ])
    ]

    /// Tries each rule in order; returns the first successful parse or `nil`.
    static func parse(text: String) -> ParsedTransaction? {
        for rule in rules {
            for (pattern, sign) in rule.patterns {
                guard let amount = matchAmount(text: text, pattern: pattern) else { continue }
                return ParsedTransaction(bankId: rule.bankId, amountVnd: amount, sign: sign)
            }
        }
        return nil
    }

    // MARK: - Private

    private static func matchAmount(text: String, pattern: String) -> Int64? {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: .caseInsensitive
        ) else { return nil }

        let nsRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: nsRange),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: text)
        else { return nil }

        let raw = String(text[captureRange])
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Int64(raw)
    }
}
