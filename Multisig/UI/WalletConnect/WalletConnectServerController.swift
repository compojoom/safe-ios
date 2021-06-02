//
//  WalletConnectServerController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

class WalletConnectServerController {
    static let shared = WalletConnectServerController()
    private var server: Server!
    private let notificationCenter = NotificationCenter.default
    private var showedNotificationsSessionTopics = [String]()

    init() {
        server = Server(delegate: self)
        server.register(handler: WCRequestsHandler(server: server))
    }

    func connect(url: String) throws {
        guard let wcurl = WCURL(url) else { throw GSError.InvalidWalletConnectQRCode() }
        do {
            WCSession.create(wcurl: wcurl)
            try server.connect(to: wcurl)
            notificationCenter.post(name: .wcConnectingServer, object: wcurl)
        } catch {
            throw GSError.CouldNotStartWallectConnectSession()
        }
    }

    func reconnectAllSessions() {
        guard let wcSessions = try? WCSession.getAll() else { return }

        wcSessions.forEach {
            guard $0.session != nil, let session = try? Session.from($0) else {
                // Trying to reconnect a session without handshake process finished.
                // This could happed when the app restarts in the middle of the process.
                $0.delete()
                return
            }

            try! server.reconnect(to: session)
        }
    }

    func disconnect(topic: String) {
        guard let wcSession = WCSession.get(topic: topic) else { return }
        do {
            try server.disconnect(from: try Session.from(wcSession))
        } catch {
            wcSession.delete()
            notificationCenter.post(name: .wcDidDisconnectServer, object: nil)
        }
    }

    func sessions(for safe: Address) -> [Session] {
        guard let wcSessions = try? WCSession.getAll() else { return [] }

        var sessions = [Session]()
        for wcSession in wcSessions {
            do {
                sessions.append(try Session.from(wcSession))
            } catch {
                wcSession.delete()
            }
        }

        return sessions
    }

    func updatePendingTransactions() {
        DispatchQueue.main.async {
            guard let pendingTransactions = try? WCPendingTransaction.getAll() else { return }
            LogService.shared.debug("PENDING WC TRANSACTIONS: \(pendingTransactions.count)")
            for pendingTx in pendingTransactions {
                let wcSession = pendingTx.session!
                let session = try! Session.from(wcSession)
                let safeAddress = AddressString(session.walletInfo!.accounts[0])!

                // stop monitoring pending WalletConnect transactions after 24h
                if Date().timeIntervalSince(pendingTx.created!) > 60 * 60 * 24 {
                    pendingTx.delete()
                    continue
                }

                DispatchQueue.global().async { [unowned self] in
                    let nonce = UInt256String(UInt256(pendingTx.nonce!)!)
                    if let transaction = try? App.shared.safeTransactionService
                        .transaction(nonce: nonce, safe: safeAddress),
                       let txHash = transaction.transactionHash,
                       // it might happen that pendingTx is removed, but the object still exists
                       let requestId = pendingTx.requestId,
                       let response = try? Response(url: session.url, value: txHash, id: requestId) {
                        self.server.send(response)
                        DispatchQueue.main.async {
                            let nonce = pendingTx.nonce!
                            pendingTx.delete()
                            App.shared.snackbar.show(message: "WalletConnect transaction with nonce \(nonce) is executed. Please return back to the browser.")
                        }
                    }
                }
            }
        }
    }
}

extension WalletConnectServerController: ServerDelegate {
    func server(_ server: Server, didFailToConnect url: WCURL) {
        DispatchQueue.main.sync {
            guard let wcSession = WCSession.get(topic: url.topic) else { return }
            wcSession.delete()
        }
        notificationCenter.post(name: .wcDidFailToConnectServer, object: url)
    }

    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        let walletMeta = Session.ClientMeta(name: "Gnosis Safe Multisig",
                                            description: "The most trusted platform to manage digital assets.",
                                            icons: [URL(string: "https://gnosis-safe.io/app/favicon.ico")!],
                                            url: URL(string: "https://gnosis-safe.io")!)

        guard let safe = try? Safe.getSelected(), let address = safe.address else {
            let walletInfo = Session.WalletInfo(
                approved: false,
                accounts: [],
                chainId: App.configuration.app.network.chainId,
                peerId: UUID().uuidString,
                peerMeta: walletMeta)

            completion(walletInfo)
            return
        }

        let walletInfo = Session.WalletInfo(
            approved: true,
            accounts: [address],
            chainId: App.configuration.app.network.chainId,
            peerId: UUID().uuidString,
            peerMeta: walletMeta)

        completion(walletInfo)
    }

    func server(_ server: Server, didConnect session: Session) {
        DispatchQueue.main.sync {
            WCSession.update(session: session, status: .connected)
        }
        notificationCenter.post(name: .wcDidConnectServer, object: session)

        // skip snackbar notification for reconnect cases
        if !showedNotificationsSessionTopics.contains(session.url.topic) {
            showedNotificationsSessionTopics.append(session.url.topic)
            DispatchQueue.main.async {
                App.shared.snackbar.show(message: "WalletConnect session created! Please return back to the browser.")
            }
        }
    }

    func server(_ server: Server, didDisconnect session: Session) {
        DispatchQueue.main.sync {
            guard let wcSession = WCSession.get(topic: session.url.topic) else { return }
            wcSession.delete()
        }
        notificationCenter.post(name: .wcDidDisconnectServer, object: session)
    }
}
