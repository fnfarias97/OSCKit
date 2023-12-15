//
//  APIVersion.swift
//  OSC
//
//  Created by Zhigang Fang on 10/25/17.
//

import Foundation
import AwaitKit
import PromiseKit

extension OSCKit {

    public func waitForInitialization() -> Promise<Void> {
        func recursion(retry: Int) -> Promise<APIVersion> {
            let timeout: Promise<APIVersion> = after(seconds: 15)
                    .then({ Promise(error: OSCKit.SDKError.fetchTimeout)})
            return race(timeout, self.apiVersion).recover({ (error) -> Promise<APIVersion> in
                if retry < 0 {
                    return Promise(error: error)
                }
                return after(seconds: 2).then({recursion(retry: retry - 1)})
            })
        }
        return recursion(retry: 5).done({ api in
            self.currentApiVersion = api
        })
    }

    var apiVersion: Promise<APIVersion> {
        if let current = self.currentApiVersion {
            switch current {
                case .version2(let session): return self.updateIfNeeded(session: session).map({ APIVersion.version2($0) })
                case .version2_1: return Promise.value(current)
            }
        }
        return `async` {
            let device = try `await`(self.cachedDeviceInfo)
            if device.currentAPI == 2 { return APIVersion.version2_1 }
            let session = try `await`(self.startSession)
            if device.currentAPI == 1 && device.supportedAPI.contains(2) {
                try `await`(self.execute(command: CommandV1.setOptions(options: [ClientVersion.v2_1], sessionId: session.id)))
                return APIVersion.version2_1
            }
            return APIVersion.version2(session)
        }
    }

}
