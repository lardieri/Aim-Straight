//
//  StoreKitTransactionMonitor.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import StoreKit

class StoreKitTransactionMonitor {
    private var task: Task<Void, Never>?

    init() {
        task = Task.detached {
            for await update in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = update else {
                    continue
                }

                await transaction.finish()
            }
        }
    }

    deinit {
        task?.cancel()
    }
}
