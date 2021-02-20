//
//  AttributedParsingOperation.swift
//  SyntaxKit
//
//  Subclass of NSOperation that can be used for mutithreaded incremental
//  parsing with all the benefits of NSOperationQueue.
//
//  It's underlying parser is an attributed parser. In theory this could be
//  refactored into a superclass that uses parser and a subclass that uses
//  attributed parser, but honestly I don't see a use-case of ParsingOperation
//  so there is only this class.
//
//  Note that the callback returns an array of results instead of each result
//  separately. This is more efficient since it allows coalescing the edits
//  between a beginEditing and an endEditing call.
//
//  Created by Alexander Hedges on 17/04/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation

/// Represents one change (insertion or deletion) between two strings
internal struct Diff {

    // MARK: - Properties

    /// - Insertion: The inserted sting
    /// - Deletion:  The empty string
    var change: String
    /// The range of the change in the old string
    ///
    /// - Insertion: The location of the insertion and length 0
    /// - Deletion:  The range of deleted characters
    var range: NSRange

    // MARK: - Methods

    /// - returns:  true if the diff represents the changes between oldString to
    ///             newString
    func representsChanges(from oldString: String, to newString: String) -> Bool {
        return newString == (oldString as NSString).replacingCharacters(in: range, with: change)
          && self.change == (newString as NSString).substring(with: self.rangeInNewString())
    }

    /// - returns: the range of the change in the new string
    func rangeInNewString() -> NSRange {
        return NSRange(location: self.range.location, length: isInsertion() ? (self.change as NSString).length : 0)
    }

    /// - returns: true if the change is an insertion
    func isInsertion() -> Bool {
        return self.range.length == 0
    }
}

open class AttributedParsingOperation: Operation {

    // MARK: - Types

    /// Asynchronous or synchronous callback to which the results are passed
    ///
    /// The sender is passed in so it can be used to check if the operation was
    /// cancelled after the call.
    public typealias OperationCallback = ([(range: NSRange, attributes: Attributes?)], AttributedParsingOperation) -> Void

    // MARK: - Properties

    private let parser: AttributedParser
    private let operationCallback: OperationCallback
    private var parsedRange: NSRange?

    // MARK: - Initializers

    /// Initializer for the first instance in the NSOperationQueue
    ///
    /// Can also be used if no incremental parsing is desired
    public init(string: String, language: Language, theme: Theme, callback: @escaping OperationCallback) {
        parser = AttributedParser(language: language, theme: theme)
        parser.toParse = ScopedString(string: string)
        operationCallback = callback
        super.init()
    }

    /// Initializer for operations that allow incremental parsing
    ///
    /// The given change has to match the change in the string between the two
    /// operations. Otherwise the entire string will be reparsed. If newCallback
    /// is nil the callback from the previous operation will be used.
    ///
    /// - parameter string:             The new String to parse.
    /// - parameter previousOperation:  The preceding operation in the queue.
    /// - parameter insertion:          True if the change was an insertion.
    /// - parameter range:              Either the range in the old string that
    ///                                 was deleted or the range in the new
    ///                                 string that was added.
    /// - parameter callback:           The callback to call with results.
    public init(string: String, previousOperation: AttributedParsingOperation, changeIsInsertion insertion: Bool, changedRange range: NSRange, newCallback callback: OperationCallback? = nil) {
        parser = previousOperation.parser
        operationCallback = callback ?? previousOperation.operationCallback

        super.init()

        let diff: Diff
        if insertion {
            diff = Diff(change: (string as NSString).substring(with: range), range: NSRange(location: range.location, length: 0))
        } else {
            diff = Diff(change: "", range: range)
        }

        if diff.representsChanges(from: parser.toParse.string, to: string) {
            self.parsedRange = AttributedParsingOperation.outdatedRange(in: string as NSString, forChange: diff, updatingPreviousResult: &self.parser.toParse)
        } else {
            self.parser.toParse = ScopedString(string: string)
        }
    }

    // MARK: - NSOperation Implementation

    open override func main() {
        var resultsArray: [(range: NSRange, attributes: Attributes?)] = []
        let callback = { (_: String, range: NSRange, attributes: Attributes?) in
            if let attributes = attributes {
                resultsArray.append((range, attributes))
            }
        }

        parser.parse(in: self.parsedRange, match: callback)

        if !parser.aborted {
            operationCallback(resultsArray, self)
        }
    }

    open override func cancel() {
        parser.aborted = true
        super.cancel()
    }

    // MARK: - Change Processing

    // Implementation notes:
    // If change occurred in a block reparse the lines in which the change
    // happened and the range of the block from this point on. If the change
    // occurred in the global scope just reparse the lines that changed.

    /// Returns the range in the given string that should be re-parsed after the
    /// given change.
    ///
    /// This method returns a range that can be safely passed into parse so that
    /// only a part of the string has to be reparsed.
    /// In fact passing anything other than this range to parse might lead to
    /// uninteded results but is not prohibited.
    ///
    /// - parameter newString:  The string that will be parsed next.
    /// - parameter diff:       A diff representing the changes from
    ///                         previous.string to newString.
    /// - parameter previous:   The result of the previous parsing pass.
    ///
    /// - returns:  A range in newString that can be safely re-parsed. Or nil if
    ///             everything has to be reparsed.
    class func outdatedRange(in newString: NSString, forChange diff: Diff, updatingPreviousResult previous: inout ScopedString) -> NSRange? {
        let linesRange: NSRange
        let range: NSRange
        if diff.isInsertion() {
            range = diff.rangeInNewString()
            previous.insert(diff.change, atIndex: range.location)
            linesRange = newString.lineRange(for: range)
        } else {
            range = diff.range
            previous.deleteCharacters(in: range)
            linesRange = newString.lineRange(for: NSRange(location: range.location, length: 0))
        }

        let scopeAtIndex = previous.topmostScope(atIndex: NSMaxRange(linesRange) - 1)
        if scopeAtIndex == previous.baseScope {
            return linesRange
        } else {
            let endOfCurrentScope = NSMaxRange(scopeAtIndex.range)
            return NSUnionRange(linesRange, NSRange(location: range.location, length: endOfCurrentScope - range.location))
        }
    }
}
