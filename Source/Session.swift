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

    public func waitForSession() -> Promise<Void> {
        func recursion(retry: Int) -> Promise<Session> {
            let timeout: Promise<Session> = after(interval: 5)
                .then(execute: {_ in Promise(error: OSCKit.SDKError.fetchTimeout)})
            return race(timeout, session).recover(execute: { (error) -> Promise<Session> in
                if retry < 0 {
                    return Promise(error: error)
                }
                return after(interval: 2).then(execute: {recursion(retry: retry - 1)})
            })
        }
        return recursion(retry: 5).then(execute: {_ in ()})
    }

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
            let session = try Session(json: response)
            Session.currentSession = session
            return session
        }
    }

    func update(session: Session) -> Promise<Session> {
        return async {
            do {
                let response = try await(self.execute(command: .updateSession(sessionId: session.id)))
                let session = try Session(json: response)
                Session.currentSession = session
                return session
            } catch {
                return try await(self.startSession)
            }
        }
    }

    public func end() -> Promise<Void> {
        return async {
            let session = try await(self.session)
            try await(self.execute(command: ._finishWlan(sessionId: session.id)))
        }
    }
}

