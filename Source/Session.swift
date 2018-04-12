//
//  Session.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import SwiftyyJSON
import PromiseKit
import AwaitKit

public struct Session {
    let id: String
    let expires: Date
    let issued: Date

    init (json: JSON) throws {
        self.id = try json["results"]["sessionId"].string !! OSCKit.SDKError.unableToParse(json)
        let expire = try json["results"]["timeout"].int !! OSCKit.SDKError.unableToParse(json)
        self.expires = Date().addingTimeInterval(TimeInterval(expire))
        self.issued = Date()
    }

    var isExpired: Bool {
        return self.expires < Date()
    }

    var wasJustedIssued: Bool {
        return self.issued.addingTimeInterval(10) > Date()
    }
}

extension OSCKit {

    func updateIfNeeded(session: Session) -> Promise<Session> {
        let result: Promise<Session>
        if session.wasJustedIssued {
            result = Promise.value(session)
        } else if session.isExpired {
            result = startSession
        } else {
            result = update(session: session)
        }
        return result.map({ session -> Session in
            self.currentApiVersion = .version2(session)
            return session
        })
    }

    var startSession: Promise<Session> {
        return async {
            let response = try await(self.execute(command: CommandV1.startSession))
            let session = try Session(json: response)
            return session
        }
    }

    private func update(session: Session) -> Promise<Session> {
        return async {
            do {
                let response = try await(self.execute(command: CommandV1.updateSession(sessionId: session.id)))
                return try Session(json: response)
            } catch {
                return try await(self.startSession)
            }
        }
    }

    public func end() -> Promise<Void> {
        return async {
            switch try await(self.apiVersion) {
            case .version2(let session):
                try await(self.execute(command: CommandV1._finishWlan(sessionId: session.id)))
            case .version2_1:
                try await(self.execute(command: CommandV2._finishWlan))
            }
        }
    }
}

