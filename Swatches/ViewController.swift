//
//  ViewController.swift
//  Swatches
//
//  Created by John Clayton on 11/20/14.
//  Copyright (c) 2014 Code Monkey Labs LLC. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {

    lazy var localPeerID: MCPeerID = {
        return MCPeerID(displayName: UIDevice.currentDevice().name)
    }()

    lazy var serviceAdvertiser: MCNearbyServiceAdvertiser = {
        var advertiser = MCNearbyServiceAdvertiser(peer: self.localPeerID, discoveryInfo: nil, serviceType: "swatch-remote")
        advertiser.delegate = self
        return advertiser
    }()

    var remoteSession: MCSession?
    var remoteSessionState = MCSessionState.NotConnected

    override func viewDidLoad() {
        super.viewDidLoad()

        NSLog("Starting remote service")
        serviceAdvertiser.startAdvertisingPeer()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSLog("Stopping remote service")
        serviceAdvertiser.stopAdvertisingPeer()
        if let session = remoteSession {
            session.disconnect()
            remoteSessionState = .NotConnected
        }
    }

    // MARK: MCNearbyServiceAdvertiserDelegate

    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        NSLog("Advertiser unable to start: %@", error)
    }

    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        NSLog("Advertiser did receive invitation from %@", peerID.displayName)

        if let session = remoteSession {
            session.disconnect()
            remoteSessionState = .NotConnected
        }

        remoteSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        remoteSession?.delegate = self

        invitationHandler(true, remoteSession)
    }

    // MARK: MCSessionDelegate

    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        remoteSessionState = state
        var status: String
        switch state {
        case .NotConnected:
            status = "not connected"
        case .Connecting:
            status = "connecting"
        case .Connected:
            status = "connected"
        }
        NSLog("Session state did change: %@ to %@", status, peerID.displayName)
    }

    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        NSLog("Session did receive data")

        if let color = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? UIColor {
            let view = self.view
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                view.backgroundColor = color
            })
        }
    }

    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        NSLog("Session did receive stream")
    }

    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        NSLog("Session did start receiving resource")
    }

    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        NSLog("Session did finish receiving resource")
    }

}

