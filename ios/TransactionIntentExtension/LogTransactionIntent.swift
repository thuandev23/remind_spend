import AppIntents
import CryptoKit
import Foundation
import UserNotifications

// Requires iOS 16+ — enforce MinimumOSVersion = 16.0 in the extension Info.plist.
// This intent is invoked by a Shortcuts Personal Automation. Supported triggers:
//   • "Tin nhắn" (SMS)        — iOS 16+, passes message body
//   • "Email"                 — iOS 16+, passes email body
//   • "Thông báo từ app X"    — iOS 18+, passes notification body
// The user sets up one automation per source via the onboarding flow in the app.

@available(iOS 16.0, *)
struct LogTransactionIntent: AppIntent {

    static var title: LocalizedStringResource = "Log Bank Transaction"
    static var description = IntentDescription(
        "Parses a bank SMS, email, or notification and saves the transaction for Remind Spend."
    )

    // Shortcuts passes the message/email/notification body as this parameter.
    @Parameter(title: "Message Text", description: "Full text of the bank SMS, email, or notification.")
    var messageText: String

    func perform() async throws -> some IntentResult {
        // Tier 1: dynamic rules from App Group UserDefaults (pushed by RemoteConfigService).
        // Tier 2: hardcoded BankRegexParser fallback.
        guard let parsed = parseDynamic(text: messageText) ?? BankRegexParser.parse(text: messageText) else {
            // Not a transaction message we recognise — silent success so Shortcuts doesn't error.
            return .result()
        }


        let nowMs = Int64(Date().timeIntervalSince1970 * 1_000)
        let payload = TransactionPayload(
            id: idempotencyKey(bankId: parsed.bankId, amount: parsed.amountVnd, timestampMs: nowMs),
            bankId: parsed.bankId,
            amountVnd: parsed.amountVnd,
            sign: parsed.sign,
            rawContent: messageText,
            timestampMs: nowMs,
            createdAt: nowMs
        )

        NSLog("[LogTransactionIntent] enqueuing id=\(payload.id) bank=\(payload.bankId) amount=\(payload.amountVnd)")
        do {
            try KeychainQueue.shared.enqueue(payload)
        } catch {
            NSLog("[LogTransactionIntent] enqueue FAILED: \(error)")
            let defaults = UserDefaults(suiteName: "group.com.example.remind_spend")
            defaults?.set("[\(Date())] \(error.localizedDescription)", forKey: "last_extension_error")
            return .result()
        }
        NSLog("[LogTransactionIntent] enqueue done")

        // Clear any previous error on success.
        UserDefaults(suiteName: "group.com.example.remind_spend")?.removeObject(forKey: "last_extension_error")

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.example.remind_spend.new_transaction" as CFString),
            nil, nil, true
        )
        postLocalNotification(payload: payload, parsed: parsed)
        return .result()
    }

    // Reads dynamic rules saved by RemoteConfigService via updateRegexConfig bridge call.
    // Format mirrors BankRule.toJson(): {bank_id, sign, patterns: [String], amount_group: Int}
    private func parseDynamic(text: String) -> ParsedTransaction? {
        guard let defaults = UserDefaults(suiteName: "group.com.example.remind_spend"),
              let data = defaults.data(forKey: "dynamic_regex_rules"),
              let rules = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        else { return nil }

        for rule in rules {
            guard let bankId   = rule["bank_id"]  as? String,
                  let sign     = rule["sign"]     as? String,
                  let patterns = rule["patterns"] as? [String]
            else { continue }
            let group = rule["amount_group"] as? Int ?? 1
            for pattern in patterns {
                if let amount = matchDynamic(text: text, pattern: pattern, group: group) {
                    return ParsedTransaction(bankId: bankId, amountVnd: amount, sign: sign)
                }
            }
        }
        return nil
    }

    private func matchDynamic(text: String, pattern: String, group: Int) -> Int64? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else { return nil }
        let nsRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: nsRange),
              match.numberOfRanges > group,
              let captureRange = Range(match.range(at: group), in: text)
        else { return nil }
        let raw = String(text[captureRange])
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Int64(raw)
    }

    // MARK: - Local Notification

    private func postLocalNotification(payload: TransactionPayload, parsed: ParsedTransaction) {
        let content = UNMutableNotificationContent()
        content.title = parsed.bankId.uppercased()
        content.body  = "\(parsed.sign == "debit" ? "-" : "+")\(formatAmount(parsed.amountVnd))đ"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: payload.id,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func formatAmount(_ amount: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    // MARK: - Idempotency

    // Key = SHA256(bankId + "_" + amount + "_" + ⌊timestampMs / 5000⌋)
    // Mirrors Android NotificationProcessor.buildIdempotencyKey exactly.
    // The 5-second window collapses retries of the same SMS.
    private func idempotencyKey(bankId: String, amount: Int64, timestampMs: Int64) -> String {
        let window = timestampMs / 5_000
        let input = Data("\(bankId)_\(amount)_\(window)".utf8)
        let digest = SHA256.hash(data: input)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
