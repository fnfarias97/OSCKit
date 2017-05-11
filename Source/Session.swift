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

    fileprivate static var currentSession: Session?

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
    public var session: Promise<Session> {
        if let currentSession = Session.currentSession {
            if currentSession.wasJustedIssued {
                return Promise(value: currentSession)
            }
            if currentSession.isExpired {
                return startSession
            }
            return update(session: currentSession)
        }
        return startSession
    }

    var startSession: Promise<Session> {
        return async {
            let response = try await(self.execute(command: .startSession))
            return try Session(json: response)
        }
    }

    func update(session: Session) -> Promise<Session> {
        return async {
            do {
                let response = try await(self.execute(command: .updateSession(sessionId: session.id)))
                return try Session(json: response)
            } catch {
                return try await(self.startSession)
            }
        }
    }
}

