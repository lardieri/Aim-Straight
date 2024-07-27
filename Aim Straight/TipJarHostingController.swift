//
//  TipJarHostingController.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit
import SwiftUI

class TipJarHostingController: UIHostingController<TipJarView> {

    required init?(coder aDecoder: NSCoder) {
        let productIdentifiers = TipLevel.productIdentifiers
        let rootView = TipJarView(productIdentifiers: productIdentifiers)

        super.init(coder: aDecoder, rootView: rootView)
    }

}
