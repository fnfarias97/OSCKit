//
//  Request.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import SwiftyyJSON
import PromiseKit
import AwaitKit

enum Endpoint {
    case info
    case state

    case execute
    case status

    var path: String {
        switch self {
        case .execute: return "/osc/commands/execute"
        case .status: return "/osc/commands/status"
        case .info: return "/osc/info"
        case .state: return "/osc/state"
        }
    }

    var method: String {
        switch self {
        case .execute, .state, .status: return "POST"
        case .info: return "GET"
        }
    }
}

extension OSCKit {
    func assembleRequest(endPoint: Endpoint = .execute, params json: JSON? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: "http://192.168.1.1\(endPoint.path)")!)
        request.httpMethod = endPoint.method
        request.addValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        if let json = json {
            request.httpBody = json.encode()
        }
        return request
    }

    func requestJSON(endPoint: Endpoint = .execute, params json: JSON? = nil) -> Promise<JSON> {
        var request = assembleRequest(endPoint: endPoint, params: json)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return URLSession.shared.dataTask(with: request).then(execute: { data -> JSON in
            let anyObject = try JSONSerialization.jsonObject(with: data, options: [])
            return JSON(value: anyObject as? NSObject)
        })
    }

    func requestData(command: Command) -> Promise<Data> {
        return async {
            let request = self.assembleRequest(params: command.json)
            return try await(URLSession.shared.dataTask(with: request))
        }
    }

    func execute(command: Command) -> Promise<JSON> {
        return self.requestJSON(endPoint: .execute, params: command.json)
    }
}
