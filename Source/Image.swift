//
//  Image.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import SwiftyyJSON
import PromiseKit
import AwaitKit

public enum DownloadType: String {
    case thumbnail = "thumb"
    case full = "full"
}

extension OSCKit {

    public func getImage(url: String, type: DownloadType = .full, progress: ((Double) -> Void)? = nil) -> Promise<UIImage> {
        return `async` {
            let url = try `await`(self.getImageLocalURL(url: url, type: type, progress: progress))
            return try UIImage(contentsOfFile: url.path) !! SDKError.unableToFindImageAt(url)
        }
    }

    public func getImageLocalURL(url: String, type: DownloadType = .full, progress: ((Double) -> Void)? = nil) -> Promise<URL> {
        return `async` {
            let device = try `await`(self.cachedDeviceInfo)
            // Adding serial key in the begining
            // To prevent cache collision between different devices
            let cacheKey = try (device.serial + url).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) !! SDKError.unableToCreateVideoCacheKey
            let cacheFolder = try NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first.map({
                URL(fileURLWithPath: $0)
            }) !! SDKError.unableToFindCacheFolder
            let fileURL = cacheFolder.appendingPathComponent(cacheKey)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
            switch try `await`(self.apiVersion) {
            case .version2:
                return try `await`(self.download(command: CommandV1.getImage(fileUri: url, _type: type), to: fileURL, progress: progress))
            case .version2_1:
                let request = URLRequest.init(url: URL(string: url)!)
                return try `await`(self.download(request: request, to: fileURL, progress: progress))
            }
        }
    }

    public func prepareTakePicture(format: FileFormat = .smallImage) -> Promise<Void> {
        return `async` {
            switch try `await`(self.apiVersion) {
            case .version2(let session):
                try `await`(self.execute(command: CommandV1.setOptions(options: [CaptureMode.image], sessionId: session.id)))
                try `await`(self.execute(command: CommandV1.setOptions(options: [format], sessionId: session.id)))
            case .version2_1:
                try `await`(self.execute(command: CommandV2.setOptions(options: [CaptureMode.image])))
                try `await`(self.execute(command: CommandV2.setOptions(options: [format])))
            }
        }
    }

    public func takePicture(format: FileFormat = .smallImage) -> Promise<String> {
        return `async` {
            let captureResponse: JSON
            switch try `await`(self.apiVersion) {
            case .version2(let session):
                captureResponse = try `await`(self.execute(command: CommandV1.takePicture(sessionId: session.id)))
            case .version2_1:
                captureResponse = try `await`(self.execute(command: CommandV2.takePicture))
            }
            let statusID = try captureResponse["id"].string !! SDKError.unableToParse(captureResponse)
            let statusResponse = try `await`(self.waitForStatus(id: statusID))
            // V2.0 has it as fileUri, v2.1 has it as fileUrl, and the doc for v2.1 has it as fileUri. FML
            let fileUri = statusResponse["results"]["fileUri"].string ?? statusResponse["results"]["fileUrl"].string
            return try fileUri !! SDKError.unableToParse(statusResponse)
        }
    }
}
