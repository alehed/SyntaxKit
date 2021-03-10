//
//  ParserTests.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 6/15/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

import SyntaxKit
import XCTest

internal class ParserTests: XCTestCase {

    // MARK: - Properties

    private var parser: Parser?
    private let manager: BundleManager = getBundleManager()

    // MARK: - Tests

    override func setUp() {
        super.setUp()
        if let yaml = manager.language(withIdentifier: "source.YAML") {
            parser = Parser(language: yaml)
        } else {
            XCTFail("Should be able to load yaml language fixture")
        }
    }

    func testParsingBeginEnd() {
        var stringQuoted: NSRange?
        var punctuationBegin: NSRange?
        var punctuationEnd: NSRange?

        parser?.parse("title: \"Hello World\"\n") { (scope: String, range: NSRange) in
            if stringQuoted == nil && scope.hasPrefix("string.quoted.double") {
                stringQuoted = range
            }

            if punctuationBegin == nil && scope.hasPrefix("punctuation.definition.string.begin") {
                punctuationBegin = range
            }

            if punctuationEnd == nil && scope.hasPrefix("punctuation.definition.string.end") {
                punctuationEnd = range
            }
        }

        XCTAssertEqual(NSRange(location: 7, length: 13), stringQuoted)
        XCTAssertEqual(NSRange(location: 7, length: 1), punctuationBegin)
        XCTAssertEqual(NSRange(location: 19, length: 1), punctuationEnd)
    }

    func testParsingBeginEndGarbage() {
        var stringQuoted: NSRange?

        parser?.parse("title: Hello World\ncomments: 24\nposts: \"12\"zz\n") { (scope: String, range: NSRange) in
            if stringQuoted == nil && scope.hasPrefix("string.quoted.double") {
                stringQuoted = range
            }
        }

        XCTAssertEqual(NSRange(location: 39, length: 4), stringQuoted)
    }

    func testParsingGarbage() {
        parser?.parse("") { _, _ in }
        parser?.parse("ainod adlkf ac\nv a;skcja\nsd flaksdfj [awiefasdvxzc\\vzxcx c\n\n\nx \ncvas\ndv\nas \ndf as]pkdfa \nsd\nfa sdos[a \n\n a\ns cvsa\ncd\n a \ncd\n \n\n\n asdcp[vk sa\n\ndd'; \nssv[ das \n\n\nlkjs") { _, _ in }
    }

    func testRuby() {
        if let ruby = manager.language(withIdentifier: "source.Ruby") {
            parser = Parser(language: ruby)
            let input = fixture("test.rb", "txt")
            parser?.parse(input) { _, _ in return }
        } else {
            XCTFail("Should be able to load ruby language fixture")
        }
    }
}
