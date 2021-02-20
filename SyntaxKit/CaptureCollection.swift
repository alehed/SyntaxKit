//
//  CaptureCollection.swift
//  SyntaxKit
//
//  Represents the captures attribute in a TextMate grammar.
//
//  Created by Sam Soffes on 9/19/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

internal struct CaptureCollection {

    // MARK: - Properties

    private let captures: [UInt: Capture]

    var captureIndexes: [UInt] {
        var keys = Array(captures.keys)
        keys.sort { $0 < $1 }
        return keys
    }

    // MARK: - Initializers

    init?(dictionary: [AnyHashable: Any]) {
        guard let dictionary = dictionary as? [String: [String: String]] else {
            return nil
        }

        var captures = [UInt: Capture]()
        for (key, value) in dictionary {
            if let key = UInt(key), let capture = Capture(dictionary: value) {
                captures[key] = capture
            }
        }
        self.captures = captures
    }

    // MARK: - Accessing Captures

    subscript(index: UInt) -> Capture? {
        return captures[index]
    }
}
