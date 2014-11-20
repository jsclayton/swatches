//
//  InterfaceController.swift
//  Swatches WatchKit Extension
//
//  Created by John Clayton on 11/20/14.
//  Copyright (c) 2014 Code Monkey Labs LLC. All rights reserved.
//

import WatchKit
import Foundation
import MultipeerConnectivity

class InterfaceController: WKInterfaceController, MCNearbyServiceBrowserDelegate, MCSessionDelegate {

    lazy var localPeerID: MCPeerID = {
        return MCPeerID(displayName: "Apple Watch")
    }()

    lazy var serviceBrowser: MCNearbyServiceBrowser = {
        var browser = MCNearbyServiceBrowser(peer: self.localPeerID, serviceType: "swatch-remote")
        browser.delegate = self
        return browser
    }()

    var remoteSession: MCSession?
    var remoteSessionState = MCSessionState.NotConnected

    override init(context: AnyObject?) {
        // Initialize variables here.
        super.init(context: context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        NSLog("Started browsing for peers")
        serviceBrowser.startBrowsingForPeers()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()

        NSLog("Stopped browsing for peers")
        serviceBrowser.stopBrowsingForPeers()
        if let session = remoteSession {
            NSLog("Disconnecting peer session")
            session.disconnect()
        }
    }

    // No way to get the button's color so use unique actions

    @IBAction func didSelectRed() {
        NSLog("Red button selected")
        sendColor(UIColor.redColor())
    }

    @IBAction func didSelectBlue() {
        NSLog("Blue button selected")
        sendColor(UIColor.blueColor())
    }

    @IBAction func didSelectGreen() {
        NSLog("Green button selected")
        sendColor(UIColor.greenColor())
    }

    func sendColor(color: UIColor) {
        if remoteSessionState == .Connected {
            if let session = remoteSession {
                let colorData = NSKeyedArchiver.archivedDataWithRootObject(color)
                session.sendData(colorData, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: nil)
            }
        }
    }

    // MARK: MCNearbyServiceBrowserDelegate

    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        NSLog("Browser unable to start: %@", error)
    }

    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        NSLog("Browser found peer: %@", peerID.displayName)

        remoteSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .None)
        remoteSession?.delegate = self

        browser.invitePeer(peerID, toSession: remoteSession, withContext: nil, timeout: 10)
    }

    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("Browser lost peer: %@", peerID.displayName)
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
