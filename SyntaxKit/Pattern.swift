//
//  Pattern.swift
//  SyntaxKit
//
//  Represents a pattern from a TextMate grammar
//
//  The Include class represents a Pattern that is a reference to another part
//  in the same or another grammar. It is only usable as a pattern after it has
//  been resolved via the provided method (and has type .resolved).
//
//  A pattern may be one of three types:
//  *   A single pattern in match which should be matched
//  *   A begin and an end pattern containing an optional body of patterns
//      (subpatterns) which should be matched between the begin and the end
//  *   Only a body of patterns without the begin and end. Any pattern may be
//      matched successfully
//
//  Created by Sam Soffes on 9/18/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

@objc(SKPattern)
class Pattern: NSObject {

    // MARK: - Properties

    var name: String? { return _name }
    var match: NSRegularExpression? { return _match }
    var captures: CaptureCollection? { return _captures }
    var begin: NSRegularExpression? { return _begin }
    var beginCaptures: CaptureCollection? { return _beginCaptures }
    var end: NSRegularExpression? { return _end }
    var endCaptures: CaptureCollection? { return _endCaptures }
    var applyEndPatternLast: Bool { return _applyEndPatternLast }
    var parent: Pattern? { return _parent }
    var subpatterns: [Pattern] = []

    fileprivate var _name: String?
    fileprivate var _match: NSRegularExpression?
    fileprivate var _captures: CaptureCollection?
    fileprivate var _begin: NSRegularExpression?
    fileprivate var _beginCaptures: CaptureCollection?
    fileprivate var _end: NSRegularExpression?
    fileprivate var _endCaptures: CaptureCollection?
    fileprivate var _applyEndPatternLast = false
    fileprivate weak var _parent: Pattern?

    fileprivate let debug = true

    // MARK: - Initializers

    init?(dictionary: [AnyHashable: Any], parent: Pattern?, with repository: Repository?, with manager: ReferenceManager) {
        super.init()
        _parent = parent
        _name = dictionary["name"] as? String

        if let matchExpr = dictionary["match"] as? String {
            _match = try? NSRegularExpression.languagePattern(matchExpr, options: [.anchorsMatchLines])
            if debug && self.match == nil {
                print("Problem parsing match expression \(matchExpr)")
            }
        }

        if let beginExpr = dictionary["begin"] as? String {
            _begin = try? NSRegularExpression.languagePattern(beginExpr, options: [.anchorsMatchLines])
            if debug && self.begin == nil {
                print("Problem parsing begin expression \(beginExpr)")
            }
        }

        if let endExpr = dictionary["end"] as? String {
            _end = try? NSRegularExpression.languagePattern(endExpr, options: [.anchorsMatchLines])
            if debug && self.end == nil {
                print("Problem parsing end expression \(endExpr)")
            }
        }

        _applyEndPatternLast = dictionary["applyEndPatternLast"] as? Bool ?? false

        if let dictionary = dictionary["beginCaptures"] as? [AnyHashable: Any] {
            _beginCaptures = CaptureCollection(dictionary: dictionary)
        }

        if let dictionary = dictionary["captures"] as? [AnyHashable: Any] {
            if match != nil {
                _captures = CaptureCollection(dictionary: dictionary)
            } else if begin != nil && end != nil {
                _beginCaptures = CaptureCollection(dictionary: dictionary)
                _endCaptures = self.beginCaptures
            }
        }

        if let dictionary = dictionary["endCaptures"] as? [AnyHashable: Any] {
            _endCaptures = CaptureCollection(dictionary: dictionary)
        }

        if dictionary["match"] as? String != nil && self.match == nil {
            return nil
        } else if dictionary["begin"] as? String != nil && (self.begin == nil || self.end == nil) {
            return nil
        }

        if self.match == nil &&
            self.begin == nil &&
            self.end == nil &&
            (dictionary["patterns"] as? [[AnyHashable: Any]] == nil || (dictionary["patterns"] as? [[AnyHashable: Any]])!.isEmpty) {
                print("Attention: pattern not recognized: \(String(describing: self.name))")
                return nil
        }

        if let array = dictionary["patterns"] as? [[AnyHashable: Any]] {
            self.subpatterns = manager.patterns(for: array, in: repository, caller: self)
        }
    }

    init(pattern: Pattern, parent: Pattern?) {
        super.init()
        _name = pattern.name
        _match = pattern.match
        _captures = pattern.captures
        _begin = pattern.begin
        _beginCaptures = pattern.beginCaptures
        _end = pattern.end
        _endCaptures = pattern.endCaptures
        _parent = parent
        self.subpatterns = []
    }

    /// For most cases does not create a usable pattern.
    override init() {
        super.init()
    }
}

enum ReferenceType {
    case toRepository
    case toSelf
    case toBase
    case toForeign
    case toForeignRepository
    case resolved
}

class Include: Pattern {

    // MARK: - Properties

    var type: ReferenceType { return _type }

    fileprivate var _type: ReferenceType
    fileprivate let repositoryRef: String?
    fileprivate let languageRef: String?
    fileprivate var associatedRepository: Repository?

    // MARK: - Initializers

    init(reference: String, in repository: Repository? = nil, parent: Pattern?, manager: BundleManager) {
        self.associatedRepository = repository
        if reference.hasPrefix("#") {
            self._type = .toRepository
            self.repositoryRef = reference.substring(from: reference.characters.index(after: reference.startIndex))
            self.languageRef = nil
        } else if reference == "$self" {
            self._type = .toSelf
            self.repositoryRef = nil
            self.languageRef = nil
        } else  if reference == "$base" {
            self._type = .toBase
            self.repositoryRef = nil
            self.languageRef = nil
        } else if reference.contains("#") {
            self._type = .toForeignRepository
            self.repositoryRef = reference.substring(from: reference.range(of: "#")!.upperBound)
            self.languageRef = reference.substring(to: reference.range(of: "#")!.lowerBound)
            _ = manager.loadRawLanguage(withIdentifier: languageRef!)
        } else {
            self._type = .toForeign
            self.repositoryRef = nil
            self.languageRef = reference
            _ = manager.loadRawLanguage(withIdentifier: languageRef!)
        }
        super.init()
        _parent = parent
    }

    init(include: Include, parent: Pattern?) {
        self._type = include.type
        self.repositoryRef = include.repositoryRef
        self.languageRef = include.languageRef
        self.associatedRepository = include.associatedRepository
        super.init(pattern: include, parent: parent)
    }

    // MARK: - Reference Resolution

    func resolveInternalReference(with repository: Repository, in language: Language) {
        let pattern: Pattern?
        if type == .toRepository {
            pattern = (associatedRepository ?? repository)[repositoryRef!]
        } else if type == .toSelf {
            pattern = language.pattern
        } else {
            return
        }

        if pattern != nil {
            self.replace(with: pattern!)
        }
        _type = .resolved
    }

    func resolveExternalReference(from thisLanguage: Language, in languages: [String: Language], baseName: String?) {
        let pattern: Pattern?
        if type == .toBase {
            pattern = languages[baseName!]!.pattern
        } else if type == .toForeignRepository {
            pattern = languages[languageRef!]?.repository[repositoryRef!]
        } else if type == .toForeign {
            pattern = languages[languageRef!]?.pattern
        } else {
            return
        }

        if pattern != nil {
            self.replace(with: pattern!)
        }
        _type = .resolved
    }

    // MARK: - Private

    fileprivate func replace(with pattern: Pattern) {
        _name = pattern.name
        _match = pattern.match
        _captures = pattern.captures
        _begin = pattern.begin
        _beginCaptures = pattern.beginCaptures
        _end = pattern.end
        _endCaptures = pattern.endCaptures
        self.subpatterns = pattern.subpatterns
    }
}

fileprivate extension NSRegularExpression {
    static func languagePattern(_ pattern: String, options: NSRegularExpression.Options) throws -> NSRegularExpression {
        var realPattern = pattern
        var realOptions = options
        if let multilineOption = pattern.range(of:"(?x)"),
            multilineOption.lowerBound == pattern.startIndex
        {
            realPattern = String(pattern.substring(from: multilineOption.upperBound))
            realOptions.insert(.allowCommentsAndWhitespace)
        }
        
        return try NSRegularExpression(pattern: realPattern, options: realOptions)
    }
}

