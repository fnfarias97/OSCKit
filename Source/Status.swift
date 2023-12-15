//
//  Status.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import AwaitKit
import PromiseKit
import SwiftyyJSON

extension OSCKit {
    func waitForStatus(id: String) -> Promise<JSON> {
        return `async` {
            let json: JSON = [
                "id": id
            ]
            let response = try `await`(self.requestJSON(endPoint: .status, params: json))
            if response["state"].string == "inProgress" {
                try `await`(after(seconds: 2).asVoid())
                return try `await`(self.waitForStatus(id: id))
            }
            return response
        }
    }
}
