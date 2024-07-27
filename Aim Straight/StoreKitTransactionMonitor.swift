//
//  StoreKitTransactionMonitor.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import StoreKit

protocol StoreKitTransactionMonitorDelegate: AnyObject {
    func paymentTransactionFinished()
}

class StoreKitTransactionMonitor {

    init() {
        task = Task.detached { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = update else {
                    continue
                }

                await transaction.finish()
                self?.delegate?.paymentTransactionFinished()
            }
        }
    }

    deinit {
        task?.cancel()
    }

    weak var delegate: StoreKitTransactionMonitorDelegate?
    private var task: Task<Void, Never>? = nil

}
