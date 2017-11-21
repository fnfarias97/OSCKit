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

private class DummyURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {

    let (promise, fulfill, reject) = Promise<URL>.pending()

    let progress: ((Double) -> Void)?

    init(progress: ((Double) -> Void)?) {
        self.progress = progress
    }

    var bytesPreviouslyWritten: Int64 = 0

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let totalBytesWritten = bytesWritten + bytesPreviouslyWritten
        progress?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
        bytesPreviouslyWritten = totalBytesWritten
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        progress?(1)
        fulfill(location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error { reject(error) }
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

    func download(command: Command, to: URL, progress: ((Double) -> Void)? = nil) -> Promise<URL> {
        let request = self.assembleRequest(params: command.json)
        return download(request: request, to: to, progress: progress)
    }

    func download(request: URLRequest, to: URL, progress: ((Double) -> Void)? = nil) -> Promise<URL> {
        let dummyDelegate = DummyURLSessionDelegate(progress: progress)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: dummyDelegate, delegateQueue: nil)

        let task = session.downloadTask(with: request)
        task.resume()
        return dummyDelegate.promise
    }

    func requestData(url: String) -> Promise<Data> {
        let request = URLRequest(url: URL(string: url)!)
        return URLSession.shared.dataTask(with: request)
    }

    func execute(command: Command) -> Promise<JSON> {
        return self.requestJSON(endPoint: .execute, params: command.json)
    }
}

