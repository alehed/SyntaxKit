//
//  AttributedParser.swift
//  SyntaxKit
//
//  A subclass of Parser that knows about themes. Using the theme it maps
//  between recognized TextMate scope descriptions and NSAttributedString
//  attributes.
//
//  Created by Sam Soffes on 9/24/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

open class AttributedParser: Parser {

    // MARK: - Types

    public typealias AttributedCallback = (_ scope: String, _ range: NSRange, _ attributes: Attributes?) -> Void

    // MARK: - Properties

    public let theme: Theme

    // MARK: - Initializers

    public required init(language: Language, theme: Theme) {
        self.theme = theme
        super.init(language: language)
    }

    // MARK: - Parsing

    open func parse(_ string: String, match callback: AttributedCallback) {
        parse(string) { scope, range in
            callback(scope, range, self.attributes(forScope: scope))
        }
    }

    func parse(in range: NSRange?, match callback: AttributedCallback) {
        parse(in: range) { scope, range in
            callback(scope, range, self.attributes(forScope: scope))
        }
    }

    open func attributedString(for string: String, base: Attributes? = nil) -> NSAttributedString {
        let output = NSMutableAttributedString(string: string, attributes: base)
        output.beginEditing()
        parse(string) { _, range, attributes in
            if let attributes = attributes {
                output.addAttributes(attributes, range: range)
            }
        }
        output.endEditing()
        return output
    }

    // MARK: - Private

    private func attributes(forScope scope: String) -> Attributes? {
        let components = scope.components(separatedBy: ".")
        if components.isEmpty {
            return nil
        }

        var attributes = Attributes()
        for i in 0..<components.count {
            let key = components[0...i].joined(separator: ".")
            if let attrs = theme.attributes[key] {
                for (k, v) in attrs {
                    attributes[k] = v
                }
            }
        }

        if attributes.isEmpty {
            return nil
        }
        return attributes
    }
}
