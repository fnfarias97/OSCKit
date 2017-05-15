//
//  SSID.swift
//  Pods
//
//  Created by Zhigang Fang on 5/15/17.
//
//

import Foundation
import SystemConfiguration.CaptiveNetwork

final class SSID: NSObject {

    static let shared = SSID()

    private var subscribers: [String: (String?) -> Void] = [:] {
        didSet {
            if subscribers.count > 0 {
                self.startTracking()
            } else {
                self.stopTracking()
            }
        }
    }

    private var previousSSID: String?

    private var ssidTrackingTimer: Timer?

    private func startTracking() {
        guard ssidTrackingTimer == nil else { return }
        self.ssidTrackingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerUpdated), userInfo: nil, repeats: true)
        self.ssidTrackingTimer?.fire()
    }

    private dynamic func timerUpdated() {
        let currentSSID = self.current
        if self.previousSSID != currentSSID {
            self.previousSSID = currentSSID
            self.subscribers.forEach({ (pair) in
                pair.value(currentSSID)
            })
        }
    }

    private func stopTracking() {
        self.ssidTrackingTimer?.invalidate()
        self.ssidTrackingTimer = nil
    }

    func subscribe(onChange subscriber: @escaping (String?) -> Void) -> () -> Void {
        let uuid = UUID().uuidString
        subscriber(self.previousSSID)
        subscribers[uuid] = subscriber
        return {
            self.subscribers[uuid] = nil
        }
    }

    private var current: String? {
        if let interfaces = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interfaces) {
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if let interfaceData: NSDictionary = unsafeInterfaceData, let ssid = interfaceData["SSID"] as? String {
                    return ssid
                }
            }
        }
        return nil
    }

}

extension OSCKit {

    public func ssid(changed: @escaping (String?) -> Void) -> () -> Void {
        return SSID.shared.subscribe(onChange: changed)
    }

}
