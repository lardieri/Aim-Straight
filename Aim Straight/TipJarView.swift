//
//  TipJarView.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    let productIdentifiers: [String]

    var body: some View {
        StoreView(ids: productIdentifiers)
    }
}

// MARK: -

#if DEBUG

struct TipJarView_Previews: PreviewProvider {
    static var previews: some View {
        let productIdentifiers = TipLevel.productIdentifiers
        TipJarView(productIdentifiers: productIdentifiers)
    }
}

#endif
