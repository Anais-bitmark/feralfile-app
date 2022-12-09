//
//  WalletConnectChannel.swift
//  Runner
//
//  Created by Ho Hien on 23/08/2022.
//

import Flutter
import Combine
import WalletConnectSign
import WalletConnectUtils
import Foundation

class WC2ChannelHandler: NSObject {
    static let shared = WC2ChannelHandler()
    private var publishers = [AnyCancellable]()

    var pendingRequests: [Request] = []
    var pendingProposals: [Session.Proposal] = []

    @MainActor
    func respondOnApprove(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let topic: String = args["topic"] as! String
        let dataString = (args["response"] as! String).utf8Data

        let response = try? JSONDecoder().decode(CustomCodable.self, from: dataString)
        
        guard let request = pendingRequests.last(where: { $0.topic == topic }) else {
            result(AppError.aborted)
            return
        }
        
        WalletConnectService.shared.respondOnApprove(
            request: request,
            response: response != nil ? AnyCodable(response) : AnyCodable(args["response"] as! String))
        
        result([
            "error": 0
        ])
    }

    @MainActor
    func respondOnReject(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let requestId: String = args["topic"] as! String
        let reason: String = (args["reason"] as? String) ?? ""

        guard let request = pendingRequests.last(where: { $0.topic == requestId }) else {
            result(AppError.aborted)
            return
        }
        
        WalletConnectService.shared.respondOnReject(request: request, reason: reason)
        
        result([
            "error": 0
        ])
    }

    @MainActor
    func getPairings(call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let pairings = WalletConnectService.shared.getPairings();
            let wc2Pairings = pairings.map { p in
                Wc2Pairing(topic: p.topic, expiryDate: p.expiryDate.absoluteTime, peer: p.peer)
            }
            let data = try JSONEncoder().encode(wc2Pairings)
            let json = String(data: data, encoding: .utf8)
            result(json)
        } catch {
            result(ErrorHandler.flutterError(error: error, "getPairings error"))
        }
    }

    @MainActor
    func activate(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let topic: String = args["topic"] as! String
        
        try WalletConnectService.shared.activate(topic: topic)
        result([
            "error": 0
        ])
    }
    
    @MainActor
    func deletePairing(call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let args: NSDictionary = call.arguments as! NSDictionary
            let topic: String = args["topic"] as! String
            try WalletConnectService.shared.deletePairing(topic: topic)
            result([
                "error": 0
            ])
        } catch {
            result(ErrorHandler.flutterError(error: error, "deletePairing error"))
        }
    }
    
    @MainActor
    func cleanupSessions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let retainIds: [String] = args["retain_ids"] as! [String]

        let pairings = WalletConnectService.shared.getPairings()
        
        pairings.forEach {
            if (!retainIds.contains($0.topic)) {
                try? WalletConnectService.shared.deletePairing(topic: $0.topic)
            }
        }
    }

    @MainActor
    func pairClient(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uri: String = args["uri"] as! String
        
        WalletConnectService.shared.pairClient(uri: uri)
        
        result([
            "error": 0
        ])
    }

    @MainActor
    func approve(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let proposalId: String = args["proposal_id"] as! String
        let account: String = args["account"] as! String

        guard let proposal = pendingProposals.last(where: { $0.id == proposalId }) else {
            result(AppError.aborted)
            return
        }
        
        var sessionNamespaces = [String: SessionNamespace]()
        proposal.requiredNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            let accounts = Set(proposalNamespace.chains.compactMap { Account($0.absoluteString + ":\(account)") })

            let extensions: [SessionNamespace.Extension]? = proposalNamespace.extensions?.map { element in
                let accounts = Set(element.chains.compactMap { Account($0.absoluteString + ":\(account)") })
                return SessionNamespace.Extension(accounts: accounts, methods: element.methods, events: element.events)
            }
            let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events, extensions: extensions)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        
        WalletConnectService.shared.approve(proposalId: proposalId, namespaces: sessionNamespaces)
        
        result([
            "error": 0
        ])
    }

    @MainActor
    func reject(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let proposalId: String = args["proposal_id"] as! String
        
        WalletConnectService.shared.reject(proposalId: proposalId, reason: .userRejectedChains)
        
        result([
            "error": 0
        ])
    }
}


extension WC2ChannelHandler: FlutterStreamHandler {

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal in
                print("[RESPONDER] WC: Did receive session proposal")
                self?.pendingProposals.append(sessionProposal)
                
                var params: [String: Any] = [:]
                let proposer = try? JSONEncoder().encode(sessionProposal.proposer)
                let namespaces = try? JSONEncoder().encode(sessionProposal.requiredNamespaces)
                params["id"] = sessionProposal.id
                params["proposer"] = proposer != nil ? String(data: proposer!, encoding: .utf8) : nil
                params["requiredNamespaces"] = namespaces != nil ? String(data: namespaces!, encoding: .utf8) : nil
                
                events([
                    "eventName": "onSessionProposal",
                    "params": params,
                ])
            }.store(in: &publishers)

        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { session in
                events([
                    "eventName": "onSessionSettle",
                    "params": session.topic,
                ])
            }.store(in: &publishers)

        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                print("[RESPONDER] WC: Did receive session request")
                self?.pendingRequests.append(sessionRequest)

                guard let data = try? JSONEncoder().encode(sessionRequest) else { return }
                events([
                    "eventName": "onSessionRequest",
                    "params": String(data: data, encoding: .utf8),
                ])
            }.store(in: &publishers)

        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                events([
                    "eventName": "onSessionDelete",
                    "params": "",
                ])
            }.store(in: &publishers)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        publishers.removeAll()
        return nil
    }

}

struct Wc2Pairing : Codable {
    var topic: String
    var expiryDate: Double
    var peer: AppMetadata?
    
    init(topic: String, expiryDate: Double, peer: AppMetadata?) {
        self.topic = topic
        self.expiryDate = expiryDate
        self.peer = peer
    }
}
