import AppIntents
import CryptoKit
import Foundation

// Requires iOS 16+ — enforce MinimumOSVersion = 16.0 in the extension Info.plist.
// This intent is invoked by a Shortcuts Personal Automation triggered on SMS
// receipt. The user sets it up once via the 1-tap install flow in the app.

@available(iOS 16.0, *)
struct LogTransactionIntent: AppIntent {

    static var title: LocalizedStringResource = "Log Bank Transaction"
    static var description = IntentDescription(
        "Parses a bank SMS and saves the transaction for Remind Spend."
    )

    // The Shortcut passes the SMS body as this parameter.
    @Parameter(title: "SMS Text", description: "Full text of the bank SMS message.")
    var smsText: String

    func perform() async throws -> some IntentResult {
        guard let parsed = BankRegexParser.parse(text: smsText) else {
            // Not a bank SMS we recognise — silent success so Shortcuts doesn't error.
            return .result()
        }

        let nowMs = Int64(Date().timeIntervalSince1970 * 1_000)
        let payload = TransactionPayload(
            id: idempotencyKey(bankId: parsed.bankId, amount: parsed.amountVnd, timestampMs: nowMs),
            bankId: parsed.bankId,
            amountVnd: parsed.amountVnd,
            sign: parsed.sign,
            rawContent: smsText,
            timestampMs: nowMs,
            createdAt: nowMs
        )

        // KeychainQueue.shared uses the App Group — both targets must have the
        // group.com.example.remind_spend entitlement.
        try KeychainQueue.shared.enqueue(payload)
        return .result()
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
