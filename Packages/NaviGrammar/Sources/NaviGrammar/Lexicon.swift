//
//  Lexicon.swift
//  NaviGrammar
//

import Foundation

/// A word in the lexicon.
public struct LexiconEntry: Hashable, Sendable, Identifiable {

    /// The LearnNavi dictionary's id for the entry.
    public let id: Int

    /// The headword as the dictionary writes it, such as `Kelutral`, `mì+` or
    /// `tìng mikyun`.
    public let headword: String

    /// The headword as the analyser compares it: normalised, without the + that
    /// marks a leniting boundary.
    public let form: String

    public let partsOfSpeech: [PartOfSpeech]

    /// Where the infixes go, for verbs.
    public let infixTemplate: InfixTemplate?

    /// The genitive, where it is irregular: from the dictionary's definition
    /// (soaia → soaiä) or Dr. Frommer's usage (po → peyä).
    public let irregularGenitive: String?

    /// Whether the word is a loanword that ends in an added -ì, which case endings
    /// replace (Kelnì → Kelnit).
    public let isLoanwordEndingInI: Bool

    /// The English definition.
    public let gloss: String

    /// Whether the word lenites the word that follows it, as the adposition mì+ does.
    public var lenitesFollowingWord: Bool {
        headword.hasSuffix("+")
    }

    /// The inflectional classes of the entry's parts of speech. An entry with an
    /// infix template inflects as a verb whatever its part of speech, as the phrase
    /// eltur tìtxen si "be interesting" does.
    ///
    /// The interrogatives meaning "who" and "what (thing)" also inflect as pronouns:
    /// appendix F has pesu + hu, pesuhu "with whom".
    public var wordClasses: [WordClass] {
        var classes = partsOfSpeech.map(\.wordClass)
        if infixTemplate != nil && !classes.contains(.verb) {
            classes.append(.verb)
        }
        if partsOfSpeech.contains(PartOfSpeech(rawValue: "inter.")) && (gloss == "who" || gloss == "what (thing)") {
            classes.append(.pronoun)
        }
        return classes
    }

    /// Whether the headword is more than one word, as tìng mikyun "listen" is.
    public var isMultiword: Bool {
        form.contains(" ")
    }

    /// Whether the entry is itself one case of a pronoun, as the dictionary marks
    /// tsaw "that (as intransitive subject)" and tsal "(as transitive subject)".
    /// Such a pronoun's other cases are separate entries, so it takes no ending:
    /// adding one would make a word such as tsawìl that nobody uses.
    public var isCaseFormOfPronoun: Bool {
        partsOfSpeech.contains(.pronoun) && gloss.contains("(as ")
    }
}

public enum LexiconError: Error, Equatable, CustomStringConvertible {
    case missingResource
    case missingHeader
    case malformedLine(number: Int, reason: String)

    public var description: String {
        switch self {
        case .missingResource: "The lexicon resource is missing from the bundle."
        case .missingHeader: "The lexicon has no column header."
        case .malformedLine(let number, let reason): "Lexicon line \(number): \(reason)."
        }
    }
}

/// The words the grammar engine knows, generated from the LearnNavi dictionary data
/// by `Scripts/build_grammar_lexicon.py`.
public struct Lexicon: Sendable {

    public let entries: [LexiconEntry]

    /// The header's `# key<TAB>value` lines: `source`, `retrieved`, `sha256`,
    /// `entries` and `credit`.
    public let metadata: [String: String]

    private let indicesByForm: [String: [Int]]
    private let indicesByID: [Int: Int]

    private static let columns = ["id", "navi", "pos", "infixes", "grammar", "en"]

    /// Parses lexicon text. A line that does not fit the format throws, rather than
    /// being skipped, so a damaged resource fails loudly in tests.
    public init(tsv: String) throws {
        var metadata: [String: String] = [:]
        var entries: [LexiconEntry] = []
        var hasHeader = false

        let lines = tsv.split(omittingEmptySubsequences: false) { $0 == "\n" || $0 == "\r\n" }
        for (offset, rawLine) in lines.enumerated() {
            let line = String(rawLine).trimmingCharacters(in: CharacterSet(charactersIn: "\r\u{FEFF}"))
            let number = offset + 1
            if line.isEmpty {
                continue
            }
            if line.hasPrefix("#") {
                let parts = line.dropFirst().trimmingCharacters(in: .whitespaces)
                    .split(separator: "\t", maxSplits: 1)
                if parts.count == 2 {
                    metadata[String(parts[0])] = String(parts[1])
                }
                continue
            }

            let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            if !hasHeader {
                guard fields == Self.columns else {
                    throw LexiconError.missingHeader
                }
                hasHeader = true
                continue
            }
            entries.append(try Self.entry(from: fields, line: number))
        }

        guard hasHeader else {
            throw LexiconError.missingHeader
        }
        self.init(entries: entries, metadata: metadata)
    }

    init(entries: [LexiconEntry], metadata: [String: String] = [:]) {
        self.entries = entries
        self.metadata = metadata
        var byForm: [String: [Int]] = [:]
        var byID: [Int: Int] = [:]
        for (index, entry) in entries.enumerated() {
            byForm[entry.form, default: []].append(index)
            byID[entry.id] = index
        }
        indicesByForm = byForm
        indicesByID = byID
    }

    /// The lexicon bundled with the package.
    public static func bundled() throws -> Lexicon {
        guard let url = Bundle.module.url(forResource: "lexicon", withExtension: "tsv") else {
            throw LexiconError.missingResource
        }
        return try Lexicon(tsv: String(contentsOf: url, encoding: .utf8))
    }

    /// Entries whose normalised headword is `form`.
    public func entries(withForm form: String) -> [LexiconEntry] {
        indicesByForm[form, default: []].map { entries[$0] }
    }

    public func entry(id: Int) -> LexiconEntry? {
        indicesByID[id].map { entries[$0] }
    }

    // MARK: - Parsing

    private static func entry(from fields: [String], line: Int) throws -> LexiconEntry {
        guard fields.count == columns.count else {
            throw LexiconError.malformedLine(number: line, reason: "\(fields.count) columns instead of \(columns.count)")
        }
        guard let id = Int(fields[0]) else {
            throw LexiconError.malformedLine(number: line, reason: "the id \(fields[0].debugDescription) is not a number")
        }

        let headword = fields[1].precomposedStringWithCanonicalMapping
        let form = Orthography.normalize(headword.replacingOccurrences(of: "+", with: ""))
        guard !form.isEmpty else {
            throw LexiconError.malformedLine(number: line, reason: "the headword is empty")
        }

        let partsOfSpeech = fields[2]
            .split(separator: ",")
            .map { PartOfSpeech(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.rawValue.isEmpty }
        guard !partsOfSpeech.isEmpty else {
            throw LexiconError.malformedLine(number: line, reason: "no part of speech")
        }

        var template: InfixTemplate?
        if fields[3].contains("<") || fields[3].contains(">") {
            template = InfixTemplate(Orthography.normalize(fields[3]))
            guard let template else {
                throw LexiconError.malformedLine(number: line, reason: "the infix template is malformed")
            }
            guard template.bare == form else {
                throw LexiconError.malformedLine(number: line, reason: "the infix template does not spell the headword")
            }
        }
        // A template that marks no positions ('ulte in the current data) leaves a verb
        // that takes no infixes; the build script reports it.

        var irregularGenitive: String?
        var isLoanword = false
        for item in fields[4].split(separator: ";") {
            let pair = item.split(separator: "=", maxSplits: 1)
            if pair.count == 2, pair[0] == "genitive" {
                irregularGenitive = Orthography.normalize(String(pair[1]))
            } else if item == "loanword" {
                isLoanword = form.hasSuffix("ì")
            }
        }

        return LexiconEntry(
            id: id,
            headword: headword,
            form: form,
            partsOfSpeech: partsOfSpeech,
            infixTemplate: template,
            irregularGenitive: irregularGenitive,
            isLoanwordEndingInI: isLoanword,
            gloss: fields[5]
        )
    }
}
