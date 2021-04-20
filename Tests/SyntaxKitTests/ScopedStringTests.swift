//
//  ScopedStringTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 30/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

@testable import SyntaxKit
import XCTest

internal class ScopedStringTests: XCTestCase {

    func testScopesString() {
        var newScopedString = ScopedString(string: "Test")
        XCTAssertEqual(newScopedString.numberOfScopes(), 1)
        XCTAssertEqual(newScopedString.numberOfLevels(), 1)

        XCTAssertEqual(newScopedString.topmostScope(atIndex: 2), newScopedString.baseScope)

        let newScope1 = Scope(identifier: "bogus", range: NSRange(location: 1, length: 3), attribute: nil)
        newScopedString.addAtTop(newScope1)
//        print(newScopedString.prettyRepresentation())

        XCTAssertEqual(newScopedString.numberOfScopes(), 2)
        XCTAssertEqual(newScopedString.numberOfLevels(), 2)

        XCTAssertEqual(newScopedString.topmostScope(atIndex: 0), newScopedString.baseScope)
        XCTAssertEqual(newScopedString.topmostScope(atIndex: 1), newScope1)
        XCTAssertEqual(newScopedString.lowerScope(for: newScope1, atIndex: 1), newScopedString.baseScope)

        let newScope2 = Scope(identifier: "bogus2", range: NSRange(location: 2, length: 1), attribute: nil)
        newScopedString.addAtTop(newScope2)
//        print(newScopedString.prettyRepresentation())

        XCTAssertEqual(newScopedString.numberOfScopes(), 3)
        XCTAssertEqual(newScopedString.numberOfLevels(), 3)

        XCTAssertEqual(newScopedString.topmostScope(atIndex: 1), newScope1)
        XCTAssertEqual(newScopedString.topmostScope(atIndex: 2), newScope2)
        XCTAssertNotEqual(newScopedString.numberOfScopes(), 1)

        newScopedString.deleteCharacters(in: NSRange(location: 2, length: 1))
//        print(newScopedString.prettyRepresentation())
        XCTAssertEqual(newScopedString.string, "Tet")
        XCTAssertEqual(newScopedString.numberOfScopes(), 2)
        XCTAssertEqual(newScopedString.numberOfLevels(), 2)

        XCTAssertEqual(newScopedString.topmostScope(atIndex: 1).range, NSRange(location: 1, length: 2))

        newScopedString.insert("ssssss", atIndex: 2)
//        print(newScopedString.prettyRepresentation())
        XCTAssertEqual(newScopedString.string, "Tesssssst")
        XCTAssertEqual(newScopedString.numberOfScopes(), 2)

        newScopedString.removeScopes(in: NSRange(location: 0, length: 1))
        XCTAssertEqual(newScopedString.numberOfScopes(), 2)

        XCTAssertEqual(newScopedString.topmostScope(atIndex: 2).range, NSRange(location: 1, length: 8))
    }

    func testRangeExtension() {
        var someRange = NSRange(location: 0, length: 24)
        XCTAssertFalse(someRange.isEmpty())

        someRange = NSRange(location: 49, length: 0)
        XCTAssertTrue(someRange.isEmpty())

        someRange = NSRange(location: 4, length: 2)
        XCTAssertTrue(someRange.contains(index: 4))
        XCTAssertFalse(someRange.contains(index: 1))
        XCTAssertFalse(someRange.contains(index: 23))

        someRange = NSRange(location: 0, length: 24)
        someRange.removeIndexes(from: NSRange(location: 2, length: 4))
        XCTAssertEqual(someRange, NSRange(location: 0, length: 20))

        someRange = NSRange(location: 20, length: 40)
        someRange.removeIndexes(from: NSRange(location: 4, length: 12))
        XCTAssertEqual(someRange, NSRange(location: 8, length: 40))

        someRange = NSRange(location: 23, length: 11)
        someRange.removeIndexes(from: NSRange(location: 20, length: 5))
        XCTAssertEqual(someRange, NSRange(location: 20, length: 9))

        someRange = NSRange(location: 10, length: 14)
        someRange.removeIndexes(from: NSRange(location: 5, length: 40))
        XCTAssertTrue(someRange.isEmpty())

        someRange = NSRange(location: 23, length: 11)
        someRange.insertIndexes(from: NSRange(location: 20, length: 5))
        XCTAssertEqual(someRange, NSRange(location: 28, length: 11))

        someRange = NSRange(location: 14, length: 2)
        someRange.insertIndexes(from: NSRange(location: 15, length: 7))
        XCTAssertEqual(someRange, NSRange(location: 14, length: 9))

        someRange = NSRange(location: 26, length: 36)
        someRange.insertIndexes(from: NSRange(location: 62, length: 5))
        XCTAssertEqual(someRange, NSRange(location: 26, length: 36))
    }
}
