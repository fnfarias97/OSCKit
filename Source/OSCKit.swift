//
//  OSCKit.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/17/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//
import SwiftyyJSON

public class OSCKit {
    public static let shared = OSCKit()

    enum SDKError: Error {
        case unableToParse(JSON)
        case unableToFindImageAt(URL)
        case fetchTimeout
        case unableToFindCacheFolder
        case unableToFindVideo
        case unableToCreateVideoCacheKey
    }

    private init() { }

}

