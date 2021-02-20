//
//  Color.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 4/28/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

#if os(macOS)
    import AppKit.NSColor
    public typealias ColorType = NSColor

    extension NSColor {
        convenience init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
            self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
        }
    }
#else
    import UIKit.UIColor
    public typealias ColorType = UIColor

    extension Color {
        var redComponent: CGFloat {
            var value: CGFloat = 0.0
            getRed(&value, green: nil, blue: nil, alpha: nil)
            return value
        }

        var greenComponent: CGFloat {
            var value: CGFloat = 0.0
            getRed(nil, green: &value, blue: nil, alpha: nil)
            return value
        }

        var blueComponent: CGFloat {
            var value: CGFloat = 0.0
            getRed(nil, green: nil, blue: &value, alpha: nil)
            return value
        }

        var alphaComponent: CGFloat {
            var value: CGFloat = 0.0
            getRed(nil, green: nil, blue: nil, alpha: &value)
            return value
        }
    }
#endif

public typealias Color = ColorType

extension Color {
    convenience init?(hex representation: String) {
        var hex = representation as NSString

        // Remove `#` and `0x`
        if hex.hasPrefix("#") {
            hex = hex.substring(from: 1) as NSString
        } else if hex.hasPrefix("0x") {
            hex = hex.substring(from: 2) as NSString
        }

        // Invalid if not 3, 6, or 8 characters
        let length = hex.length
        if length != 3 && length != 6 && length != 8 {
            return nil
        }

        // Make the string 8 characters long for easier parsing
        if length == 3 {
            let r = hex.substring(with: NSRange(location: 0, length: 1))
            let g = hex.substring(with: NSRange(location: 1, length: 1))
            let b = hex.substring(with: NSRange(location: 2, length: 1))
            hex = "\(r)\(r)\(g)\(g)\(b)\(b)ff" as NSString
        } else if length == 6 {
            hex = "\(hex)ff" as NSString
        }

        // Convert 2 character strings to CGFloats
        func hexValue(_ string: String) -> CGFloat {
            let value = Double(strtoul(string, nil, 16))
            return CGFloat(value / 255.0)
        }

        let red = hexValue(hex.substring(with: NSRange(location: 0, length: 2)))
        let green = hexValue(hex.substring(with: NSRange(location: 2, length: 2)))
        let blue = hexValue(hex.substring(with: NSRange(location: 4, length: 2)))
        let alpha = hexValue(hex.substring(with: NSRange(location: 6, length: 2)))

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
