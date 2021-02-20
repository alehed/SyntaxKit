//
//  Patterns.swift
//  SyntaxKit
//
//  A utility class to facilitate the creation of pattern arrays.
//  It works it the following fashion: First all the pattern arrays should be
//  created with patterns:inRepository:caller:. Then
//  resolveReferencesWithRepository:inLanguage: has to be called to resolve all
//  the references in the passed out patterns. So first lots of calls to
//  patterns and then one call to resolveReferences to validate the
//  patterns by resolving all references.
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

internal class ReferenceManager {

    // MARK: - Properties

    private var includes: [Include] = []
    private weak var bundleManager: BundleManager?

    var includedLanguageRefs: [String] {
        return includes.compactMap { $0.languageRef }
    }

    // MARK: - Init

    init(bundleManager: BundleManager) {
        self.bundleManager = bundleManager
    }

    // MARK: - Pattern Creation and Resolution

    func patterns(for patterns: [[AnyHashable: Any]], in repository: Repository?, caller: Pattern?) -> [Pattern] {
        guard let manager = bundleManager else {
            fatalError("bundleManager not set")
        }
        var results: [Pattern] = []
        for rawPattern in patterns {
            if let include = rawPattern["include"] as? String {
                let reference = Include(reference: include, in: repository, parent: caller, manager: manager)
                self.includes.append(reference)
                results.append(reference)
            } else if let pattern = Pattern(dictionary: rawPattern, parent: caller, with: repository, with: self) {
                results.append(pattern)
            }
        }
        return results
    }

    func resolveInternalReferences(with repository: Repository, in language: Language) {
        for include in includes {
            include.resolveInternalReference(with: repository, in: language)
        }
    }

    class func resolveExternalReferences(between languages: [Language], basename: String) {
        var otherLanguages: [String: Language] = [:]
        for language in languages {
            otherLanguages[language.scopeName] = language
        }
        for language in languages {
            let includes = language.referenceManager.includes
            for include in includes {
                include.resolveExternalReference(from: language, in: otherLanguages, baseName: basename)
            }
        }
    }
}
