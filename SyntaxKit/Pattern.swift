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
internal class Pattern: NSObject {

    // MARK: - Properties

    var name: String? { return _name }
    var match: RegularExpression? { return _match }
    var captures: CaptureCollection? { return _captures }
    var begin: RegularExpression? { return _begin }
    var beginCaptures: CaptureCollection? { return _beginCaptures }
    var end: RegularExpression? { return _end }
    var endCaptures: CaptureCollection? { return _endCaptures }
    var applyEndPatternLast: Bool { return _applyEndPatternLast }
    var parent: Pattern? { return _parent }
    var subpatterns: [Pattern] = []

    // swiftlint:disable strict_fileprivate
    fileprivate var _name: String?
    fileprivate var _match: RegularExpression?
    fileprivate var _captures: CaptureCollection?
    fileprivate var _begin: RegularExpression?
    fileprivate var _beginCaptures: CaptureCollection?
    fileprivate var _end: RegularExpression?
    fileprivate var _endCaptures: CaptureCollection?
    fileprivate var _applyEndPatternLast: Bool = false
    fileprivate weak var _parent: Pattern?
    // swiftlint:enable strict_fileprivate

    // MARK: - Initializers

    init?(dictionary: [AnyHashable: Any], parent: Pattern?, with repository: Repository?, with manager: ReferenceManager) {
        super.init()
        _parent = parent
        _name = dictionary["name"] as? String

        if let matchExpr = dictionary["match"] as? String {
            _match = try? RegularExpression(pattern: matchExpr, options: [.anchorsMatchLines])
        }

        if let beginExpr = dictionary["begin"] as? String {
            _begin = try? RegularExpression(pattern: beginExpr, options: [.anchorsMatchLines])
        }

        if let endExpr = dictionary["end"] as? String {
            _end = try? RegularExpression(pattern: endExpr, options: [.anchorsMatchLines])
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

        if dictionary["match"] as? String != nil && self.match == nil ||
            dictionary["begin"] as? String != nil && (self.begin == nil || self.end == nil) ||
            self.match == nil && self.begin == nil && self.end == nil && ((dictionary["patterns"] as? [[AnyHashable: Any]])?.isEmpty ?? true) {
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

internal class Include: Pattern {

    // MARK: - Properties

    enum ReferenceType {
        case toRepository (repositoryRef: String)
        case toSelf
        case toBase
        case toForeign (languageRef: String)
        case toForeignRepository (repositoryRef: String, languageRef: String)
        case resolved
    }

    private var type: ReferenceType
    private var associatedRepository: Repository?

    var languageRef: String? {
        switch type {
        case let .toForeignRepository(_, languageRef):
            return languageRef
        case let .toForeign(languageRef):
            return languageRef
        default:
            return nil
        }
    }

    // MARK: - Initializers

    init(reference: String, in repository: Repository? = nil, parent: Pattern?, manager: BundleManager /* not used */) {
        self.associatedRepository = repository
        if reference.hasPrefix("#") {
            self.type = .toRepository(repositoryRef: String(reference[reference.index(after: reference.startIndex)...]))
        } else if reference == "$self" {
            self.type = .toSelf
        } else  if reference == "$base" {
            self.type = .toBase
        } else if reference.contains("#") {
            if let hashRange = reference.range(of: "#") {
                let languagePart = String(reference[..<hashRange.lowerBound])
                self.type = .toForeignRepository(repositoryRef: String(reference[hashRange.upperBound...]), languageRef: languagePart)
            } else {
                fatalError()
            }
        } else {
            self.type = .toForeign(languageRef: reference)
        }
        super.init()
        _parent = parent
    }

    init(include: Include, parent: Pattern?) {
        self.type = include.type
        self.associatedRepository = include.associatedRepository
        super.init(pattern: include, parent: parent)
    }

    // MARK: - Reference Resolution

    func resolveInternalReference(with repository: Repository, in language: Language) {
        let pattern: Pattern?
        switch type {
        case let .toRepository(repositoryRef):
            pattern = (associatedRepository ?? repository)[repositoryRef]
        case .toSelf:
            pattern = language.pattern
        default:
            return
        }

        if let pat = pattern {
            self.replace(with: pat)
        }

        type = .resolved
    }

    func resolveExternalReference(from thisLanguage: Language /* not used */, in languages: [String: Language], baseName: String?) {
        let pattern: Pattern?
        switch type {
        case .toBase:
            if let base = baseName {
                pattern = languages[base]?.pattern
            } else {
                fatalError()
            }
        case let .toForeignRepository(repositoryRef, languageRef):
            pattern = languages[languageRef]?.repository[repositoryRef]
        case let .toForeign(languageRef):
            pattern = languages[languageRef]?.pattern
        default:
            return
        }

        if let pat = pattern {
            self.replace(with: pat)
        }
        
        type = .resolved
    }

    // MARK: - Private

    private func replace(with pattern: Pattern) {
        _name = pattern.name
        _match = pattern.match
        _captures = pattern.captures
        _begin = pattern.begin
        _beginCaptures = pattern.beginCaptures
        _end = pattern.end
        _endCaptures = pattern.endCaptures
        _applyEndPatternLast = pattern.applyEndPatternLast
        self.subpatterns = pattern.subpatterns
    }
}
