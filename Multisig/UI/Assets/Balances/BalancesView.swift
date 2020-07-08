//
//  AssetsView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BalancesView: Loadable {
    @ObservedObject
    var model: BalancesViewModel

    init(safe: Safe) {
        self.model = BalancesViewModel(safe: safe)
    }

    var body: some View {
         List {
            ForEach(model.balances) { tokenBalance in
                TokenBalanceCell(tokenBalance: tokenBalance)
            }
        }
        .onAppear {
            self.trackEvent(.assetsCoins)
        }
    }
}

struct TokenBalanceCell: View {
    var tokenBalance: TokenBalance

    var body: some View {
        HStack(spacing: 12) {
            if tokenBalance.address != AddressRegistry.ether.checksummed {
                TokenImage(url: tokenBalance.imageURL)
            } else {
                TokenImage.ether
            }
            BoldText(tokenBalance.symbol)
            Spacer()
            VStack(alignment: .trailing) {
                BoldText(tokenBalance.balance)
                FootnoteText(tokenBalance.balanceUsd)
            }
        }
        .frame(height: 48)
    }
}