//
//  LivePreview.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import SwiftyyJSON
import PromiseKit
import AwaitKit

final class LivePreview: NSObject, URLSessionDataDelegate {
    static let shared = LivePreview()

    lazy var session: URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)

    enum Status {
        case stopped
        case loading
        case playing
    }

    var status: Status = .stopped
    private var receivedData: NSMutableData?
    private var dataTask: URLSessionDataTask?

    var callback: (UIImage) -> Void = { _ in }

    private override init() {}

    func play(request: URLRequest) {
        self.receivedData = NSMutableData()
        self.dataTask?.cancel()
        self.dataTask = self.session.dataTask(with: request)
        self.dataTask?.resume()
        self.status = .loading
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let imageData = receivedData , imageData.length > 0,
            let receivedImage = UIImage(data: imageData as Data) {
            if status == .loading {
                status = .playing
            }
            DispatchQueue.main.async {
                self.callback(receivedImage)
            }
        }

        receivedData = NSMutableData()
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.receivedData?.append(data)
    }

    func stop() {
        self.dataTask?.cancel()
        self.dataTask = nil
        self.receivedData = nil
    }
}


extension OSCKit {
    public func startLivePreview(callback: @escaping (UIImage) -> Void) {
        async {
            let session = try await(OSCKit.shared.session)
            try await(self.execute(command: .setOptions(options: [CaptureMode.image], sessionId: session.id)))
            DispatchQueue.main.async(execute: {
                LivePreview.shared.stop()
                LivePreview.shared.callback = callback
                let json = Command._getLivePreview(sessionId: session.id).json
                let request = self.assembleRequest(endPoint: .execute, params: json)
                LivePreview.shared.play(request: request)
            })
        }
    }

    public func stopLivePreview() {
        DispatchQueue.main.async {
            LivePreview.shared.stop()
        }
    }
}
