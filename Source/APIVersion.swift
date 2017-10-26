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

    public func usingVersion2_1() -> Promise<Void> {
        return async {
            let session = try await(self.session)
            try await(self.execute(command: CommandV1.setOptions(options: [APIVersion.v2_1], sessionId: session.id)))
        }
    }

}
