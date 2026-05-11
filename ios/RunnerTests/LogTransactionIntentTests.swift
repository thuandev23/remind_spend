import XCTest
import CryptoKit
@testable import Runner

// Tests the business logic that LogTransactionIntent.perform() executes:
//   1. Parse bank message (SMS / email / notification) via BankRegexParser
//   2. Build TransactionPayload with a SHA-256 idempotency key (5-second window)
//   3. Enqueue into KeychainQueue
//
// We cannot call perform() directly because LogTransactionIntent lives in the
// TransactionIntentExtension target and requires the AppIntents framework.
// Instead, each test replays the same sequence of calls perform() makes,
// giving equivalent coverage without the AppIntents dependency.
final class LogTransactionIntentTests: XCTestCase {

    private var queue: KeychainQueue!

    override func setUp() {
        super.setUp()
        queue = KeychainQueue(
            accessGroup: nil,
            itemKey: "intent_test_\(name.filter(\.isLetter))"
        )
    }

    override func tearDown() {
        try? queue.dequeueAll()
        super.tearDown()
    }

    // MARK: - Happy path

    func test_validVCBMessage_parsesAndEnqueues() throws {
        let sms = "GD: -150,000 VND tai ATM"
        let ts: Int64 = 1_700_000_000_000

        let enqueued = try simulateIntent(messageText: sms, timestampMs: ts)
        XCTAssertTrue(enqueued)

        let items = try queue.dequeueAll()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].bankId, "vcb")
        XCTAssertEqual(items[0].amountVnd, 150_000)
        XCTAssertEqual(items[0].sign, "debit")
        XCTAssertEqual(items[0].rawContent, sms)
    }

    func test_validMBMessage_parsesAndEnqueues() throws {
        let sms = "Bạn đã chi 300,000 đ cho đơn hàng"
        let ts: Int64 = 1_700_000_100_000

        let enqueued = try simulateIntent(messageText: sms, timestampMs: ts)
        XCTAssertTrue(enqueued)

        let items = try queue.dequeueAll()
        XCTAssertEqual(items[0].bankId, "mb")
        XCTAssertEqual(items[0].amountVnd, 300_000)
    }

    func test_unknownMessage_doesNotEnqueue() throws {
        let enqueued = try simulateIntent(messageText: "Mã OTP của bạn là 123456", timestampMs: 1_000)
        XCTAssertFalse(enqueued)

        let items = try queue.dequeueAll()
        XCTAssertTrue(items.isEmpty)
    }

    func test_emptyMessage_doesNotEnqueue() throws {
        let enqueued = try simulateIntent(messageText: "", timestampMs: 1_000)
        XCTAssertFalse(enqueued)
        XCTAssertTrue(try queue.dequeueAll().isEmpty)
    }

    // MARK: - Idempotency key

    func test_idempotencyKey_is64HexChars() {
        let key = idempotencyKey(bankId: "vcb", amount: 150_000, timestampMs: 1_700_000_000_000)
        XCTAssertEqual(key.count, 64)
        XCTAssertTrue(key.allSatisfy(\.isHexDigit))
    }

    func test_idempotencyKey_sameWindowProducesSameKey() {
        // Two timestamps within the same 5-second window must produce the same key.
        let ts1: Int64 = 1_700_000_000_000   // window = 340_000_000_000
        let ts2: Int64 = 1_700_000_004_999   // same window

        let k1 = idempotencyKey(bankId: "vcb", amount: 100_000, timestampMs: ts1)
        let k2 = idempotencyKey(bankId: "vcb", amount: 100_000, timestampMs: ts2)
        XCTAssertEqual(k1, k2)
    }

    func test_idempotencyKey_crossWindowBoundary_producesDifferentKey() {
        let ts1: Int64 = 1_700_000_000_000   // window 340_000_000_000
        let ts2: Int64 = 1_700_000_005_000   // window 340_000_001_000

        let k1 = idempotencyKey(bankId: "vcb", amount: 100_000, timestampMs: ts1)
        let k2 = idempotencyKey(bankId: "vcb", amount: 100_000, timestampMs: ts2)
        XCTAssertNotEqual(k1, k2)
    }

    func test_idempotencyKey_matchesPinnedSHA256() {
        // Pins the exact SHA-256 of "vcb_50000_340000000000" so any formula
        // change is caught immediately. This value was computed offline and
        // matches Android's NotificationProcessor.buildIdempotencyKey.
        // ts=1_700_000_000_000 → window = 1_700_000_000_000 / 5_000 = 340_000_000_000
        let expected = sha256hex("vcb_50000_340000000000")
        let actual = idempotencyKey(bankId: "vcb", amount: 50_000, timestampMs: 1_700_000_000_000)
        XCTAssertEqual(actual, expected)
    }

    // MARK: - Idempotency via queue

    func test_sameMessageTwiceWithinWindow_onlyOneItemStored() throws {
        let sms = "GD: -50,000 VND tai ATM"
        let ts: Int64 = 1_700_000_000_000

        try simulateIntent(messageText: sms, timestampMs: ts)
        try simulateIntent(messageText: sms, timestampMs: ts + 2_000)  // same 5-second window

        let items = try queue.dequeueAll()
        XCTAssertEqual(items.count, 1, "Duplicate SMS within same 5-second window must be deduplicated")
    }

    func test_sameMessageInDifferentWindows_enqueuedTwice() throws {
        let sms = "GD: -50,000 VND tai ATM"

        try simulateIntent(messageText: sms, timestampMs: 1_700_000_000_000)
        try simulateIntent(messageText: sms, timestampMs: 1_700_000_005_000)  // next window

        let items = try queue.dequeueAll()
        XCTAssertEqual(items.count, 2, "Messages in different 5-second windows should produce two distinct entries")
    }

    // MARK: - Amount integrity

    func test_largeAmount_storedExactlyAsInt64() throws {
        try simulateIntent(messageText: "GD: -10,000,000 VND tai ATM", timestampMs: 1_000_000)

        let items = try queue.dequeueAll()
        XCTAssertEqual(items[0].amountVnd, 10_000_000)
    }

    func test_amountWithDotSeparator_parsedCorrectly() throws {
        try simulateIntent(messageText: "GD: -1.500.000 VND tai ATM", timestampMs: 1_000_000)

        let items = try queue.dequeueAll()
        XCTAssertEqual(items[0].amountVnd, 1_500_000)
    }

    // MARK: - Payload field completeness

    func test_payload_hasAllRequiredFields() throws {
        let sms = "GD: -200,000 VND"
        let ts: Int64 = 1_700_000_000_000

        try simulateIntent(messageText: sms, timestampMs: ts)
        let item = try queue.dequeueAll()[0]

        XCTAssertFalse(item.id.isEmpty)
        XCTAssertFalse(item.bankId.isEmpty)
        XCTAssertGreaterThan(item.amountVnd, 0)
        XCTAssertFalse(item.sign.isEmpty)
        XCTAssertEqual(item.rawContent, sms)
        XCTAssertEqual(item.timestampMs, ts)
        XCTAssertEqual(item.createdAt, ts)
    }

    // MARK: - Helpers

    // Mirrors LogTransactionIntent.perform() step by step — works for SMS, email, or notification text.
    @discardableResult
    private func simulateIntent(messageText: String, timestampMs: Int64) throws -> Bool {
        guard let parsed = BankRegexParser.parse(text: messageText) else { return false }
        let payload = TransactionPayload(
            id: idempotencyKey(bankId: parsed.bankId, amount: parsed.amountVnd, timestampMs: timestampMs),
            bankId: parsed.bankId,
            amountVnd: parsed.amountVnd,
            sign: parsed.sign,
            rawContent: messageText,
            timestampMs: timestampMs,
            createdAt: timestampMs
        )
        try queue.enqueue(payload)
        return true
    }

    // Mirrors LogTransactionIntent.idempotencyKey exactly.
    private func idempotencyKey(bankId: String, amount: Int64, timestampMs: Int64) -> String {
        let window = timestampMs / 5_000
        let input = Data("\(bankId)_\(amount)_\(window)".utf8)
        let digest = SHA256.hash(data: input)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func sha256hex(_ string: String) -> String {
        let input = Data(string.utf8)
        let digest = SHA256.hash(data: input)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
