import Foundation

struct ParsedTransaction: Equatable {
    let bankId: String
    let amountVnd: Int64
    let sign: String    // "debit" | "credit"
}

/// Tier-3 hardcoded regex rules — mirrors Android RegexConfigLoader.hardcodedRules.
/// Patterns operate on SMS body text (vs. Android which parses notification text).
/// Tier-1 (backend) and Tier-2 (local cache) will replace these in Sprint 5.
enum BankRegexParser {

    private struct Rule {
        let bankId: String
        let patterns: [(regex: String, sign: String)]
    }

    private static let rules: [Rule] = [
        Rule(bankId: "vcb", patterns: [
            ("GD: ?-([0-9,.]+) ?VND",            "debit"),
            ("Debit: ?([0-9,.]+) ?VND",           "debit"),
            ("So du TK[^:]*: ?([0-9,.]+) ?VND",  "debit"),
            ("So du: ?([0-9,.]+) ?VND",            "debit")
        ]),
        Rule(bankId: "mb", patterns: [
            ("(?:chi|giao dịch)[^0-9]*([0-9,.]+) ?đ",  "debit"),
            ("Số dư: ?([0-9,.]+) ?đ",                    "debit"),
            ("So du: ?([0-9,.]+)",                        "debit")
        ]),
        Rule(bankId: "tcb", patterns: [
            ("GD: ?-([0-9,.]+)VND",  "debit"),
            ("([0-9,.]+) VND",       "debit")
        ]),
        Rule(bankId: "acb", patterns: [
            ("([0-9,.]+) VND",   "debit"),
            ("([0-9,.]+)VND",    "debit")
        ]),
        Rule(bankId: "momo", patterns: [
            ("(?:chi|thanh toán)[^0-9]*([0-9,.]+)đ",          "debit"),
            ("Bạn đã (?:chi|gửi)[^0-9]*([0-9,.]+)(?:đ|VND)",  "debit")
        ]),
        Rule(bankId: "zalopay", patterns: [
            ("(?:chi|thanh toán)[^0-9]*([0-9,.]+)(?:đ|VND)",  "debit")
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
