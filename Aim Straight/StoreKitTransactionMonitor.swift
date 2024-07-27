//
//  StoreKitTransactionMonitor.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import StoreKit

class StoreKitTransactionMonitor {

    typealias PaymentTransactionFinished = () -> Void

    init(paymentTransactionFinished: @escaping PaymentTransactionFinished) {
        task = Task.detached {
            for await update in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = update else {
                    continue
                }

                await transaction.finish()
                paymentTransactionFinished()
            }
        }
    }

    deinit {
        task?.cancel()
    }

    private var task: Task<Void, Never>?

}
