//
//  String+BackReference.swift
//  SyntaxKit
//
//  Created by Rachel on 2021/2/20.
//  Copyright © 2021 Sam Soffes. All rights reserved.
//

import Foundation

internal extension String {
    var hasBackReferencePlaceholder: Bool {
        var escape = false
        let buf = cString(using: .utf8)!.dropLast()
        for ch in buf {
            if escape && (ch >= 0x30 && ch <= 0x39) {
                return true
            }
            escape = !escape && ch == 0x5c
        }
        return false
    }

    // Converts into an escaped regex string
    func addingRegexEscapedCharacters() -> String {
        let special = "\\|([{}]).?*+^$".cString(using: .ascii)
        let buf = cString(using: .utf8)!.dropLast()
        var res = ""
        for ch in buf {
            if strchr(special, Int32(ch)) != nil {
                res += "\\"
            }
            res += String(format: "%c", ch)
        }
        return res
    }

    // Converts a back-referenced regex string to an ICU back-referenced regex string
    func convertToICUBackReferencedRegex() -> String {
        var escape = false
        let buf = cString(using: .utf8)!.dropLast()
        var res = ""
        for ch in buf {
            if escape && (ch >= 0x30 && ch <= 0x39) {
                res += String(format: "$%c", ch)
                escape = false
                continue
            }
            escape = !escape && ch == 0x5c
            if !escape {
                res += String(format: "%c", ch)
            }
        }
        return res
    }

    // Converts an ICU back-referenced regex string to a back-referenced regex string
    func convertToBackReferencedRegex() -> String {
        var escape = false
        var capture = false
        let buf = cString(using: .utf8)!.dropLast()
        var res = ""
        for ch in buf {
            if !escape && capture && (ch >= 0x30 && ch <= 0x39) {
                capture = false
                res += String(format: "\\%c", ch)
                continue
            }
            if escape {
                escape = false
                res += String(format: "%c", ch)
                continue
            }
            if !escape && ch == 0x24 {
                capture = true
                continue
            }
            if ch == 0x5c {
                escape = true
                continue
            }
            res += String(format: "%c", ch)
        }
        return res
    }

    // Expand a back-referenced regex string with original content and matches
    func removingBackReferencePlaceholders(content: String, matches: NSTextCheckingResult) -> String {
        var escape = false
        let buf = cString(using: .utf8)!.dropLast()
        var res = ""
        for ch in buf {
            if escape && (ch >= 0x30 && ch <= 0x39) {
                let i = Int(ch - 0x30)
                if i <= matches.numberOfRanges - 1 {
                    let refRange = matches.range(at: i)
                    if refRange.location != NSNotFound {
                        res += (content as NSString).substring(with: refRange).addingRegexEscapedCharacters()
                    }
                }
                escape = false
                continue
            }
            if escape {
                res += "\\"
            }
            escape = !escape && ch == 0x5c
            if !escape {
                res += String(format: "%c", ch)
            }
        }
        return res
    }
}
