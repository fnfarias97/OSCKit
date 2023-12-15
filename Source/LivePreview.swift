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

    var callback: ((UIImage?) -> Void)?
    var completed: (() -> Void)?
    var restartTimer: Timer?

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
                self.callback?(receivedImage)
            }
        }

        receivedData = NSMutableData()
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.receivedData?.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.completed?()
    }

    func stop() {
        self.callback = nil
        self.completed = nil
        self.dataTask?.cancel()
        self.dataTask = nil
        self.receivedData = nil
        self.restartTimer?.invalidate()
        self.restartTimer = nil
    }
}


extension OSCKit {
    public func startLivePreview(callback: @escaping (UIImage?) -> Void) {
        _ = `async` { () -> JSON in
            switch try `await`(self.apiVersion) {
            case .version2(let session):
                try `await`(self.execute(command: CommandV1.setOptions(options: [CaptureMode.image], sessionId: session.id)))
                return CommandV1._getLivePreview(sessionId: session.id).json
            case .version2_1:
                try `await`(self.execute(command: CommandV2.setOptions(options: [CaptureMode.image])))
                return CommandV2.getLivePreview.json
            }
        }.done(on: DispatchQueue.main) { json -> Void in
            LivePreview.shared.stop()
            LivePreview.shared.callback = callback
            LivePreview.shared.completed = {
                callback(nil)
                DispatchQueue.main.async {
                    LivePreview.shared.restartTimer = Timer.after(5, action: {[weak self] in
                        self?.startLivePreview(callback: callback)
                    })
                }
            }
            let request = self.assembleRequest(endPoint: .execute, params: json)
            LivePreview.shared.play(request: request)
        }
    }

    public func stopLivePreview() {
        DispatchQueue.main.async {
            LivePreview.shared.stop()
        }
    }
}

private class DummyTarget: NSObject {
    let callback: () -> Void
    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    @objc func timerUpdated() {
        self.callback()
    }
}

extension Timer {

    static func after(_ time: TimeInterval, repeats: Bool = false, action: @escaping () -> Void) -> Timer {
        let target = DummyTarget(callback: action)
        return self.scheduledTimer(timeInterval: time, target: target, selector: #selector(target.timerUpdated), userInfo: nil, repeats: repeats)
   }

}
