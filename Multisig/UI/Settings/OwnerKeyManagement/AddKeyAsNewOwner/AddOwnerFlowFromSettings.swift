//
//  AddOwnerFlowFromSettingsFactory.swift
//  Multisig
//
//  Created by Moaaz on 5/17/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class AddOwnerFlowFromSettings: AddOwnerFlow {
    var newAddressName: String?

    var addOwnerFlowFactory: AddOwnerFlowFactory {
        factory as! AddOwnerFlowFactory
    }
    init(safe: Safe, factory: AddOwnerFlowFactory = .init(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        super.init(newOwner: nil, safe: safe, factory: factory, navigationController: navigationController, completion: completion)
    }

    override func start() {
        enterAddressViewController()
    }

    func enterAddressViewController() {
        let viewController = addOwnerFlowFactory.enterOwnerAddress(chain: safe.chain!,
                                                                   stepNumber: 1,
                                                                   maxSteps: 3,
                                                                   trackingEvent: .addOwnerSelectAddress) { [unowned self] address, resolvedName  in
            newOwner = address
            if let resolvedName = resolvedName {
                self.newAddressName = resolvedName
                confirmations()
            } else {
                enterOwnerNameViewController()
            }
        }

        show(viewController)
    }

    func enterOwnerNameViewController() {
        assert(newOwner != nil)
        let viewController = addOwnerFlowFactory.enterOwnerName(safe: safe,
                                                                            address: newOwner!,
                                                                            stepNumber: 1,
                                                                            maxSteps: 3,
                                                                            trackingEvent: .addOwnerSpecifyName) { [unowned self] name in
            newAddressName = name
            confirmations()
        }

        show(viewController)
    }

    func confirmations() {
        confirmations(stepNumber: 2, maxSteps: 3)
    }
}
