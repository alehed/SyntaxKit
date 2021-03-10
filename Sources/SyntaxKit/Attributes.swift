//
//  Attributes.swift
//  
//
//  Created by Zheng Wu on 2021/3/10.
//  Copyright © 2021 Zheng Wu. All rights reserved.
//

import Foundation

public typealias Attributes = [NSAttributedString.Key: Any]

public extension NSAttributedString.Key {
    // Shared
    static let foreground            = NSAttributedString.Key("foreground")
    static let background            = NSAttributedString.Key("background")

    // Text Only
    static let fontName              = NSAttributedString.Key("fontName")
    static let fontSize              = NSAttributedString.Key("fontSize")
    static let fontStyle             = NSAttributedString.Key("fontStyle")
    static let caret                 = NSAttributedString.Key("caret")
    static let selection             = NSAttributedString.Key("selection")
    static let invisibles            = NSAttributedString.Key("invisibles")
    static let lineHighlight         = NSAttributedString.Key("lineHighlight")

    // Gutter Only
    static let divider               = NSAttributedString.Key("divider")
    static let selectionBorder       = NSAttributedString.Key("selectionBorder")
    static let icons                 = NSAttributedString.Key("icons")
    static let iconsHover            = NSAttributedString.Key("iconsHover")
    static let iconsPressed          = NSAttributedString.Key("iconsPressed")
    static let selectionForeground   = NSAttributedString.Key("selectionForeground")
    static let selectionBackground   = NSAttributedString.Key("selectionBackground")
    static let selectionIcons        = NSAttributedString.Key("selectionIcons")
    static let selectionIconsHover   = NSAttributedString.Key("selectionIconsHover")
    static let selectionIconsPressed = NSAttributedString.Key("selectionIconsPressed")
}
