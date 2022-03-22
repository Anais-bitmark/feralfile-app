//
//  BeaconConnectService+PostMessage.swift
//  Runner
//
//  Created by Thuyên Trương on 08/03/2022.
//

import Combine
import Foundation
import BeaconCore
import BeaconBlockchainTezos
import Base58Swift

extension BeaconConnectService {
    func getPostMessageConnectionURI() -> AnyPublisher<String, Error> {
        Future<String, Error> { [weak self] (promise) in
            guard let self = self,
                  let beacon = Beacon.shared,
                  let beaconDappClient = self.beaconClient else {
                      promise(.failure(AppError.pendingBeaconClient))
                      return
                  }
            
            let request = PostMessagePairingRequest(
                id: UUID().uuidString,
                name: beaconDappClient.name,
                icon: nil,
                appUrl: nil,
                publicKey: HexString(from: beacon.app.keyPair.publicKey).asString(),
                type: "postmessage-pairing-request")
            
            do {
                
                let jsonRaw = try JSONEncoder().encode(request)
                let encodedData = Base58.base58CheckEncode(Array(jsonRaw))
                promise(.success(encodedData))
                
            } catch {
                promise(.failure(error))
            }
            
        }
        .eraseToAnyPublisher()
    }
    
    func handlePostMessageOpenChannel(payload: String) -> AnyPublisher<(Beacon.P2PPeer, String), Error> {
        Future<(Beacon.P2PPeer, String), Error> { [weak self] (promise) in
            guard let self = self,
                  let beacon = Beacon.shared else {
                      promise(.failure(AppError.pendingBeaconClient))
                      return
                  }
            
            beacon.openCryptoBox(payload: payload) { result in
                guard let decryptedData = result.get(ifFailure: { promise(.failure($0)) }) else {return }
                
                do {
                    let pairingResponse = try JSONDecoder().decode(
                        ExtendedPostMessagePairingResponse.self, from: Data(decryptedData))
                    let extensionPublicKey = pairingResponse.publicKey
                    let pairingPeer = pairingResponse.extractPeer()
                    
                    // Finish HandShake; generate permissionRequest
                    self.generatePermissionTezosRequest() { result  in
                        guard let request = result.get(ifFailure: { promise(.failure($0)) }) else { return }
                        
                        do {
                            let jsonRaw = try JSONEncoder().encode(request)
                            let message = Base58.base58CheckEncode(Array(jsonRaw))
                            
                            beacon.sealCryptoBox(payload: message, publicKey: extensionPublicKey) { (result) in
                                guard let encryptedPayload = result.get(ifFailure: { promise(.failure($0)) }) else { return }
                                promise(.success((pairingPeer, encryptedPayload)))
                            }
                            
                        } catch {
                            promise(.failure(error))
                        }
                    }
                    
                } catch {
                    promise(.failure(error))
                }
                
            }
            
        }
        .eraseToAnyPublisher()
    }
    
    func handlePostMessageMessage(extensionPublicKey: String, payload: String) -> AnyPublisher<(String, PermissionTezosResponse), Error> {
        Future<(String, PermissionTezosResponse), Error> { [weak self] (promise) in
            guard let self = self,
                  let beacon = Beacon.shared,
                  let beaconDappClient = self.beaconClient else {
                      promise(.failure(AppError.pendingBeaconClient))
                      return
                  }
            
            beacon.openCryptoBox(payload: payload, publicKey: extensionPublicKey) { result in
                guard let decryptedData = result.get(ifFailure: { promise(.failure($0)) }) else { return }
                
                guard let decryptedMessage = String(data: Data(decryptedData), encoding: .utf8),
                      let decodedMessage = Base58.base58CheckDecode(decryptedMessage) else {
                          promise(.failure(AppError.incorrectData))
                          return
                      }
                
                do {
                    let postMessageResponse = try JSONDecoder().decode(
                        PostMessageResponse.self, from: Data(decodedMessage))
                    
                    let permissionTezosResponse = postMessageResponse.convertToPermissionRequest()
                    let tzAddress = try beaconDappClient.crypto.address(fromPublicKey: postMessageResponse.publicKey)
                    
                    promise(.success((tzAddress, permissionTezosResponse)))
                    
                } catch {
                    do {
                        let postMessageResponse = try JSONDecoder().decode(
                            PostMessageErrorResponse.self, from: Data(decodedMessage))
                        
                        if (postMessageResponse.errorType == "ABORTED_ERROR") {
                            promise(.failure(AppError.aborted))
                            return
                        }
                        
                        promise(.failure(error))
                        
                    } catch {
                        promise(.failure(error))
                    }
                }
                
            }
            
        }
        .eraseToAnyPublisher()
    }
}

fileprivate extension BeaconConnectService {
    func generatePermissionTezosRequest(completion: @escaping (Result<PostMessagePermissionRequest, Error>) -> Void) {
        guard let beaconClient = beaconClient else {
            completion(.failure(AppError.pendingBeaconClient))
            return
        }
        
        beaconClient.getOwnAppMetadata { result in
            guard let appMetadata = result.get(ifFailure: { completion(.failure($0)) }) else {
                return
            }
            
            let permissionRequest = PostMessagePermissionRequest(
                type: "permission_request",
                id: UUID().uuidString.lowercased(),
                blockchainIdentifier: Tezos.identifier,
                senderID: appMetadata.senderID,
                appMetadata: appMetadata,
                network: Tezos.Network(type: .mainnet, name: nil, rpcURL: nil),
                scopes: [Tezos.Permission.Scope.operationRequest, Tezos.Permission.Scope.sign],
                version: "2")
            
            completion(.success(permissionRequest))
            
        }
    }
}

struct PostMessagePairingRequest: Codable {
    let id: String
    let name: String
    let icon: String?
    let appUrl: String?
    let publicKey: String
    let type: String
    
}

struct ExtendedPostMessagePairingResponse: Codable {
    let id: String
    let type: String
    let name: String
    let publicKey: String
    let icon: String?
    let appUrl: String?
    let senderId: String
}

struct PostMessagePermissionRequest: Codable {
    public let type: String
    public let id: String
    public let blockchainIdentifier: String
    public let senderID: String
    public let appMetadata: Beacon.AppMetadata
    public let network: Tezos.Network
    public let scopes: [Tezos.Permission.Scope]
    public let version: String
}

struct PostMessageResponse: Codable {
    
    public let id: String
    public let publicKey: String
    public let network: Tezos.Network
    public let scopes: [Tezos.Permission.Scope]
    public let threshold: Beacon.Threshold?
    public let version: String
    public let senderId: String
    public let type: String
    
}

struct PostMessageErrorResponse: Codable {
    public let id: String
    public let version: String
    public let senderId: String
    public let type: String
    public let errorType: String
}

extension PostMessageResponse {
    public func convertToPermissionRequest() -> PermissionTezosResponse {
        PermissionTezosResponse(
            id: id,
            blockchainIdentifier: Tezos.identifier,
            publicKey: publicKey,
            network: network,
            scopes: scopes,
            threshold: nil,
            // this should be postMessage or something, but the app crashes if I updated for unknown reason, so I just let it .p2p for now
            version: version, requestOrigin: Beacon.Origin.p2p(id: senderId)
        )
    }
}

extension ExtendedPostMessagePairingResponse {
    func extractPeer() -> Beacon.P2PPeer { // should be postMessagePeer; but we use that just for field values
        return Beacon.P2PPeer(
            id: id,
            name: name,
            publicKey: publicKey,
            relayServer: "",
            version: "",
            icon: icon,
            appURL: URL(string: appUrl ?? "")
        )
    }
}
