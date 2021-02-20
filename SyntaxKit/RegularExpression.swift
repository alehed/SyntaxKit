//
//  RegularExpression.swift
//  SyntaxKit
//
//  Created by Rachel on 2021/2/19.
//  Copyright © 2021 Sam Soffes. All rights reserved.
//

internal class RegularExpression {

    // MARK: - Properties

    var pattern: String { return _pattern }
    var options: RegularExpression.Options { return _options }
    var isTemplate: Bool { return _isTemplate }
    var expression: NSRegularExpression? { return _expression }

    // swiftlint:disable strict_fileprivate
    fileprivate var _pattern: String
    fileprivate var _options: RegularExpression.Options
    fileprivate var _isTemplate: Bool
    fileprivate var _expression: NSRegularExpression?
    // swiftlint:enable strict_fileprivate

    // MARK: - Initializer

    init(pattern: String, options: RegularExpression.Options = []) throws {
        self._pattern = pattern
        self._options = options
        self._isTemplate = pattern.hasBackReferencePlaceholder
        if !self._isTemplate {
            self._expression = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: options.rawValue))
        }
    }
}

/* NSRegularExpression Implementation */

internal extension RegularExpression {
    struct Options : OptionSet {
        let rawValue: UInt
        init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        static let caseInsensitive = Options(rawValue: NSRegularExpression.Options.caseInsensitive.rawValue)
        static let allowCommentsAndWhitespace = Options(rawValue: NSRegularExpression.Options.allowCommentsAndWhitespace.rawValue)
        static let ignoreMetacharacters = Options(rawValue: NSRegularExpression.Options.ignoreMetacharacters.rawValue)
        static let dotMatchesLineSeparators = Options(rawValue: NSRegularExpression.Options.dotMatchesLineSeparators.rawValue)
        static let anchorsMatchLines = Options(rawValue: NSRegularExpression.Options.anchorsMatchLines.rawValue)
        static let useUnixLineSeparators = Options(rawValue: NSRegularExpression.Options.useUnixLineSeparators.rawValue)
        static let useUnicodeWordBoundaries = Options(rawValue: NSRegularExpression.Options.useUnicodeWordBoundaries.rawValue)
    }

    struct MatchingOptions : OptionSet {
        let rawValue: UInt
        init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        static let reportProgress = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.reportProgress.rawValue)
        static let reportCompletion = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.reportCompletion.rawValue)
        static let anchored = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.anchored.rawValue)
        static let withTransparentBounds = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.withTransparentBounds.rawValue)
        static let withoutAnchoringBounds = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.withoutAnchoringBounds.rawValue)
    }

    struct MatchingFlags : OptionSet {
        let rawValue: UInt
        init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        static var progress = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.progress.rawValue)
        static var completed = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.completed.rawValue)
        static var hitEnd = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.hitEnd.rawValue)
        static var requiredEnd = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.requiredEnd.rawValue)
        static var internalError = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.internalError.rawValue)
    }
}

internal extension RegularExpression {

    var numberOfCaptureGroups: Int {
        return _expression?.numberOfCaptureGroups ?? 0
    }

    static func escapedPattern(for string: String) -> String {
        return NSRegularExpression.escapedPattern(for: string)
    }

}

internal extension RegularExpression {

    func enumerateMatches(in string: String, options: RegularExpression.MatchingOptions = [], range: NSRange, using block: (NSTextCheckingResult?, RegularExpression.MatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void) {
        _expression?.enumerateMatches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: options.rawValue), range: range) { (result, flags, stop) in
            block(result, RegularExpression.MatchingFlags(rawValue: flags.rawValue), stop)
        }
    }

    func matches(in string: String, options: RegularExpression.MatchingOptions = [], range: NSRange) -> [NSTextCheckingResult] {
        return _expression?.matches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: options.rawValue), range: range) ?? []
    }

    func numberOfMatches(in string: String, options: RegularExpression.MatchingOptions = [], range: NSRange) -> Int {
        return _expression?.numberOfMatches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: options.rawValue), range: range) ?? 0
    }

    func firstMatch(in string: String, options: RegularExpression.MatchingOptions = [], range: NSRange) -> NSTextCheckingResult? {
        return _expression?.firstMatch(in: string, options: NSRegularExpression.MatchingOptions(rawValue: options.rawValue), range: range)
    }

    func rangeOfFirstMatch(in string: String, options: RegularExpression.MatchingOptions = [], range: NSRange) -> NSRange {
        return _expression?.rangeOfFirstMatch(in: string, options: NSRegularExpression.MatchingOptions(rawValue: options.rawValue), range: range) ?? NSRange(location: NSNotFound, length: 0)
    }

}

/* NSRegularExpression's find-and-replace methods, not used. */

internal extension RegularExpression {

    func stringByReplacingMatches(in string: String, options: RegularExpression.MatchingOptions = [], range: NSRange, withTemplate templ: String) -> String {
        fatalError("not supported")
    }

    func replaceMatches(in string: NSMutableString, options: RegularExpression.MatchingOptions = [], range: NSRange, withTemplate templ: String) -> Int {
        fatalError("not supported")
    }

    func replacementString(for result: NSTextCheckingResult, in string: String, offset: Int, template templ: String) -> String {
        fatalError("not supported")
    }

    class func escapedTemplate(for string: String) -> String {
        fatalError("not supported")
    }

}
