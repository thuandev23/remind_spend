import Foundation
import Security

/// Thread-safe Keychain-backed queue shared between the Runner app and the
/// TransactionIntentExtension via an App Group.
///
/// Both targets must include this file in their compile sources and must be in
/// the same App Group (group.com.example.remind_spend).
///
/// Race condition note: the main app reads+clears while the extension writes.
/// In practice these processes don't overlap (the intent fires when the user
/// receives an SMS, typically while the app is backgrounded). A missed write
/// stays in Keychain until the next pull. This is acceptable for Sprint 3;
/// Sprint 5 can add a "read + mark collected" protocol if needed.
final class KeychainQueue {

    static let shared = KeychainQueue(
        accessGroup: "group.com.example.remind_spend",
        itemKey: "pending_transactions"
    )

    private let accessGroup: String?
    private let itemKey: String
    // Fixed service key — must be the same across all targets (app + extension).
    // Without this, iOS defaults to the calling bundle's ID, so the extension
    // writes to a different Keychain item than the main app reads from.
    private static let serviceKey = "com.example.remind_spend.queue"
    private let serialQueue = DispatchQueue(
        label: "com.example.remind_spend.keychain",
        qos: .utility
    )

    /// Designated initialiser. Pass `accessGroup: nil` in unit tests (no App
    /// Group entitlement needed on simulator) and a unique `itemKey` per test
    /// to avoid cross-test pollution.
    init(accessGroup: String?, itemKey: String) {
        self.accessGroup = accessGroup
        self.itemKey = itemKey
    }

    // MARK: - Public API

    /// Appends `payload` to the queue. Silently drops it if its `id` already
    /// exists (idempotency — same key as Android's NotificationProcessor).
    func enqueue(_ payload: TransactionPayload) throws {
        try serialQueue.sync {
            var items = try _load()
            guard !items.contains(where: { $0.id == payload.id }) else { return }
            items.append(payload)
            try _save(items)
        }
    }

    /// Reads queue without clearing — for diagnostics only.
    func peek() throws -> [TransactionPayload] {
        try serialQueue.sync { try _load() }
    }

    /// Returns all queued payloads and atomically clears the queue.
    /// Returns an empty array (not an error) if the queue is empty.
    func dequeueAll() throws -> [TransactionPayload] {
        try serialQueue.sync {
            let items = try _load()
            if !items.isEmpty { try _save([]) }
            return items
        }
    }

    // MARK: - Private Keychain helpers

    private func _load() throws -> [TransactionPayload] {
        var query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceKey,
            kSecAttrAccount as String: itemKey,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        NSLog("[KeychainQueue] _load status=\(status) group=\(accessGroup ?? "nil") service=\(Self.serviceKey)")

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { throw KeychainError.invalidData }
            let items = try JSONDecoder().decode([TransactionPayload].self, from: data)
            NSLog("[KeychainQueue] _load decoded \(items.count) item(s)")
            return items
        case errSecItemNotFound:
            NSLog("[KeychainQueue] _load: item not found (errSecItemNotFound)")
            return []
        default:
            NSLog("[KeychainQueue] _load: unexpected status \(status)")
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func _save(_ items: [TransactionPayload]) throws {
        let data = try JSONEncoder().encode(items)

        var query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceKey,
            kSecAttrAccount as String: itemKey
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        let attributes: [String: Any] = [
            kSecValueData as String:      data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insertQuery = query
            insertQuery.merge(attributes) { _, new in new }
            status = SecItemAdd(insertQuery as CFDictionary, nil)
        }
        NSLog("[KeychainQueue] _save status=\(status) count=\(items.count) group=\(accessGroup ?? "nil")")

        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }
}

// MARK: - Error

enum KeychainError: Error, Equatable {
    case invalidData
    case unexpectedStatus(OSStatus)
}
