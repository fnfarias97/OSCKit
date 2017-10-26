//
//  Video.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import SwiftyyJSON
import PromiseKit
import AwaitKit

public enum VideoCaptureMode: String {
    case interval
    case composite
    case bracket
}

extension OSCKit {

    public func startCapture(mode: VideoCaptureMode = .interval) -> Promise<JSON> {
        return async {
            switch try await(self.apiVersion) {
            case .version2(let session):
                try await(self.execute(command: CommandV1.setOptions(options: [CaptureMode.video], sessionId: session.id)))
                return try await(self.execute(command: CommandV1._startCapture(sessionId: session.id, mode: mode)))
            case .version2_1:
                fatalError("Not implemented")
            }
        }

    }

    public func stopCapture() -> Promise<String> {
        return async {
            switch try await(self.apiVersion) {
            case .version2(let session):
                // Saving first item before capturing video
                // This is due to the face THETA API v2.0 does not return a file URL when capture finishes
                // https://developers.theta360.com/en/docs/v2.0/api_reference/commands/camera._stop_capture.html
                let lastItem = try await(self.getLatestMediaItem(withPredicate: const(value: true)))
                try await(self.execute(command: CommandV1._stopCapture(sessionId: session.id)))
                // After stop capturing video, wait until it returns a new item with type being .video
                let mediaItem = try await(self.getLatestMediaItem(withPredicate: {
                    $0.url != lastItem.url && $0.type ~= .video
                }))
                return mediaItem.url
            case .version2_1:
                let result = try await(self.execute(command: CommandV2.stopCapture))
                let statusID = try result["id"].string !! SDKError.unableToParse(result)
                let statusResponse = try await(self.waitForStatus(id: statusID))
                return try statusResponse["results"]["fileUris"].array?.first?.string !! SDKError.unableToParse(statusResponse)
            }
        }
    }

    public func getVideo(url: String, type: DownloadType = .full) -> Promise<URL> {
        return async {
            let device = try await(self.deviceInfo)
            let cacheKey = try (device.serial + url).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) !! SDKError.unableToCreateVideoCacheKey
            let cacheFolder = try NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first.map({
                URL(fileURLWithPath: $0)
            }) !! SDKError.unableToFindCacheFolder
            let fileURL = cacheFolder.appendingPathComponent(cacheKey)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
            let data: Data
            switch try await(self.apiVersion) {
            case .version2:
                data = try await(self.requestData(command: CommandV1._getVideo(fileUri: url, _type: type)))
            case .version2_1:
                data = try await(self.requestData(url: url))
            }
            try data.write(to: fileURL)
            return fileURL
        }
    }
}
