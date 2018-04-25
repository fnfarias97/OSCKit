//
//  DeviceInfo.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import SwiftyyJSON
import PromiseKit
import AwaitKit

public struct DeviceInfo {
    public let model: String
    public let serial: String
    public let battery: Double
    public let currentAPI: Int
    public let supportedAPI: [Int]
}

extension OSCKit {
    public var deviceInfo: Promise<DeviceInfo> {
        return async {
            let info = try await(self.info)
            let state = try await(self.state)

            let dI = DeviceInfo(
                model: try info["model"].string !! SDKError.unableToParse(info),
                serial: try info["serialNumber"].string !! SDKError.unableToParse(info),
                battery: try state["state"]["batteryLevel"].double !! SDKError.unableToParse(state),
                currentAPI: state["state"]["_apiVersion"].int ?? 1,
                supportedAPI: info["apiLevel"].array?.compactMap({$0.int}) ?? [1]
            )
            self.currentDevice = dI
            return dI
        }
    }

    public var cachedDeviceInfo: Promise<DeviceInfo> {
        if let cached = self.currentDevice {
            return Promise.value(cached)
        }
        return self.deviceInfo
    }

    public var info: Promise<JSON> { return self.requestJSON(endPoint: .info) }

    public var state: Promise<JSON> { return self.requestJSON(endPoint: .state) }

    public var latestFile: Promise<String?> {
        return self.state.map({
            let state = $0["state"]
            return state["_latestFileUri"].string ?? state["_latestFileUrl"].string
        })
    }

    public func watchTillLastFileChages() -> (Promise<String>, () -> Void) {
        var stop = false
        func recursion(currentURL: String?) -> Promise<String> {
            return async {
                if stop { throw SDKError.fetchTimeout }
                try await(after(seconds: 2).asVoid())
                let newFile = try await(self.latestFile)
                if let newFile = newFile, newFile != currentURL {
                    return newFile
                }
                return try await(recursion(currentURL: newFile))
            }
        }
        do {
            return (recursion(currentURL: try await(self.latestFile)), {stop = true})
        } catch {
            return (Promise(error: error), {})
        }
    }

}
