//
//  StoreKitTransactionMonitor.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import StoreKit

class StoreKitTransactionMonitor {

    init() {
        task = Task.detached {
            let recorder = LastPaymentDateRecorder()

            for await update in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = update else {
                    continue
                }

                await transaction.finish()
                recorder.recordPayment()
            }
        }
    }

    deinit {
        task?.cancel()
    }

    private var task: Task<Void, Never>?

}
