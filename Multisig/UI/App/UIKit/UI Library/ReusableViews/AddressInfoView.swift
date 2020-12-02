//
//  AddressInfoView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

struct AddressInfo {
    let address: Address
    let label: String?
}

class AddressInfoView: UINibView {
    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var copyButton: UIButton!
    @IBOutlet private weak var detailImageView: UIImageView!
    @IBOutlet private weak var detailButton: UIButton!

    private (set) var addressInfo: AddressInfo!

    var onDisclosureButtonAction: (() -> Void)?

    @IBAction private func onDisclosureButton() {
        onDisclosureButtonAction?()
    }

    @IBAction private func onAddressInfoButton() {
        let address = addressInfo.address
        Pasteboard.string = address.checksummed
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.headline)
        detailLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
        addTarget(self, action: #selector(didTouchDown(sender:forEvent:)), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp(sender:forEvent:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    func setAddressInfo(_ addressInfo: AddressInfo) {
        self.addressInfo = addressInfo
        update()
    }

    func setDetailsImage(_ image: UIImage, tintColor: UIColor = .gnoHold) {
        detailImageView.image = image
        detailImageView.tintColor = tintColor
    }

    private func update() {
        identiconView.setAddress(addressInfo.address.hexadecimal)
        if let label = addressInfo.label {
            textLabel.isHidden = false
            textLabel.text = label
            detailLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
            detailLabel.text = addressInfo.address.ellipsized()
        } else {
            textLabel.isHidden = true
            detailLabel.attributedText = addressInfo.address.highlighted
        }
    }

    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        copyButton.addTarget(target, action: action, for: controlEvents)
    }

    // visual reaction for user touches
    @objc private func didTouchDown(sender: UIButton, forEvent event: UIEvent) {
        alpha = 0.7
    }

    @objc private func didTouchUp(sender: UIButton, forEvent event: UIEvent) {
        alpha = 1.0
    }
}
