//
//  Analyser.swift
//  NaviGrammar
//

import Foundation

/// Takes Na'vi words apart: finds every lexicon entry and inflection that produce a
/// word, and ranks the readings.
///
/// The analyser proposes readings by removing affixes and undoing lenition, then
/// keeps a reading only if the `Generator` produces the word from it. It therefore
/// never accepts a form the rules do not produce, and a word no entry produces is
/// reported as unknown rather than guessed at.
public struct Analyser: Sendable {

    public let lexicon: Lexicon
    private let generator = Generator()

    /// One matcher per verb and per word of it that takes infixes, by the first
    /// character of the text before the infixes; verbs that begin with a vowel, where
    /// that text is empty, are under nil.
    private let verbMatchers: [Character?: [VerbMatcher]]
    /// Adpositions that attach as suffixes, by normalised form.
    private let adpositions: [String: LexiconEntry]
    private let irregularGenitives: [String: [LexiconEntry]]

    public init(lexicon: Lexicon) {
        self.lexicon = lexicon

        var matchers: [VerbMatcher] = []
        var adpositions: [String: LexiconEntry] = [:]
        var irregularGenitives: [String: [LexiconEntry]] = [:]
        for entry in lexicon.entries {
            if let template = entry.infixTemplate {
                matchers += template.slottedWordIndices.map { VerbMatcher(entry: entry, template: template, wordIndex: $0) }
            }
            // to "than" is a particle that, the dictionary notes, behaves like an adposition.
            if entry.wordClasses.contains(.adposition) || (entry.form == "to" && entry.gloss.contains("adp.")) {
                adpositions[entry.form] = adpositions[entry.form] ?? entry
            }
            if let genitive = entry.irregularGenitive {
                irregularGenitives[genitive, default: []].append(entry)
            }
        }
        verbMatchers = Dictionary(grouping: matchers) { $0.head.first }
        self.adpositions = adpositions
        self.irregularGenitives = irregularGenitives
    }

    /// An analyser for the bundled lexicon.
    public static func bundled() throws -> Analyser {
        Analyser(lexicon: try Lexicon.bundled())
    }

    /// Every reading of `word`, most likely first.
    ///
    /// - Parameter afterLenitingWord: whether the word follows one that lenites the
    ///   next word, such as the adposition mì+. Readings of the word's unlenited
    ///   forms are then included.
    public func analyse(_ word: String, afterLenitingWord: Bool = false) -> WordAnalysis {
        let prepared = Self.prepare(word)
        guard !prepared.isEmpty else {
            return WordAnalysis(word: word, normalized: prepared, analyses: [])
        }
        // A word in the Reef dialect's letters is read in the forest dialect's, which
        // the dictionary uses, and its readings say so.
        let normalized = Orthography.forestSpelling(prepared)
        let notes: Set<FormNote> = normalized == prepared ? [] : [.reefSpelling]

        var analyses = readings(of: normalized, surface: normalized, lenitedByContext: false, notes: notes)
        if afterLenitingWord && !normalized.contains(" ") {
            for unlenited in Orthography.unlenitedCandidates(normalized) where unlenited != normalized {
                analyses += readings(of: unlenited, surface: normalized, lenitedByContext: true, notes: notes)
            }
            // After a leniting adposition a lenited noun is singular; the plural needs
            // ay+: mì hilvan "in the river", mì ayhilvan "in the rivers"
            // (https://naviteri.org/2010/07/thoughts-on-ambiguity/).
            analyses.removeAll { $0.inflection.prefix == .shortPlural }
        }
        let (kept, folded) = ranked(analyses)
        return WordAnalysis(word: word, normalized: prepared, analyses: kept, folded: folded)
    }

    /// Normalises a word for analysis. Hyphens are dropped, since writers sometimes
    /// mark a suffix with one (t«awn»aron-a); runs of spaces become one.
    static func prepare(_ word: String) -> String {
        let hyphens: Set<Character> = ["-", "\u{2010}", "\u{2011}", "\u{2012}"]
        let normalized = Orthography.normalize(word.trimmingCharacters(in: .whitespacesAndNewlines))
        return normalized.filter { !hyphens.contains($0) }
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    // MARK: - Readings

    private struct Candidate {
        let entry: LexiconEntry
        let wordClass: WordClass
        let inflection: Inflection
    }

    /// Proposes readings of `word` and keeps those the generator confirms. `surface`
    /// is the word as written, which differs from `word` for a word lenited by the
    /// one before it.
    private func readings(of word: String, surface: String, lenitedByContext: Bool, notes extraNotes: Set<FormNote>) -> [Analysis] {
        var candidates: [Candidate] = []
        bareCandidates(word, into: &candidates)
        for match in verbMatches(word) {
            candidates.append(Candidate(entry: match.entry, wordClass: .verb, inflection: Inflection(infixes: match.infixes)))
        }
        if !word.contains(" ") {
            adjectivalCandidates(word, into: &candidates)
            adverbCandidates(word, into: &candidates)
            nominalCandidates(word, into: &candidates)
        }

        var seen: Set<String> = []
        var analyses: [Analysis] = []
        for candidate in candidates {
            let forms = generator.forms(of: candidate.entry, as: candidate.wordClass, candidate.inflection)
            guard let form = forms.first(where: { $0.text == word }) else {
                continue
            }
            var adposition: LexiconEntry?
            if case .adposition(let form) = candidate.inflection.ending {
                adposition = adpositions[form]
            }
            let analysis = Analysis(
                word: surface,
                entry: candidate.entry,
                wordClass: candidate.wordClass,
                inflection: candidate.inflection,
                notes: form.notes.union(extraNotes),
                isLenitedByPrecedingWord: lenitedByContext,
                adposition: adposition,
                cost: Self.cost(of: candidate.inflection, notes: form.notes, lenitedByContext: lenitedByContext)
            )
            if seen.insert(analysis.id).inserted {
                analyses.append(analysis)
            }
        }
        return analyses
    }

    private func bareCandidates(_ word: String, into candidates: inout [Candidate]) {
        for entry in lexicon.entries(withForm: word) {
            for wordClass in Self.unique(entry.wordClasses) {
                candidates.append(Candidate(entry: entry, wordClass: wordClass, inflection: .none))
            }
        }
    }

    /// Adjectives, participles and the adjectives derived from verbs and numbers,
    /// with the attributive a and the conjunction -sì.
    private func adjectivalCandidates(_ word: String, into candidates: inout [Candidate]) {
        for (conjunction, withoutConjunction) in Self.conjunctionSplits(word) {
            for (attributive, stem) in Self.attributiveSplits(withoutConjunction) {
                let inflection = Inflection(attributive: attributive, conjunction: conjunction)
                if attributive != nil || conjunction {
                    for entry in lexicon.entries(withForm: stem) {
                        for wordClass in Self.unique(entry.wordClasses) where wordClass == .adjective || wordClass == .number {
                            candidates.append(Candidate(entry: entry, wordClass: wordClass, inflection: inflection))
                        }
                    }
                }
                if attributive != nil {
                    for match in verbMatches(stem) where match.infixes.first?.isParticiple == true {
                        var participle = inflection
                        participle.infixes = match.infixes
                        candidates.append(Candidate(entry: match.entry, wordClass: .verb, inflection: participle))
                    }
                }
                // Derived adjectives, unless the dictionary lists the word itself and
                // it takes the same marking. A listed ordinal ('awve) is a number,
                // which takes no attributive a, so a'awve is read as a derived ordinal.
                let listed = lexicon.entries(withForm: stem).flatMap(\.wordClasses)
                guard !listed.contains(.adjective), !(listed.contains(.number) && attributive == nil && !conjunction) else {
                    continue
                }
                for (prefix, derivation) in [("ketsuk", Derivation.unable), ("tsuk", .able)] where stem.hasPrefix(prefix) {
                    for entry in lexicon.entries(withForm: String(stem.dropFirst(prefix.count))) where entry.wordClasses.contains(.verb) {
                        var derived = inflection
                        derived.derivation = derivation
                        candidates.append(Candidate(entry: entry, wordClass: .verb, inflection: derived))
                    }
                }
                if stem.hasSuffix("ve") {
                    for entry in lexicon.entries(withForm: String(stem.dropLast(2))) where entry.wordClasses.contains(.number) {
                        var ordinal = inflection
                        ordinal.derivation = .ordinal
                        candidates.append(Candidate(entry: entry, wordClass: .number, inflection: ordinal))
                    }
                }
            }
        }
    }

    /// nì- adverbs made from adjectives and nouns, unless the dictionary lists the
    /// adverb itself.
    private func adverbCandidates(_ word: String, into candidates: inout [Candidate]) {
        guard word.hasPrefix("nì"),
              !lexicon.entries(withForm: word).contains(where: { $0.wordClasses.contains(.adverb) }) else {
            return
        }
        for entry in lexicon.entries(withForm: String(word.dropFirst(2))) {
            for wordClass in Self.unique(entry.wordClasses) where wordClass == .adjective || wordClass == .noun {
                candidates.append(Candidate(entry: entry, wordClass: wordClass, inflection: Inflection(derivation: .adverb)))
            }
        }
    }

    /// Nouns and pronouns: undoes, from the outside in, the conjunction -sì, a case
    /// ending or adposition, a suffix such as -tsyìp, and a number or determiner
    /// prefix with any lenition it caused.
    private func nominalCandidates(_ word: String, into candidates: inout [Candidate]) {
        for (conjunction, afterConjunction) in Self.conjunctionSplits(word) {
            for (ending, afterEnding) in endingSplits(afterConjunction) {
                for (suffix, afterSuffix) in Self.suffixSplits(afterEnding) {
                    for (prefix, afterPrefix) in Self.prefixSplits(afterSuffix) {
                        let stems = prefix?.lenites == true ? Orthography.unlenitedCandidates(afterPrefix) : [afterPrefix]
                        for stem in stems where !(prefix == .shortPlural && stem == afterPrefix) {
                            let inflection = Inflection(prefix: prefix, suffix: suffix, ending: ending, conjunction: conjunction)
                            for entry in Self.stemsBeforeCase(stem, ending).flatMap(lexicon.entries(withForm:)) {
                                for wordClass in Self.unique(entry.wordClasses) where wordClass.isNominal {
                                    candidates.append(Candidate(entry: entry, wordClass: wordClass, inflection: inflection))
                                }
                            }
                            if ending == nil && suffix == nil {
                                var genitive = inflection
                                genitive.ending = .case(.genitive)
                                for entry in irregularGenitives[stem, default: []] {
                                    for wordClass in Self.unique(entry.wordClasses) where wordClass.isNominal {
                                        candidates.append(Candidate(entry: entry, wordClass: wordClass, inflection: genitive))
                                    }
                                }
                            }
                            derivedNounCandidates(stem, inflection, into: &candidates)
                        }
                    }
                }
            }
        }
    }

    /// The headwords a stem left by removing a case ending could belong to: the stem
    /// itself; without a final a, for the pronouns in -ng (oengaru); with an -ì, for
    /// loanwords (Kelnit); and with an a, for the genitive of nouns in -ia (soaiä).
    private static func stemsBeforeCase(_ stem: String, _ ending: NounEnding?) -> [String] {
        guard case .case = ending else {
            return [stem]
        }
        var stems = [stem, stem + "ì", stem + "a"]
        if stem.count > 1 && stem.hasSuffix("a") {
            stems.append(String(stem.dropLast()))
        }
        return stems
    }

    /// Nouns made from verbs, unless the dictionary lists the noun itself.
    private func derivedNounCandidates(_ stem: String, _ inflection: Inflection, into candidates: inout [Candidate]) {
        guard !lexicon.entries(withForm: stem).contains(where: { $0.wordClasses.contains(.noun) }) else {
            return
        }
        for (suffix, derivation) in [("yu", Derivation.agentNoun), ("tswo", .abilityNoun), ("tseng", .placeNoun)]
        where stem.count > suffix.count && stem.hasSuffix(suffix) {
            for entry in lexicon.entries(withForm: String(stem.dropLast(suffix.count))) where entry.wordClasses.contains(.verb) {
                var derived = inflection
                derived.derivation = derivation
                candidates.append(Candidate(entry: entry, wordClass: .verb, inflection: derived))
            }
        }
        if stem.count > 2 && stem.hasPrefix("tì") {
            for match in verbMatches(String(stem.dropFirst(2))) where match.infixes == VerbInfixes(first: .activeParticiple) {
                var gerund = inflection
                gerund.derivation = .gerund
                candidates.append(Candidate(entry: match.entry, wordClass: .verb, inflection: gerund))
            }
        }
    }

    // MARK: - Affix splits

    private static let caseSuffixes: [(suffix: String, nounCase: NounCase)] = [
        ("l", .agentive), ("ìl", .agentive),
        ("t", .patientive), ("ti", .patientive), ("it", .patientive),
        ("r", .dative), ("ru", .dative), ("ur", .dative),
        ("yä", .genitive), ("ä", .genitive), ("y", .genitive),
        ("ri", .topical), ("ìri", .topical),
        ("ya", .vocative),
    ]

    /// The word without each ending it might have, as (ending, rest) pairs.
    private func endingSplits(_ word: String) -> [(NounEnding?, String)] {
        var splits: [(NounEnding?, String)] = [(nil, word)]
        for (suffix, nounCase) in Self.caseSuffixes where word.count > suffix.count && word.hasSuffix(suffix) {
            splits.append((.case(nounCase), String(word.dropLast(suffix.count))))
        }
        // A pronoun's a is fronted to e before the genitive: nga → ngeyä, ngey.
        for fronted in ["eyä", "ey"] where word.count > fronted.count && word.hasSuffix(fronted) {
            splits.append((.case(.genitive), String(word.dropLast(fronted.count)) + "a"))
        }
        for (form, _) in adpositions where word.count > form.count && word.hasSuffix(form) {
            splits.append((.adposition(form), String(word.dropLast(form.count))))
        }
        return splits
    }

    private static func conjunctionSplits(_ word: String) -> [(Bool, String)] {
        var splits = [(false, word)]
        if word.count > 2 && word.hasSuffix("sì") {
            splits.append((true, String(word.dropLast(2))))
        }
        return splits
    }

    private static func suffixSplits(_ word: String) -> [(NounSuffix?, String)] {
        var splits: [(NounSuffix?, String)] = [(nil, word)]
        for suffix in NounSuffix.allCases where word.count > suffix.rawValue.count && word.hasSuffix(suffix.rawValue) {
            splits.append((suffix, String(word.dropLast(suffix.rawValue.count))))
        }
        return splits
    }

    private static func prefixSplits(_ word: String) -> [(NounPrefix?, String)] {
        var splits: [(NounPrefix?, String)] = [(nil, word), (.shortPlural, word)]
        for prefix in NounPrefix.allCases where prefix != .shortPlural {
            let form = prefix.rawValue
            guard word.count > form.count && word.hasPrefix(form) else {
                continue
            }
            let rest = String(word.dropFirst(form.count))
            splits.append((prefix, rest))
            // A vowel doubled across the boundary is written once (me+ 'eylan → meylan).
            if let last = form.last, Orthography.vowels.contains(last) {
                splits.append((prefix, String(last) + rest))
            }
        }
        return splits
    }

    private static func attributiveSplits(_ word: String) -> [(Attributive?, String)] {
        var splits: [(Attributive?, String)] = [(nil, word)]
        if word.count > 1 && word.hasPrefix("a") {
            splits.append((.before, String(word.dropFirst())))
        }
        if word.count > 1 && word.hasSuffix("a") {
            splits.append((.after, String(word.dropLast())))
        }
        return splits
    }

    // MARK: - Verbs

    /// The verbs whose templates, filled with some infixes, spell `word`. The
    /// generator confirms each match.
    private func verbMatches(_ word: String) -> [(entry: LexiconEntry, infixes: VerbInfixes)] {
        var matches: [(entry: LexiconEntry, infixes: VerbInfixes)] = []
        let matchers = verbMatchers[word.first, default: []] + verbMatchers[nil, default: []]
        for matcher in matchers {
            for infixes in matcher.infixes(in: word) {
                matches.append((matcher.entry, infixes))
            }
        }
        return matches
    }

    // MARK: - Ranking

    /// Roughly one per affix, so that the simplest reading comes first. Readings
    /// that rely on an optional or restricted form cost a little more.
    private static func cost(of inflection: Inflection, notes: Set<FormNote>, lenitedByContext: Bool) -> Double {
        var cost = 0.0
        // A derivation makes a different word, which is less likely than an
        // inflection of the same length.
        if inflection.derivation != nil { cost += 1.5 }
        if let infixes = inflection.infixes {
            cost += Double([infixes.preFirst != nil, infixes.first != nil, infixes.second != nil].filter { $0 }.count)
        }
        if let prefix = inflection.prefix { cost += prefix == .shortPlural ? 1.5 : 1 }
        if inflection.suffix != nil { cost += 1 }
        if inflection.ending != nil { cost += 1 }
        if inflection.attributive != nil { cost += 1 }
        if inflection.conjunction { cost += 1 }
        if notes.contains(.casualGenitive) { cost += 0.5 }
        if notes.contains(.raisedPejorative) { cost += 0.25 }
        if notes.contains(.collectiveVocative) { cost += 1.5 }
        if lenitedByContext { cost += 0.25 }
        return cost
    }

    /// Sorts readings, cheapest first, and removes two kinds of duplicate: the same
    /// reading reached through two of an entry's parts of speech, and a reading that
    /// builds, with a productive affix, a word the dictionary lists on its own
    /// ('ite + -tsyìp for 'itetsyìp "little daughter"). Readings with different
    /// meanings, such as 'ur "sight" and 'u + dative "to the thing", both stay.
    private func ranked(_ analyses: [Analysis]) -> (kept: [Analysis], folded: [Analysis]) {
        var seen: Set<String> = []
        let unique = analyses
            .sorted { ($0.cost, $0.entry.id, $0.id) < ($1.cost, $1.entry.id, $1.id) }
            .filter { seen.insert($0.id).inserted }
        var kept: [Analysis] = []
        var folded: [Analysis] = []
        for reading in unique {
            if unique.contains(where: { rebuildsListedWord(reading, $0) }) {
                folded.append(reading)
            } else {
                kept.append(reading)
            }
        }
        return (kept, folded)
    }

    /// Whether `reading` uses one affix to build `listed`'s headword and otherwise
    /// matches `listed`, so that the two describe the same word.
    private func rebuildsListedWord(_ reading: Analysis, _ listed: Analysis) -> Bool {
        guard listed.entry.id != reading.entry.id,
              listed.isLenitedByPrecedingWord == reading.isLenitedByPrecedingWord,
              Self.sameKind(reading.resultClass, listed.resultClass) else {
            return false
        }
        for (part, rest) in reading.inflection.lexicalizableParts where rest == listed.inflection {
            if generator.strings(of: reading.entry, as: reading.wordClass, part).contains(listed.entry.form) {
                return true
            }
        }
        return false
    }

    /// Nouns, pronouns and interrogatives count as one kind of word here, so that
    /// 'u + -pe "what thing" and the interrogative 'upe are recognised as one word.
    private static func sameKind(_ first: WordClass, _ second: WordClass) -> Bool {
        let nominal: Set<WordClass> = [.noun, .pronoun, .properNoun, .other]
        return first == second || (nominal.contains(first) && nominal.contains(second))
    }

    private static func unique(_ classes: [WordClass]) -> [WordClass] {
        var seen: Set<WordClass> = []
        return classes.filter { seen.insert($0).inserted }
    }
}

// MARK: - Verb matching

/// Finds the infixes in a word that could be one verb's template, filled. The
/// template's fixed text around the infix positions must match exactly; the text in
/// the positions must be infixes.
private struct VerbMatcher: Sendable {

    let entry: LexiconEntry
    /// Everything before positions 0 and 1, including any words before this one.
    let head: String
    /// The text between positions 1 and 2, and everything after position 2, as
    /// written; and, where «ol» absorbs a following ll (plltxe → poltxe), as written
    /// after that contraction.
    let spellings: [(middle: String, tail: String)]

    init(entry: LexiconEntry, template: InfixTemplate, wordIndex: Int) {
        self.entry = entry
        let before = template.words[..<wordIndex].map(\.bare)
        let after = template.words[(wordIndex + 1)...].map(\.bare)
        guard case .slotted(let onset, let middle, let coda) = template.words[wordIndex] else {
            preconditionFailure("Word \(wordIndex) of \(entry.headword) takes no infixes.")
        }
        head = (before + [onset]).joined(separator: " ")
        let tail = ([coda] + after).joined(separator: " ")
        var spellings = [(middle, tail)]
        if middle.hasPrefix("ll") {
            spellings.append((String(middle.dropFirst(2)), tail))
        } else if middle.isEmpty && tail.hasPrefix("ll") {
            spellings.append(("", String(tail.dropFirst(2))))
        }
        self.spellings = spellings
    }

    /// Each set of infixes that makes the template spell `word`. The bare verb is
    /// left to the lexicon lookup.
    func infixes(in word: String) -> [VerbInfixes] {
        guard word.hasPrefix(head) else {
            return []
        }
        var results: [VerbInfixes] = []
        for (middle, tail) in spellings where word.count >= head.count + middle.count + tail.count && word.hasSuffix(tail) {
            collect(word.dropFirst(head.count).dropLast(tail.count), middle: middle, into: &results)
        }
        return results
    }

    private func collect(_ inner: Substring, middle: String, into results: inout [VerbInfixes]) {

        func add(_ firstPart: Substring, _ secondPart: Substring) {
            guard let firsts = Self.firstPositions[String(firstPart)],
                  let seconds = Self.secondPositions[String(secondPart)] else {
                return
            }
            for (preFirst, first) in firsts {
                for second in seconds {
                    let infixes = VerbInfixes(preFirst: preFirst, first: first, second: second)
                    if !infixes.isEmpty {
                        results.append(infixes)
                    }
                }
            }
        }

        if middle.isEmpty {
            var split = inner.startIndex
            while true {
                add(inner[..<split], inner[split...])
                guard split < inner.endIndex else {
                    break
                }
                split = inner.index(after: split)
            }
        } else {
            var searchStart = inner.startIndex
            while let range = inner.range(of: middle, range: searchStart..<inner.endIndex) {
                add(inner[..<range.lowerBound], inner[range.upperBound...])
                searchStart = inner.index(after: range.lowerBound)
            }
        }
    }

    /// What positions 0 and 1 together can hold, by spelling.
    private static let firstPositions: [String: [(PreFirstInfix?, FirstInfix?)]] = {
        var table: [String: [(PreFirstInfix?, FirstInfix?)]] = [:]
        for preFirst in [nil] + PreFirstInfix.allCases.map(Optional.some) {
            for first in [nil] + FirstInfix.allCases.map(Optional.some) {
                for spelling in first?.spellings ?? [""] {
                    table[(preFirst?.rawValue ?? "") + spelling, default: []].append((preFirst, first))
                }
            }
        }
        return table
    }()

    /// What position 2 can hold, by spelling; «eng» is the raised form of «äng», and
    /// «eiy» the form «ei» takes before i or a pseudovowel.
    private static let secondPositions: [String: [SecondInfix?]] = {
        var table: [String: [SecondInfix?]] = ["": [nil], "eng": [.pejorative], "eiy": [.laudative]]
        for second in SecondInfix.allCases {
            table[second.rawValue, default: []].append(second)
        }
        return table
    }()
}
