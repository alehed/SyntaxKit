//
//  BackReferenceTests.swift
//  SyntaxKit
//
//  Created by Rachel on 2021/2/19.
//  Copyright © 2021 Sam Soffes. All rights reserved.
//

@testable import SyntaxKit
import XCTest

internal class BackReferenceTests: XCTestCase {

    // MARK: - Properties

    private var parser: Parser?
    private let manager: BundleManager = getBundleManager()

    // MARK: - Tests

    override func setUp() {
        super.setUp()
        if let lua = manager.language(withIdentifier: "source.lua") {
            parser = Parser(language: lua)
        } else {
            XCTFail("Should be able to load lua language fixture")
        }
    }

    func testBackReferenceHelpers() throws {
        XCTAssertFalse("title: \"Hello World\"\n".hasBackReferencePlaceholder)
        XCTAssertFalse("title: Hello World\ncomments: 24\nposts: \"12\"zz\n".hasBackReferencePlaceholder)
        XCTAssert("title: Hello World\ncomments: 24\nposts: \"12\\3\"zz\n".hasBackReferencePlaceholder)
        
        XCTAssertEqual("title: Hello World\ncomments: \\24\nposts: \"12\\3\"zz\n".convertToICUBackReferencedRegex(), "title: Hello World\ncomments: $24\nposts: \"12$3\"zz\n")
        XCTAssertEqual("title: Hello World\ncomments: $24\nposts: \"12$3\"zz\n".convertToBackReferencedRegex(), "title: Hello World\ncomments: \\24\nposts: \"12\\3\"zz\n")
        
        XCTAssertEqual("(?<=\\.) {2,}(?=[A-Z])".addingRegexEscapedCharacters(), "\\(\\?<=\\\\\\.\\) \\{2,\\}\\(\\?=\\[A-Z\\]\\)")
    }

    func testBackReference() throws {
        // TODO
    }

    func testBackReferencePerformance() throws {
        self.measure {
            let input = fixture("test.lua", "txt")
            parser?.parse(input) { _, _ in return }
        }
    }

}
