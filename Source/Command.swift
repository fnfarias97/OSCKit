//
//  Command.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import SwiftyyJSON

// swiftlint:disable identifier_name
// We want to keep it as close to API as possible
enum Command {
    case startSession
    case updateSession(sessionId: String)
    case closeSession(sessionId: String)
    case _finishWlan(sessionId: String)
    case takePicture(sessionId: String)
    case _startCapture(sessionId: String, mode: VideoCaptureMode)
    case _stopCapture(sessionId: String)
    case listImages
    case _listAll(entryCount: Int, detail: Bool)
    case delete
    case getImage(fileUri: String, _type: DownloadType)
    case _getVideo(fileUri: String, _type: DownloadType)
    case _getLivePreview(sessionId: String)
    case getMetadata
    case getOptions
    case setOptions(options: [Option], sessionId: String)
    case _getMySetting
    case _setMySetting
    case _stopSelfTimer
}
// swiftlint:enable identifier_name

extension Command {
    var name: String {
        switch self {
        case .startSession: return "camera.startSession"
        case .updateSession: return "camera.updateSession"
        case .closeSession: return "camera.closeSession"
        case ._finishWlan: return "camera._finishWlan"
        case .takePicture: return "camera.takePicture"
        case ._startCapture: return "camera._startCapture"
        case ._stopCapture: return "camera._stopCapture"
        case .listImages: return "camera.listImages"
        case ._listAll: return "camera._listAll"
        case .delete: return "camera.delete"
        case .getImage: return "camera.getImage"
        case ._getVideo: return "camera._getVideo"
        case ._getLivePreview: return "camera._getLivePreview"
        case .getMetadata: return "camera.getMetadata"
        case .getOptions: return "camera.getOptions"
        case .setOptions: return "camera.setOptions"
        case ._getMySetting: return "camera._getMySetting"
        case ._setMySetting: return "camera._setMySetting"
        case ._stopSelfTimer: return "camera._stopSelfTimer"
        }
    }

    var defaultJSON: JSON {
        return ["name": self.name]
    }

    func with(params: [String: Any]) -> JSON {
        return [
            "name": self.name,
            "parameters": params
        ]
    }

    var json: JSON {
        switch self {
        case .updateSession(sessionId: let id): return with(params: ["sessionId": id])
        case .takePicture(sessionId: let id): return with(params: ["sessionId": id])
        case let .getImage(fileUri: fileUri, _type: _type):
            return with(params: [
                "fileUri": fileUri,
                "_type": _type.rawValue
            ])
        case let ._getVideo(fileUri: fileUri, _type: _type):
            return with(params: [
                "fileUri": fileUri,
                "_type": _type.rawValue
            ])
        case let ._startCapture(sessionId: id, mode: mode):
            return with(params: [
                "sessionId": id,
                "mode": mode.rawValue
            ])
        case ._stopCapture(sessionId: let id): return with(params: ["sessionId": id])
        case let ._listAll(entryCount: count, detail: detail):
            return with(params: [
                "entryCount": count,
                "detail": detail
            ])
        case let .setOptions(options: options, sessionId: id):
            var json: JSON = [:]
            options.forEach({ json[$0.key] = $0.value })
            return with(params: [
                "sessionId": id,
                "options": json.value ?? NSNull()
            ])
        case ._getLivePreview(sessionId: let id): return with(params: ["sessionId": id])
        case ._finishWlan(sessionId: let id): return with(params: ["sessionId": id])
        default: return defaultJSON
        }
    }
}
