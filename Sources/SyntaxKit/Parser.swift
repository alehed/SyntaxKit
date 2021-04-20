//
//  Parser.swift
//  SyntaxKit
//
//  This class is in charge of the painful task of recognizing the syntax
//  patterns. It tries to match parsing behavior of TextMate as closely as
//  possible.
//
//  Created by Sam Soffes on 9/19/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

open class Parser {

    // MARK: - Types

    public typealias Callback = (_ scope: String, _ range: NSRange) -> Void

    // MARK: - Properties

    /// The Language that the parser recognizes
    public let language: Language

    /// String that is used in parse(in:). May already contain lexical
    /// information from previous calls to parse for incremental parsing.
    /// Stores the recognized lexical scopes after a successful call to parse.
    var toParse: ScopedString = ScopedString(string: "")
    /// Set to true to abort the parsing pass
    var aborted: Bool = false

    // MARK: - Initializers

    public init(language: Language) {
        self.language = language
    }

    // MARK: - Public

    open func parse(_ string: String, match callback: Callback) {
        if aborted {
            return
        }
        self.toParse = ScopedString(string: string)
        parse(match: callback)
    }

    // MARK: - Private

    /// Parses the string in toParse. Supports incremental parsing.
    ///
    /// - parameter range:  The range that should be re-parsed or nil if the
    ///                     entire string should be parsed. It may be exceeded
    ///                     if necessary to match a pattern entirely. For
    ///                     calculation of such a range take a look at
    ///                     outdatedRange(in: forChange:).
    /// - parameter match:  The callback to call on every match of a pattern
    ///                     identifier of the language.
    func parse(in range: NSRange? = nil, match: Callback) {

        let bounds: NSRange = range ?? NSRange(location: 0, length: (toParse.string as NSString).length)
        assert((toParse.string as NSString).length >= NSMaxRange(bounds))
        var endScope = toParse.topmostScope(atIndex: bounds.location)
        var startIndex = bounds.location
        var endIndex = NSMaxRange(bounds)
        let allResults = ResultSet(startingRange: bounds)

        while startIndex < endIndex {
            let endPattern = endScope.attribute as? Pattern ?? language.pattern
            guard let results = self.matchSubpatterns(of: endPattern, in: NSRange(location: startIndex, length: endIndex - startIndex), beginResults: nil) else {
                return
            }

            allResults.add(Result(identifier: endScope.patternIdentifier, range: results.range))

            if results.range.length != 0 {
                allResults.add(results)
                startIndex = NSMaxRange(results.range)
                endScope = toParse.lowerScope(for: endScope, atIndex: startIndex)
            } else {
                startIndex = endIndex
            }

            if startIndex > endIndex && toParse.isInString(index: startIndex + 1) {
                let scopeAtIndex = toParse.topmostScope(atIndex: startIndex + 1)
                if toParse.level(for: scopeAtIndex) > toParse.level(for: endScope) {
                    endIndex = NSMaxRange(scopeAtIndex.range)
                }
            }
        }

        if aborted {
            return
        }
        toParse.removeScopes(in: allResults.range)
        self.apply(allResults, callback: match)
    }

    // Algorithmic notes:
    // A pattern expression can not match a substring spanning multiple lines
    // so in the outer loop the string is decomposed into its lines.
    // In the inner loop it tries to repeatedly match a pattern followed by the
    // end pattern until either the line is consumed or it has found the end.
    // This procedure is repeated with the subsequent lines until it has either
    // matched the end pattern or the string is consumed entirely.
    // If it can find neither in a line it moves to the next one.

    // Implementation note:
    // The matching of the middle part may return a match that goes beyond the
    // given range. This is intentional.

    /// Matches subpatterns of the given pattern in the input.
    ///
    /// - parameter pattern:    The patterns whose subpatterns should be matched
    /// - parameter range:      The range in which the matching should occur.
    ///
    /// - returns:  The result set containing the lexical scope names with range
    ///             information or nil if aborted. May exceed range.
    private func matchSubpatterns(of pattern: Pattern, in range: NSRange, beginResults begin: ResultSet?) -> ResultSet? {
        let stop = range.location + range.length
        var lineStart = range.location
        var lineEnd = range.location
        let result = ResultSet(startingRange: NSRange(location: range.location, length: 0))

        while lineEnd < stop {
            (toParse.string as NSString).getLineStart(nil, end: &lineEnd, contentsEnd: nil, for: NSRange(location: lineEnd, length: 0))
            var range = NSRange(location: lineStart, length: lineEnd - lineStart)

            while range.length > 0 {
                if aborted {
                    return nil
                }

                let bestMatchForMiddle = self.match(pattern.subpatterns, in: range)

                if let patternEnd = pattern.end {
                    if let endMatchResult = self.match(patternEnd.expandedRegularExpression(with: toParse.string, matches: begin), in: range, captures: pattern.endCaptures) {
                        if let middleMatch = bestMatchForMiddle {
                            if !pattern.applyEndPatternLast && endMatchResult.range.location <= middleMatch.match.range.location || endMatchResult.range.location < middleMatch.match.range.location {
                                result.add(endMatchResult)
                                return result
                            }
                        } else {
                            result.add(endMatchResult)
                            return result
                        }
                    }
                }

                guard let middleMatch = bestMatchForMiddle,
                      let middleResult = middleMatch.pattern.match != nil ? middleMatch.match : self.matchAfterBegin(of: middleMatch.pattern, beginResults: middleMatch.match) else {
                    break
                }
                if middleResult.range.length == 0 {
                    break
                }
                result.add(middleResult)
                let newStart = NSMaxRange(middleResult.range)
                range = NSRange(location: newStart, length: max(0, range.length - (newStart - range.location)))
                lineEnd = max(lineEnd, newStart)
            }

            lineStart = lineEnd
        }

        result.extend(with: range)
        return result
    }

    /// Helper method that iterates over the given patterns and tries to match
    /// them. Returns the matched pattern with the highest priority
    /// (first criterion: matched sooner, second: higher up the list).
    ///
    /// - parameter patterns:   The patterns that can be matched
    /// - parameter range:      The range in which the matching should happen.
    ///
    /// - returns:  The matched pattern and the matching result. Nil on failure.
    ///             The results range may exceed the passed in range.
    private func match(_ patterns: [Pattern], in range: NSRange) -> (pattern: Pattern, match: ResultSet)? {
        var interestingBounds = range
        var bestResult: (pattern: Pattern, match: ResultSet)?
        for pattern in patterns {
            let currentMatch = self.firstMatch(of: pattern, in: range, beginResults: bestResult?.match)
            if currentMatch?.match.range.location == range.location {
                return currentMatch
            } else if let currMatch = currentMatch {
                if let best = bestResult {
                    if currMatch.match.range.location < best.match.range.location {
                        bestResult = currentMatch
                        interestingBounds.length = currMatch.match.range.location - interestingBounds.location
                    }
                } else {
                    bestResult = currentMatch
                    interestingBounds.length = currMatch.match.range.location - interestingBounds.location
                }
            }
        }
        return bestResult
    }

    /// Matches a single pattern in the string in the given range
    ///
    /// - parameter pattern:    The Pattern to match in the string
    /// - parameter range:      The range in which to match the pattern
    ///
    /// - returns: The matched pattern and the matching result. Nil on failure.
    private func firstMatch(of pattern: Pattern, in range: NSRange, beginResults begin: ResultSet?) -> (pattern: Pattern, match: ResultSet)? {
        if let expression = pattern.match {
            if let resultSet = self.match(expression.expandedRegularExpression(with: toParse.string, matches: begin), in: range, captures: pattern.captures, baseSelector: pattern.name) {
                if resultSet.range.length != 0 {
                    return (pattern, resultSet)
                }
            }
        } else if let begin = pattern.begin {
            if let beginResults = self.match(begin, in: range, captures: pattern.beginCaptures) {
                return (pattern, beginResults)
            }
        } else if pattern.subpatterns.count >= 1 {
            return self.match(pattern.subpatterns, in: range)
        }
        return nil
    }

    // Implementation note:
    // The order in which the beginning middle and end are added to the final
    // result matters.

    /// Matches the middle and end of the given pattern
    ///
    /// - parameter pattern:    The pattern whose subpatterns and end pattern
    ///                         has to be matched
    /// - parameter begin:      The match result of the beginning
    /// - returns:  The result of matching the given pattern or nil on abortion.
    private func matchAfterBegin(of pattern: Pattern, beginResults begin: ResultSet) -> ResultSet? {
        let newLocation = NSMaxRange(begin.range)
        guard let endResults = self.matchSubpatterns(of: pattern, in: NSRange(location: newLocation, length: (toParse.string as NSString).length - newLocation), beginResults: begin) else {
            return nil
        }

        let result = ResultSet(startingRange: endResults.range)
        if let patternName = pattern.name {
            result.add(Result(identifier: patternName, range: NSUnionRange(begin.range, endResults.range)))
        }
        result.add(Scope(identifier: pattern.name ?? "", range: NSRange(location: begin.range.location + begin.range.length, length: NSUnionRange(begin.range, endResults.range).length - begin.range.length), attribute: pattern))
        result.add(begin)
        result.add(endResults)
        return result
    }

    /// Matches a given regular expression in the String and returns range
    /// information for the captures
    ///
    /// - parameter expression:     The regular expression to match
    /// - parameter range:          The range to which to restrict the match
    /// - parameter captures:       A collection of captures that can be used to
    ///                             add extra information to parts of the match.
    /// - parameter baseSelector:   String to associate with the entire range of
    ///                             the match
    ///
    /// - returns:  The set containing the results. May be nil if the expression
    ///             could not match any part of the string. It may also be empty
    ///             and only contain range information to show what it matched.
    private func match(_ expression: RegularExpression, in range: NSRange, captures: CaptureCollection?, baseSelector: String? = nil) -> ResultSet? {
        guard let result = expression.firstMatch(in: toParse.string, options: [.withTransparentBounds], range: range) else {
            return nil
        }

        let resultSet = ResultSet(startingRange: result.range)
        if let base = baseSelector {
            resultSet.add(Result(identifier: base, range: result.range, result: result))
        }

        if let captures = captures {
            for index in captures.captureIndexes {
                if result.numberOfRanges <= Int(index) {
                    print("Attention unexpected capture (\(index) to \(result.numberOfRanges)): \(expression.pattern)")
                    continue
                }
                let range = result.range(at: Int(index))
                if range.location == NSNotFound {
                    continue
                }
                
                if let scope = captures[index]?.name {
                    resultSet.add(Result(identifier: scope, range: range, result: result))
                }
            }
        }

        return resultSet
    }

    /// Uses the callback to communicate the results of the parsing pass back to
    /// the caller of parse. The scopes are stored in toParse.
    ///
    /// - parameter results:    The results of the parsing pass
    /// - parameter callback:   The method to call on every successful match
    private func apply(_ results: ResultSet, callback: Callback) {
        callback(Language.globalScope, results.range)
        for result in results.results where result.range.length > 0 {
            if result.attribute != nil {
                toParse.addAtTop(result as Scope)
            } else if result.patternIdentifier != "" {
                callback(result.patternIdentifier, result.range)
            }
        }
    }
}
