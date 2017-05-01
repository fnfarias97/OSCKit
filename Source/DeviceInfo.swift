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
}

extension OSCKit {
    public var deviceInfo: Promise<DeviceInfo> {
        return async {
            let info = try await(self.info)
            let state = try await(self.state)

            return DeviceInfo(
                model: try info["model"].string !! SDKError.unableToParse(info),
                serial: try info["serialNumber"].string !! SDKError.unableToParse(info),
                battery: try state["state"]["batteryLevel"].double !! SDKError.unableToParse(state)
            )
        }
    }

    public var info: Promise<JSON> { return self.requestJSON(endPoint: .info) }

    public var state: Promise<JSON> { return self.requestJSON(endPoint: .state) }

}
