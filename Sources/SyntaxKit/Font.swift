//
//  Font.swift
//  SyntaxKit
//
//  Created by Zheng Wu on 2021/3/6.
//  Copyright © 2021 Zheng Wu. All rights reserved.
//

#if os(macOS)
import AppKit.NSFont
public typealias FontType = NSFont

extension NSFont {
    func withTraits(traits: NSFontTraitMask) -> NSFont {
        return NSFontManager.shared.convert(
            self,
            toHaveTrait: traits
        )
    }

    func bold() -> NSFont {
        return withTraits(traits: .boldFontMask)
    }

    func italic() -> NSFont {
        return withTraits(traits: .italicFontMask)
    }

    func boldItalic() -> NSFont {
        return withTraits(traits: [.boldFontMask, .italicFontMask])
    }
}
#else
import UIKit.UIFont
public typealias FontType = UIFont

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0)  // size 0 means keep the size as it is
    }

    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }

    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }

    func boldItalic() -> UIFont {
        return withTraits(traits: [.traitBold, .traitItalic])
    }
}
#endif

public typealias Font = FontType

public enum FontStyle: String {
    case initial
    case plain
    case bold
    case italic
    case boldItalic
    case underline
    case strikethrough
}
