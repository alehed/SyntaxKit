//
//  BackReferenceTests.swift
//  SyntaxKit
//
//  Created by Zheng Wu on 2021/2/19.
//  Copyright © 2021 Zheng Wu. All rights reserved.
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

        let testString1 = "title: Hello World\ncomments: \\24\nposts: \"12\\3\"zz\n"
        let testString2 = "title: Hello World\ncomments: $24\nposts: \"12$3\"zz\n"
        XCTAssertEqual(testString1.convertToICUBackReferencedRegex(), testString2)
        XCTAssertEqual(testString2.convertToBackReferencedRegex(), testString1)
        
        XCTAssertEqual("(?<=\\.) {2,}(?=[A-Z])".addingRegexEscapedCharacters(), "\\(\\?<=\\\\\\.\\) \\{2,\\}\\(\\?=\\[A-Z\\]\\)")
    }

    func testBackReference() throws {
        var blockComment: NSRange?
        var commentBegin: NSRange?
        var commentEnd: NSRange?

        parser?.parse("\"Emmmm...\" --[=[ This is \na multi-line comment. ]=]") { (scope: String, range: NSRange) in
            if blockComment == nil && scope.hasPrefix("comment.block.lua") {
                blockComment = range
            }

            if commentBegin == nil && scope.hasPrefix("punctuation.definition.comment.begin.lua") {
                commentBegin = range
            }

            if commentEnd == nil && scope.hasPrefix("punctuation.definition.comment.end.lua") {
                commentEnd = range
            }
        }

        XCTAssertEqual(NSRange(location: 11, length: 40), blockComment)
        XCTAssertEqual(NSRange(location: 11, length: 5), commentBegin)
        XCTAssertEqual(NSRange(location: 48, length: 3), commentEnd)

        var blockString: NSRange?
        var stringBegin: NSRange?
        var stringEnd: NSRange?

        parser?.parse("--[=[ Emmmm...]=] [===[ This is \na multi-line string. ]===]") { (scope: String, range: NSRange) in
            debugPrint(scope, range)

            if blockString == nil && scope.hasPrefix("string.quoted.other.multiline.lua") {
                blockString = range
            }

            if stringBegin == nil && scope.hasPrefix("punctuation.definition.string.begin.lua") {
                stringBegin = range
            }

            if stringEnd == nil && scope.hasPrefix("punctuation.definition.string.end.lua") {
                stringEnd = range
            }
        }

        XCTAssertEqual(NSRange(location: 18, length: 41), blockString)
        XCTAssertEqual(NSRange(location: 18, length: 5), stringBegin)
        XCTAssertEqual(NSRange(location: 54, length: 5), stringEnd)
    }

    func testBackReferencePerformance() throws {
        self.measure {
            let input = fixture("test.lua", "txt")
            parser?.parse(input) { _, _ in return }
        }
    }

}
