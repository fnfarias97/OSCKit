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

    public func getImage(url: String, type: DownloadType = .full) -> Promise<UIImage> {
        return async {
            let url = try await(self.getImageLocalURL(url: url, type: type))
            return try UIImage(contentsOfFile: url.path) !! SDKError.unableToFindImageAt(url)
        }
    }

    public func getImageLocalURL(url: String, type: DownloadType = .full) -> Promise<URL> {
        return async {
            let device = try await(self.deviceInfo)
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
            let data: Data
            switch try await(self.apiVersion) {
            case .version2:
                data = try await(self.requestData(command: CommandV1.getImage(fileUri: url, _type: type)))
            case .version2_1:
                data = try await(self.requestData(url: url))
            }
            try data.write(to: fileURL)
            return fileURL
        }
    }

    public func takePicture(format: FileFormat = .smallImage) -> Promise<String> {
        return async {
            let captureResponse: JSON
            switch try await(self.apiVersion) {
            case .version2(let session):
                try await(self.execute(command: CommandV1.setOptions(options: [CaptureMode.image], sessionId: session.id)))
                try await(self.execute(command: CommandV1.setOptions(options: [format], sessionId: session.id)))
                captureResponse = try await(self.execute(command: CommandV1.takePicture(sessionId: session.id)))
            case .version2_1:
                try await(self.execute(command: CommandV2.setOptions(options: [CaptureMode.image])))
                try await(self.execute(command: CommandV2.setOptions(options: [format])))
                captureResponse = try await(self.execute(command: CommandV2.takePicture))
            }
            let statusID = try captureResponse["id"].string !! SDKError.unableToParse(captureResponse)
            let statusResponse = try await(self.waitForStatus(id: statusID))
            // V2.0 has it as fileUri, v2.1 has it as fileUrl, and the doc for v2.1 has it as fileUri. FML
            let fileUri = statusResponse["results"]["fileUri"].string ?? statusResponse["results"]["fileUrl"].string
            return try fileUri !! SDKError.unableToParse(statusResponse)
        }
    }
}
