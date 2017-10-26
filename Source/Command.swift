//
//  Command.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation
import SwiftyyJSON

protocol Command {
    var name: String { get }
    var json: JSON { get }
}

extension Command {
    var defaultJSON: JSON {
        return ["name": self.name]
    }

    func with(params: [String: Any]) -> JSON {
        return [
            "name": self.name,
            "parameters": params
        ]
    }
}

