//
//  PerformanceTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 05/01/17.
//  Copyright © 2017 Sam Soffes. All rights reserved.
//

import SyntaxKit
import XCTest

internal class PerformanceTests: XCTestCase {

    // MARK: - Properties

    private let manager: BundleManager = getBundleManager()
    private var parser: AttributedParser?

    override func setUp() {
        super.setUp()
        if let latex = manager.language(withIdentifier: "source.Latex"),
            let solarized = manager.theme(withIdentifier: "Solarized") {
            parser = AttributedParser(language: latex, theme: solarized)
        } else {
            XCTFail("Should be able to load latex language fixture")
        }
    }

    func testLongTexFilePerformance() {
        let input = fixture("test.tex", "txt")
        self.measure {
            _ = self.parser?.attributedString(for: input)
        }
    }

}
