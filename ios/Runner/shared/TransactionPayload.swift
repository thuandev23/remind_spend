import Foundation

/// Represents one pending bank transaction waiting to be pulled by Flutter.
/// Used in both the Runner app and the TransactionIntentExtension — both targets
/// must include this file in their compile sources.
struct TransactionPayload: Codable, Equatable {
    let id: String        // idempotency key — SHA-256 hex, 64 chars
    let bankId: String
    let amountVnd: Int64  // never Double; unit = đồng
    let sign: String      // "debit" | "credit"
    let rawContent: String
    let timestampMs: Int64
    let createdAt: Int64
}
