import XCTest
@testable import Runner

// These tests run on the iOS Simulator (RunnerTests target).
// Each test uses a unique Keychain key so they are fully isolated.
// No App Group entitlement is needed because accessGroup is nil here —
// the production code uses the shared group.com.example.remind_spend group.
final class KeychainQueueTests: XCTestCase {

    private var queue: KeychainQueue!

    override func setUp() {
        super.setUp()
        // Unique key per test — prevents cross-test pollution.
        queue = KeychainQueue(
            accessGroup: nil,
            itemKey: "test_\(name.filter(\.isLetter))"
        )
    }

    override func tearDown() {
        // Best-effort cleanup; tests are isolated by key so residual items
        // from a crashed test don't affect subsequent runs.
        try? queue.dequeueAll()
        super.tearDown()
    }

    // MARK: - Basic enqueue / dequeue

    func test_enqueueAndDequeue_returnsItem() throws {
        let payload = makePayload(id: "key1", amount: 50_000)
        try queue.enqueue(payload)

        let result = try queue.dequeueAll()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], payload)
    }

    func test_dequeueAll_clearsQueue() throws {
        try queue.enqueue(makePayload(id: "k1", amount: 100_000))
        _ = try queue.dequeueAll()

        let second = try queue.dequeueAll()
        XCTAssertTrue(second.isEmpty)
    }

    func test_dequeueAll_emptyQueue_returnsEmpty() throws {
        let result = try queue.dequeueAll()
        XCTAssertTrue(result.isEmpty)
    }

    func test_multipleItems_preserveInsertionOrder() throws {
        let p1 = makePayload(id: "a", amount: 10_000)
        let p2 = makePayload(id: "b", amount: 20_000)
        let p3 = makePayload(id: "c", amount: 30_000)

        try queue.enqueue(p1)
        try queue.enqueue(p2)
        try queue.enqueue(p3)

        let result = try queue.dequeueAll()
        XCTAssertEqual(result.map(\.id), ["a", "b", "c"])
    }

    // MARK: - Idempotency

    func test_enqueueWithSameId_onlyStoresOnce() throws {
        let p1 = makePayload(id: "dup", amount: 50_000)
        let p2 = makePayload(id: "dup", amount: 99_000)  // same id, different amount

        try queue.enqueue(p1)
        try queue.enqueue(p2)

        let result = try queue.dequeueAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].amountVnd, 50_000)  // first write wins
    }

    func test_enqueueAfterDequeue_acceptsNewItem() throws {
        let first = makePayload(id: "first", amount: 10_000)
        try queue.enqueue(first)
        _ = try queue.dequeueAll()

        // Same id should be accepted again after the queue was cleared.
        let second = makePayload(id: "first", amount: 20_000)
        try queue.enqueue(second)

        let result = try queue.dequeueAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].amountVnd, 20_000)
    }

    // MARK: - Amount integrity

    func test_amountVndIsStoredExactly() throws {
        let exact: Int64 = 1_234_567_890
        try queue.enqueue(makePayload(id: "exact", amount: exact))

        let result = try queue.dequeueAll()
        XCTAssertEqual(result[0].amountVnd, exact)
    }

    // MARK: - Helpers

    private func makePayload(id: String, amount: Int64) -> TransactionPayload {
        TransactionPayload(
            id: id,
            bankId: "vcb",
            amountVnd: amount,
            sign: "debit",
            rawContent: "GD: -\(amount) VND",
            timestampMs: 1_700_000_000_000,
            createdAt: 1_700_000_000_000
        )
    }
}
