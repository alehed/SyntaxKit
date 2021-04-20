//
//  SwiftBaselineHighlightingTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 19/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation
@testable import SyntaxKit
import XCTest

internal class SwiftBaselineHighlightingTests: XCTestCase {

    // MARK: - Properties

    let manager: BundleManager = getBundleManager()
    var parser: AttributedParser?

    // MARK: - Tests

    override func setUp() {
        super.setUp()
        if let swift = manager.language(withIdentifier: "source.Swift"),
            let solarized = manager.theme(withIdentifier: "Solarized") {
            parser = AttributedParser(language: swift, theme: solarized)
        } else {
            XCTFail("Should be able to load swift language fixture")
        }
    }

    func testColors() {
        let input = fixture("test.swift", "txt")
        if let string = parser?.attributedString(for: input) {
            // line comment
            assertEqualColors(Color(hex: "#93A1A1"), string.attributes(at: 10, effectiveRange: nil)[NSAttributedString.Key.foregroundColor] as? Color)
            assertEqualColors(Color(hex: "#93A1A1"), string.attributes(at: 135, effectiveRange: nil)[NSAttributedString.Key.foregroundColor] as? Color)

            // block comment
            //        print((string.string as NSString).substringWithRange(NSRange(location: 157, length: 20)))
            assertEqualColors(Color(hex: "#93A1A1"), string.attributes(at: 157, effectiveRange: nil)[NSAttributedString.Key.foregroundColor] as? Color)

            // string literal
            //        print((string.string as NSString).substringWithRange(NSRange(location: 744, length: 6)))
            assertEqualColors(Color(hex: "#839496"), string.attributes(at: 744, effectiveRange: nil)[NSAttributedString.Key.foregroundColor] as? Color)
            var stringRange = NSRange()
            assertEqualColors(Color(hex: "#2aa198"), string.attributes(at: 745, effectiveRange: &stringRange)[NSAttributedString.Key.foregroundColor] as? Color)
            XCTAssertEqual(stringRange.length, 4)
            assertEqualColors(Color(hex: "#839496"), string.attributes(at: 749, effectiveRange: nil)[NSAttributedString.Key.foregroundColor] as? Color)

            // number literal
            var numberRange = NSRange()
            //        print((string.string as NSString).substringWithRange(NSRange(location: 715, length: 3)))
            assertEqualColors(Color(hex: "#d33682"), string.attributes(at: 715, effectiveRange: &numberRange)[NSAttributedString.Key.foregroundColor] as? Color)
            XCTAssertEqual(numberRange, NSRange(location: 715, length: 1))
        } else {
            XCTFail("Parser loading should have succeeded")
        }
    }

    func testHighlightingPerformance() {
        let input = fixture("test.swift", "txt")
        self.measure {
            _ = self.parser?.attributedString(for: input)
        }
    }
}
