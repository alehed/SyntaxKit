//
//  TestHelper.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 6/15/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

import Foundation
@testable import SyntaxKit
import XCTest

private let fixturesBundleURL = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Fixtures").appendingPathComponent("TestSyntaxKit.bundle")

internal func fixture(_ name: String, _ type: String) -> String {
    guard let testBundle = Bundle(url: fixturesBundleURL) else {
        return ""
    }
    guard let url = testBundle.url(forResource: name, withExtension: type) else {
        return ""
    }
    do {
        return try String(contentsOf: url)
    } catch {
        return ""
    }
}

internal func getBundleManager() -> BundleManager {
    return BundleManager { identifier, kind in
        let name = kind == .language ? String(identifier.split(separator: ".")[1]) : identifier
        let ext = kind == .language ? ".tmLanguage" : ".tmTheme"
        print("[*] Loading resources for \(name.capitalized)\(ext)")
        return Bundle(url: fixturesBundleURL)?.url(forResource: name.capitalized, withExtension: ext) ?? URL(fileURLWithPath: "")
    }
}

internal func simpleTheme() -> Theme? {
    return Theme(dictionary: [
        "uuid": "123e4567-e89b-12d3-a456-426655440000",
        "name": "Simple",
        "settings": [
            [
                "scope": "entity.name",
                "settings": [
                    "color": "blue"
                ]
            ],
            [
                "scope": "string",
                "settings": [
                    "color": "red"
                ]
            ],
            [
                "scope": "constant.numeric",
                "settings": [
                    "color": "purple"
                ]
            ]
        ]
    ])
}

internal func replace(_ range: NSRange, in string: String, with inserted: String) -> String {
    let newInput = string.mutableCopy() as? NSMutableString
    newInput?.replaceCharacters(in: range, with: inserted)
    return newInput?.copy() as? String ?? ""
}

internal func assertEqualColors(_ color1: Color?, _ color2: Color?, accuracy: CGFloat = 0.005) {
    guard let lhColor = color1, let rhColor = color2 else {
        XCTAssert(false, "colors have to be non-nil")
        return
    }
    XCTAssertEqual(lhColor.redComponent, rhColor.redComponent, accuracy: accuracy)
    XCTAssertEqual(lhColor.greenComponent, rhColor.greenComponent, accuracy: accuracy)
    XCTAssertEqual(lhColor.blueComponent, rhColor.blueComponent, accuracy: accuracy)
    XCTAssertEqual(lhColor.alphaComponent, rhColor.alphaComponent, accuracy: accuracy)
}
