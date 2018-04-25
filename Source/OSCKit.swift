//
//  OSCKit.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/17/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//
import SwiftyyJSON

public class OSCKit {

    enum SDKError: Error {
        case unableToParse(JSON)
        case unableToFindImageAt(URL)
        case fetchTimeout
        case unableToFindCacheFolder
        case unableToFindVideo
        case unableToCreateVideoCacheKey
    }

    enum APIVersion {
        case version2_1
        case version2(Session)

        var isVersion2_1: Bool {
            switch self {
            case .version2_1:
                return true
            case .version2:
                return false
            }
        }
    }

    var currentDevice: DeviceInfo?
    var currentApiVersion: APIVersion?

    public init() { }

}

