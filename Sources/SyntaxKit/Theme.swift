//
//  Theme.swift
//  SyntaxKit
//
//  Represents a TextMate theme file (.tmTheme). Currently only supports the
//  foreground text color attribute on a local scope.
//
//  Created by Sam Soffes on 10/11/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

public struct Theme {
    
    // MARK: - Public Types
    
    public typealias FontCallback = (_ fontName: String, _ fontSize: CGFloat, _ fontStyle: FontStyle) -> (Font?)
    
    // MARK: - Private Defaults
    
    private var fontName: String = Theme.defaultFontName
    private var fontSize: CGFloat = Theme.defaultFontSize
    private var fontCallback: FontCallback?
    
    // MARK: - Properties

    public let uuid: UUID
    public let name: String
    public let semanticClass: String?
    public let attributes: [String: Attributes]

    public let gutterSettings: Attributes?
    public var globalSettings: Attributes? { attributes[Theme.globalScope] }
    
    // MARK: - Global Convenience
    
    public var font: Font {
        return (globalSettings?[.font] as? Font) ?? Theme.defaultFontWithStyle(.initial)
    }
    
    public var foregroundColor: Color {
        return (globalSettings?[.foregroundColor] as? Color) ?? Theme.defaultForegroundColor
    }

    public var backgroundColor: Color {
        return (globalSettings?[.backgroundColor] as? Color) ?? Theme.defaultBackgroundColor
    }
    
    public var caretColor: Color? {
        return globalSettings?[.caret] as? Color
    }
    
    public var selectionColor: Color? {
        return globalSettings?[.selection] as? Color
    }
    
    public var invisiblesColor: Color? {
        return globalSettings?[.invisibles] as? Color
    }
    
    public var lineHighlightColor: Color? {
        return globalSettings?[.lineHighlight] as? Color
    }
    
    // MARK: - Static Convenience
    private static func defaultFontWithStyle(_ style: FontStyle) -> Font {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            switch style {
            case .bold:
                return Font.monospacedSystemFont(ofSize: defaultFontSize, weight: .bold)
            case .italic:
                return Font.monospacedSystemFont(ofSize: defaultFontSize, weight: .regular).italic()
            case .boldItalic:
                return Font.monospacedSystemFont(ofSize: defaultFontSize, weight: .bold).italic()
            default:
                return Font.monospacedSystemFont(ofSize: defaultFontSize, weight: .regular)
            }
        } else {
            // Fallback on earlier versions
            #if os(macOS)
            switch style {
            case .bold:
                return Font.userFixedPitchFont(ofSize: defaultFontSize)!.bold()
            case .italic:
                return Font.userFixedPitchFont(ofSize: defaultFontSize)!.italic()
            case .boldItalic:
                return Font.userFixedPitchFont(ofSize: defaultFontSize)!.boldItalic()
            default:
                return Font.userFixedPitchFont(ofSize: defaultFontSize)!
            }
            #else
            switch style {
            case .bold:
                return Font(name: "Menlo-Bold", size: defaultFontSize)!
            case .italic:
                return Font(name: "Menlo-Italic", size: defaultFontSize)!
            case .boldItalic:
                return Font(name: "Menlo-BoldItalic", size: defaultFontSize)!
            default:
                return Font(name: "Menlo-Regular", size: defaultFontSize)!
            }
            #endif
        }
    }
    private static var defaultFontName  : String   = defaultFontWithStyle(.initial).fontName
    private static var defaultFontSize  : CGFloat  = 12.0
    private static var defaultBackgroundColor      = Color.white
    private static var defaultForegroundColor      = Color.black
    
    private static let globalScope: String = "GLOBAL"

    // MARK: - Initializers

    init?(dictionary: [String: Any], fontCallback: FontCallback? = nil) {
        guard let uuidString = dictionary["uuid"] as? String,
            let uuid = UUID(uuidString: uuidString),
            let name = dictionary["name"] as? String,
            let rawSettings = dictionary["settings"] as? [[String: AnyObject]]
            else { return nil }

        self.uuid = uuid
        self.name = name
        
        if let semanticClass = dictionary["semanticClass"] as? String {
            self.semanticClass = semanticClass
        } else {
            self.semanticClass = nil
        }
        
        if let rawGutterSettings = dictionary["gutterSettings"] as? [String: AnyObject] {
            var gutterSettings = Attributes()
            for rawGutter in rawGutterSettings {
                gutterSettings[NSAttributedString.Key(rawValue: rawGutter.key)] = rawGutter.value
            }
            self.gutterSettings = gutterSettings
        } else {
            self.gutterSettings = nil
        }

        var attributes = [String: Attributes]()
        for raw in rawSettings {
            guard var setting = raw["settings"] as? [NSAttributedString.Key: Any] else { continue }

            if let value = setting.removeValue(forKey: .foreground) as? String {
                setting[NSAttributedString.Key.foregroundColor] = Color(hex: value)
            }

            if let value = setting.removeValue(forKey: .background) as? String {
                setting[NSAttributedString.Key.backgroundColor] = Color(hex: value)
            }
            
            if let value = setting.removeValue(forKey: .fontStyle) as? String, let fontStyle = FontStyle(rawValue: value) {
                switch fontStyle {
                case .initial, .plain, .bold, .italic, .boldItalic:
                    setting[NSAttributedString.Key.font] = fontCallback?(self.fontName, self.fontSize, fontStyle) ?? Theme.defaultFontWithStyle(fontStyle)
                case .underline:      // plain + underline
                    setting[NSAttributedString.Key.font] = fontCallback?(self.fontName, self.fontSize, .plain) ?? Theme.defaultFontWithStyle(.plain)
                    setting[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue
                case .strikethrough:  // plain + strikethrough
                    setting[NSAttributedString.Key.font] = fontCallback?(self.fontName, self.fontSize, .plain) ?? Theme.defaultFontWithStyle(.plain)
                    setting[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                }
            } else {
                setting[NSAttributedString.Key.font] = fontCallback?(self.fontName, self.fontSize, .plain) ?? Theme.defaultFontWithStyle(.plain)
            }

            if let patternIdentifiers = raw["scope"] as? String {
                for patternIdentifier in patternIdentifiers.components(separatedBy: ",") {
                    let key = patternIdentifier.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    attributes[key] = setting
                }
            } else if !setting.isEmpty {
                
                if let fontCallback = fontCallback {
                    let fontName = (setting.removeValue(forKey: .fontName) as? String) ?? Theme.defaultFontName
                    let fontSize = (setting.removeValue(forKey: .fontSize) as? CGFloat) ?? Theme.defaultFontSize
                    if let font = fontCallback(fontName, fontSize, .initial) {
                        setting[NSAttributedString.Key.font] = font
                        self.fontName = font.fontName
                        self.fontSize = font.pointSize
                    }
                } else {
                    setting[NSAttributedString.Key.font] = Theme.defaultFontWithStyle(.initial)
                }
                
                attributes[Theme.globalScope] = setting
            }
        }
        
        self.attributes = attributes
        self.fontCallback = fontCallback
    }
}
