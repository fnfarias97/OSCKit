//
//  SSID.swift
//  Pods
//
//  Created by Zhigang Fang on 5/15/17.
//
//

import Foundation
import SystemConfiguration.CaptiveNetwork

extension OSCKit {

    public var currentSSID: String? {
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
