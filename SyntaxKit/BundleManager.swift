//
//  BundleManager.swift
//  SyntaxKit
//
//  Used to get access to SyntaxKit representations of TextMate bundle files.
//  This class is used as a gateway for both internal and external use.
//  Alternatively a global instace can be used for convenience. It is
//  initialized with a callback that tells the bundle manager where to find the
//  files.
//
//  Created by Alexander Hedges on 15/02/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

open class BundleManager {

    public enum TextMateFileType {
        case language, theme
    }

    // MARK: - Types

    /// Given an identifier of a grammar file and the format returns a url to 
    /// the resource.
    ///
    /// - parameter identifier: The identifier of the file. Used to map it to
    ///                         the name of the file.
    /// - parameter kind:       The kind of file requested
    /// - returns:  A URL pointing to the resource, if found
    public typealias BundleLocationCallback = (_ identifier: String, _ kind: TextMateFileType) -> (URL?)

    // MARK: - Properties

    /// You probably want to leave the languageCaching property set to true.
    ///
    /// - note: Setting it to false will not invalidate or purge the cache. This
    ///         has to be done separately using clearLanguageCache.
    open var languageCaching: Bool = true

    /// You probably want to leave the themeCaching property set to true.
    ///
    /// - note: Setting it to false will not invalidate or purge the cache. This
    ///         has to be done separately using clearThemeCache.
    open var themeCaching: Bool = true

    public static var defaultManager: BundleManager?

    private var bundleCallback: BundleLocationCallback
    private var cachedLanguages: [String: Language] = [:]
    private var cachedThemes: [String: Theme] = [:]

    // MARK: - Initializers

    /// Used to initialize the default manager. Unless this is called the
    /// defaultManager property will be set to nil.
    ///
    /// - parameter callback:   The callback used to find the location of the
    ///                         textmate files.
    open class func initializeDefaultManager(with callback: @escaping BundleLocationCallback) {
        if let manager = defaultManager {
            manager.bundleCallback = callback
        } else {
            defaultManager = BundleManager(callback: callback)
        }
    }

    public init(callback: @escaping BundleLocationCallback) {
        self.bundleCallback = callback
    }

    // MARK: - Public

    open func language(withIdentifier identifier: String) -> Language? {
        if let language = self.cachedLanguages[identifier] {
            return language
        }

        guard let newLanguage = includeLanguage(withIdentifier: identifier) else {
            return nil
        }

        var languageSet = Set<Language>(arrayLiteral: newLanguage)
        var languageDependencies = [Language]()

        while let language = languageSet.popFirst() {
            languageDependencies.append(language)
            for childLanguageRef in language.referencedLanguageRefs {
                if languageDependencies.map({ $0.scopeName }).contains(childLanguageRef) {
                    continue
                }
                guard let childLanguage = includeLanguage(withIdentifier: childLanguageRef) else {
                    continue
                }
                languageSet.insert(childLanguage)
            }
        }

        // Now we finally got all helper languages
        newLanguage.validate(with: languageDependencies)

        if languageCaching {
            self.cachedLanguages[identifier] = newLanguage
        }

        return newLanguage
    }

    open func theme(withIdentifier identifier: String) -> Theme? {
        if let theme = cachedThemes[identifier] {
            return theme
        }

        guard let dictURL = self.bundleCallback(identifier, .theme),
            let plist = NSDictionary(contentsOf: dictURL) as? [String: Any],
            let newTheme = Theme(dictionary: plist) else {
                return nil
        }

        if themeCaching {
            self.cachedThemes[identifier] = newTheme
        }
        return newTheme
    }

    /// Use if low on memory.
    open func clearCaches() {
        self.cachedLanguages.removeAll()
        self.cachedThemes.removeAll()
    }

    // MARK: - Internal Interface

    /// - parameter identifier: The identifier of the requested language.
    /// - returns:  The Language with unresolved extenal references, if found
    private func includeLanguage(withIdentifier identifier: String) -> Language? {
        guard let dictURL = self.bundleCallback(identifier, .language),
              let plist = NSDictionary(contentsOf: dictURL) as? [String: Any],
              let newLanguage = Language(dictionary: plist, manager: self) else {
            return nil
        }
        return newLanguage
    }
}
