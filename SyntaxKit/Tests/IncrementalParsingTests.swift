//
//  IncrementalParsingTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 27/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import SyntaxKit
import XCTest

internal class IncrementalParsingTests: XCTestCase {

    // MARK: - Properties

    private let manager: BundleManager = getBundleManager()
    private var parsingOperation: AttributedParsingOperation?
    private var totalRange: NSRange?
    private var input: String = ""

    // MARK: - Tests

    override func setUp() {
        super.setUp()
    }

    func testEdits() {
        input = fixture("test.swift", "txt")
        parsingOperation = getParsingOperation()

        parsingOperation?.main()
        XCTAssertEqual(totalRange, NSRange(location: 0, length: (input as NSString).length))

        assertInsertion("i", location: 162, expectedRange: NSRange(location: 159, length: 5))

        assertDeletion(NSRange(location: 162, length: 1), expectedRange: NSRange(location: 159, length: 4))

        assertInsertion("756", location: 160, expectedRange: NSRange(location: 159, length: 7))
    }

    func testDeletion() {
        input = "Only this!"
        parsingOperation = getParsingOperation()

        parsingOperation?.main()

        assertDeletion(NSRange(location: 9, length: 1), expectedRange: NSRange(location: 0, length: 9))
    }

    func testEdgeCase() {
        input = "// test.swift\n/**"
        parsingOperation = getParsingOperation()

        parsingOperation?.main()
        XCTAssertEqual(totalRange, NSRange(location: 0, length: 17))

        assertDeletion(NSRange(location: 2, length: 1), expectedRange: NSRange(location: 0, length: 13))

        assertInsertion(" ", location: 2, expectedRange: NSRange(location: 0, length: 14))

        assertInsertion("\n", location: 17, expectedRange: NSRange(location: 14, length: 4))
    }

    func testPerformanceInScope() {
        input = fixture("test.swift", "txt")
        parsingOperation = getParsingOperation()

        parsingOperation?.main()

        self.measure {
            self.assertInsertion("Tests", location: 239, expectedRange: NSRange(location: 230, length: 24))

            self.assertDeletion(NSRange(location: 239, length: 5), expectedRange: NSRange(location: 230, length: 19))
        }
    }

    func testPerformanceEdgeCases() {
        input = fixture("test.swift", "txt")
        parsingOperation = getParsingOperation()

        parsingOperation?.main()

        self.measure {
            self.assertDeletion(NSRange(location: 139, length: 1), expectedRange: NSRange(location: 139, length: 22))

            self.assertInsertion("/", location: 139, expectedRange: NSRange(location: 139, length: 23))
        }
    }

    // MARK: - Helpers

    private func getParsingOperation() -> AttributedParsingOperation? {
        if let language = manager.language(withIdentifier: "Source.swift"),
            let theme = manager.theme(withIdentifier: "tomorrow") {
            return AttributedParsingOperation(string: input, language: language, theme: theme) { (results: [(range: NSRange, attributes: Attributes?)], _: AttributedParsingOperation) in
                for result in results {
                    if let range = self.totalRange {
                        self.totalRange = NSUnionRange(range, result.range)
                    } else {
                        self.totalRange = result.range
                    }
                }
            }
        } else {
            XCTFail("Should be able to load swift language fixture")
            return nil
        }
    }

    private func assertInsertion(_ string: String, location: Int, expectedRange expected: NSRange) {
        input = replace(NSRange(location: location, length: 0), in: input, with: string)
        if let previousOperation = parsingOperation {
            parsingOperation = AttributedParsingOperation(string: input, previousOperation: previousOperation, changeIsInsertion: true, changedRange: NSRange(location: location, length: (string as NSString).length))

            totalRange = nil
            parsingOperation?.main()
            XCTAssertEqual(totalRange, expected)
        } else {
            XCTFail("Should have been able to get parsing operation")
        }
    }

    private func assertDeletion(_ range: NSRange, expectedRange expected: NSRange) {
        input = replace(range, in: input, with: "")
        if let previousOperation = parsingOperation {
            parsingOperation = AttributedParsingOperation(string: input, previousOperation: previousOperation, changeIsInsertion: false, changedRange: range)

            totalRange = nil
            parsingOperation?.main()
            XCTAssertEqual(totalRange, expected)
        } else {
            XCTFail("Should have been able to get parsing operation")
        }
    }
}
