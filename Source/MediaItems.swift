//
//  Items.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import SwiftyyJSON
import PromiseKit
import AwaitKit

public struct MediaItem {
    public enum Kind {
        case image
        case video
    }

    public let name: String
    public let url: String

    public let size: Int?
    public let date: String?
    public let width: Int?
    public let height: Int?

    public var type: Kind {
        if name.lowercased().hasSuffix(".mp4") {
            return .video
        }
        return .image
    }

    init (json: JSON) throws {
        self.name = try json["name"].string !! OSCKit.SDKError.unableToParse(json)
        self.url = try json["uri"].string !! OSCKit.SDKError.unableToParse(json)
        self.size = json["size"].int
        self.date = json["dateTimeZone"].string
        self.width = json["width"].int
        self.height = json["height"].int
    }
}

extension OSCKit {
    public var listAllMediaItems: Promise<[MediaItem]> {
        return async {
            let all = try await(self.execute(command: CommandV1._listAll(entryCount: 100, detail: false)))
            let entries = try all["results"]["entries"].array !! SDKError.unableToParse(all)
            return try entries.map({try MediaItem(json: $0)})
        }
    }

    public func getLatestMediaItem(timeout: TimeInterval = 0, withPredicate predicate: @escaping (MediaItem) -> Bool) -> Promise<MediaItem> {
        return async {
            if timeout < 0 {
                throw SDKError.fetchTimeout
            }
            let all = try await(self.execute(command: CommandV1._listAll(entryCount: 1, detail: true)))
            let json = try all["results"]["entries"].array !! SDKError.unableToParse(all)
            if let first = json.first {
                let item = try MediaItem(json: first)
                if predicate(item) {
                    return item
                }
            }
            try await(after(seconds: 2).asVoid())
            return try await(self.getLatestMediaItem(timeout: timeout - 2, withPredicate: predicate))
        }
    }
}
