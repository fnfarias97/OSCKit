//
//  OptionalThrow.swift
//  ThreeSixtyCamera
//
//  Created by Zhigang Fang on 4/18/17.
//  Copyright © 2017 Tappollo Inc. All rights reserved.
//

import Foundation

infix operator !! : LogicalConjunctionPrecedence

func !!<T>(optional: Optional<T>, error: Error) throws -> T {
    return try optional.someOrThrow(error)
}

extension Optional {
    func someOrThrow(_ error: Error) throws -> Wrapped {
        if let value = self {
            return value
        }
        throw error
    }
}

func const<T, V>(value: T) -> (V) -> T {
    return { _ in
        value
    }
}
