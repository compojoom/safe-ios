//
//  CenteredAddressWithLink.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CenteredAddressWithLink: View {

    @ObservedObject var safe: Safe
    @State private var showsBrowser: Bool = false

    var body: some View {
        HStack {
            Button(action: {
                UIPasteboard.general.string = self.safe.address
            }) {
                AddressText(safe.address!)
                    .font(Font.gnoBody.weight(.medium))
                    .multilineTextAlignment(.center)
            }

            Button(action: { self.showsBrowser.toggle() }) {
                Image("icon-external-link")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.gnoHold)
            }
            .frameForTapping()
            .sheet(isPresented: $showsBrowser) {
                SafariViewController(url: self.safe.browserURL)
            }
        }
        // these two lines make sure that the alignment will be by
        // the addreses text's center, and
        .padding([.leading, .trailing], 44)
        // that 'link button' will be visually attached to the trailnig
        .padding(.trailing, -44)
    }
}
