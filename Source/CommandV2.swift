//
// Created by Zhigang Fang on 10/26/17.
//

import Foundation
import SwiftyyJSON

// swiftlint:disable identifier_name
// We want to keep it as close to API as possible
enum CommandV2: Command {
    case _finishWlan
    case takePicture
    case startCapture(mode: VideoCaptureMode)
    case stopCapture
    case listFiles(entryCount: Int, detail: Bool)
    case delete
    case getLivePreview
    case getOptions
    case setOptions(options: [Option])
    case _getMySetting
    case _setMySetting
    case _stopSelfTimer
}

extension CommandV2 {
    var name: String {
        switch self {
        case ._finishWlan: return "camera._finishWlan"
        case .takePicture: return "camera.takePicture"
        case .startCapture: return "camera.startCapture"
        case .stopCapture: return "camera.stopCapture"
        case .listFiles: return "camera.listFiles"
        case .delete: return "camera.delete"
        case .getLivePreview: return "camera.getLivePreview"
        case .getOptions: return "camera.getOptions"
        case .setOptions: return "camera.setOptions"
        case ._getMySetting: return "camera._getMySetting"
        case ._setMySetting: return "camera._setMySetting"
        case ._stopSelfTimer: return "camera._stopSelfTimer"
        }
    }

    var json: JSON {
        switch self {
        case let .startCapture(mode: mode):
            return with(params: [
                "_mode": mode.rawValue
            ])
        case let .listFiles(entryCount: count, detail: detail):
            return with(params: [
                "entryCount": count,
                "_detail": detail
            ])
        case let .setOptions(options: options):
            var json: JSON = [:]
            options.forEach({ json[$0.key] = $0.value })
            return with(params: [
                "options": json.value ?? NSNull()
            ])
        default: return defaultJSON
        }
    }
}

// swiftlint:enable identifier_name
