//
//  TipJarView.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    let productIdentifiers: [String]

    var body: some View {
        VStack(alignment: .center, spacing: 20.0) {
            closeButton()
            titleView()
            ctaView()
            storeView()
        }
        .background(.ultraThickMaterial, in: .rect(cornerRadius: 20))
    }

    @ViewBuilder
    private func closeButton() -> some View {
        HStack {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: 44.0)
            Image(systemName: "xmark")
                .frame(width: 44.0, height: 44.0)
                .onTapGesture {
                    dismiss()
                }
        }
    }

    @ViewBuilder
    private func titleView() -> some View {
        HStack {
            Text(" ")
            Text("Tip Jar")
            Text(" ")
            ZStack {
                Text("🫙")
                Text("❤️")
                    .font(.footnote)
            }
        }
            .font(.largeTitle)
            .fontWeight(.heavy)
    }

    @ViewBuilder
    private func ctaView() -> some View {
        let appName = (Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? "Aim Straight"
        let message = "If you are enjoying \(appName), you may send a gratuity to the developer."
        Text(message)
            .padding()
    }

    @ViewBuilder
    private func storeView() -> some View {
        StoreView(ids: productIdentifiers)
        .storeButton(.hidden, for: .cancellation)
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
