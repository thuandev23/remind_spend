//
//  TransactionIntentExtension.swift
//  TransactionIntentExtension
//
//  Created by T T on 8/5/26.
//

import AppIntents

struct TransactionIntentExtension: AppIntent {
    static var title: LocalizedStringResource { "TransactionIntentExtension" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
