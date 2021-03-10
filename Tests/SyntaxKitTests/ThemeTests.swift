//
//  ThemeTests.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 6/15/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

@testable import SyntaxKit
import XCTest

internal class ThemeTests: XCTestCase {

    // MARK: - Properties

    private let manager: BundleManager = getBundleManager()

    // MARK: - Tests

    func testLoading() {
        if let tomorrow = manager.theme(withIdentifier: "Tomorrow") {
            XCTAssertEqual(UUID(uuidString: "82CCD69C-F1B1-4529-B39E-780F91F07604"), tomorrow.uuid)
            XCTAssertEqual("Tomorrow", tomorrow.name)
            assertEqualColors(Color(hex: "#666969"), tomorrow.attributes["constant.other"]?[NSAttributedString.Key.foregroundColor] as? Color)
            assertEqualColors(Color(hex: "#4271AE"), tomorrow.attributes["keyword.other.special-method"]?[NSAttributedString.Key.foregroundColor] as? Color)
        } else {
            XCTFail("Should be able to load tomorrow theme fixture")
        }
    }

    func testComplexTheme() {
        if let solarized = manager.theme(withIdentifier: "Solarized") {
            XCTAssertEqual(UUID(uuidString: "38E819D9-AE02-452F-9231-ECC3B204AFD7"), solarized.uuid)
            XCTAssertEqual("Solarized (light)", solarized.name)
            assertEqualColors(Color(hex: "#2aa198"), solarized.attributes["string.quoted.double"]?[NSAttributedString.Key.foregroundColor] as? Color)
            assertEqualColors(Color(hex: "#2aa198"), solarized.attributes["string.quoted.single"]?[NSAttributedString.Key.foregroundColor] as? Color)
        } else {
            XCTFail("Should be able to load solarized theme fixture")
        }
    }
}
