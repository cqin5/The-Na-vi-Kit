//
//  Inflection.swift
//  NaviGrammar
//
//  The inflections and derivations the engine knows, as listed in appendix H of the
//  LearnNavi dictionary (version 16.1.0). Names and explanations are our own.
//

// MARK: - Verbal infixes

/// The infixes of position 0, before the first-position infix. The two can be
/// combined, reflexive first: 'rrko "roll" gives 'äpeykamrrko
/// (https://naviteri.org/2015/04/some-new-words-for-may-day/).
public enum PreFirstInfix: String, Hashable, Sendable, CaseIterable {
    case reflexive = "äp"
    case causative = "eyk"
    case reflexiveCausative = "äpeyk"

    public var name: String {
        switch self {
        case .reflexive: "reflexive"
        case .causative: "causative"
        case .reflexiveCausative: "reflexive causative"
        }
    }

    public var explanation: String {
        switch self {
        case .reflexive: "the subject acts on itself"
        case .causative: "the subject makes someone do it"
        case .reflexiveCausative: "the subject makes itself do it"
        }
    }
}

/// The infixes of position 1: tense, aspect, mood and the participles.
public enum FirstInfix: String, Hashable, Sendable, CaseIterable {
    case past = "am"
    case recentPast = "ìm"
    case future = "ay"
    case nearFuture = "ìy"
    case intendedFuture = "asy"
    case intendedNearFuture = "ìsy"
    case perfective = "ol"
    case imperfective = "er"
    case pastPerfective = "alm"
    case recentPastPerfective = "ìlm"
    case futurePerfective = "aly"
    case nearFuturePerfective = "ìly"
    case pastImperfective = "arm"
    case recentPastImperfective = "ìrm"
    case futureImperfective = "ary"
    case nearFutureImperfective = "ìry"
    case subjunctive = "iv"
    case pastSubjunctive = "imv"
    case futureSubjunctive = "iyev"
    case perfectiveSubjunctive = "ilv"
    case imperfectiveSubjunctive = "irv"
    case activeParticiple = "us"
    case passiveParticiple = "awn"

    /// The spellings of the infix. Appendix H lists the future subjunctive as both
    /// «iyev» and «ìyev», with the same meaning.
    public var spellings: [String] {
        self == .futureSubjunctive ? ["iyev", "ìyev"] : [rawValue]
    }

    /// Whether the infix makes a participle, which describes a noun as an adjective does.
    public var isParticiple: Bool {
        self == .activeParticiple || self == .passiveParticiple
    }

    public var name: String {
        switch self {
        case .past: "past"
        case .recentPast: "recent past"
        case .future: "future"
        case .nearFuture: "near future"
        case .intendedFuture: "future, with intent"
        case .intendedNearFuture: "near future, with intent"
        case .perfective: "perfective"
        case .imperfective: "imperfective"
        case .pastPerfective: "past perfective"
        case .recentPastPerfective: "recent past perfective"
        case .futurePerfective: "future perfective"
        case .nearFuturePerfective: "near future perfective"
        case .pastImperfective: "past imperfective"
        case .recentPastImperfective: "recent past imperfective"
        case .futureImperfective: "future imperfective"
        case .nearFutureImperfective: "near future imperfective"
        case .subjunctive: "subjunctive"
        case .pastSubjunctive: "past subjunctive"
        case .futureSubjunctive: "future subjunctive"
        case .perfectiveSubjunctive: "perfective subjunctive"
        case .imperfectiveSubjunctive: "imperfective subjunctive"
        case .activeParticiple: "active participle"
        case .passiveParticiple: "passive participle"
        }
    }

    public var explanation: String {
        switch self {
        case .past: "happened before now"
        case .recentPast: "happened just now"
        case .future: "will happen"
        case .nearFuture: "will happen soon"
        case .intendedFuture: "will happen, as the speaker is determined it will"
        case .intendedNearFuture: "will happen soon, as the speaker is determined it will"
        case .perfective: "a completed action"
        case .imperfective: "an action in progress"
        case .pastPerfective: "had been completed"
        case .recentPastPerfective: "has just been completed"
        case .futurePerfective: "will have been completed"
        case .nearFuturePerfective: "will soon have been completed"
        case .pastImperfective: "was in progress"
        case .recentPastImperfective: "was in progress just now"
        case .futureImperfective: "will be in progress"
        case .nearFutureImperfective: "will soon be in progress"
        case .subjunctive: "wished for, possible or required, as after 'want' or 'must'"
        case .pastSubjunctive: "wished for or possible, in the past"
        case .futureSubjunctive: "wished for or possible, in the future"
        case .perfectiveSubjunctive: "wished for or possible, as a completed action"
        case .imperfectiveSubjunctive: "wished for or possible, as an action in progress"
        case .activeParticiple: "describes someone or something doing it: '-ing'"
        case .passiveParticiple: "describes someone or something it is done to: '-ed'"
        }
    }
}

/// The infixes of position 2: the speaker's attitude, and evidence.
public enum SecondInfix: String, Hashable, Sendable, CaseIterable {
    case laudative = "ei"
    case pejorative = "äng"
    case honorific = "uy"
    case inferential = "ats"

    public var name: String {
        switch self {
        case .laudative: "laudative"
        case .pejorative: "pejorative"
        case .honorific: "honorific"
        case .inferential: "inferential"
        }
    }

    public var explanation: String {
        switch self {
        case .laudative: "the speaker is pleased about it"
        case .pejorative: "the speaker is displeased about it"
        case .honorific: "formal or ceremonial speech"
        case .inferential: "the speaker infers it rather than knowing it"
        }
    }
}

/// The infixes of a verb form, one set per position.
public struct VerbInfixes: Hashable, Sendable {

    /// Position 0.
    public var preFirst: PreFirstInfix?
    public var first: FirstInfix?
    public var second: SecondInfix?

    public init(preFirst: PreFirstInfix? = nil, first: FirstInfix? = nil, second: SecondInfix? = nil) {
        self.preFirst = preFirst
        self.first = first
        self.second = second
    }

    public var isEmpty: Bool {
        preFirst == nil && first == nil && second == nil
    }
}

// MARK: - Nouns

public enum NounCase: String, Hashable, Sendable, CaseIterable {
    case subjective
    case agentive
    case patientive
    case dative
    case genitive
    case topical
    case vocative

    /// The cases that every noun and pronoun takes. The vocative suffix -ya is for
    /// collective nouns only (appendix H), and the lexicon does not mark which nouns
    /// are collective.
    public static let regular: [NounCase] = [.subjective, .agentive, .patientive, .dative, .genitive, .topical]

    public var explanation: String {
        switch self {
        case .subjective: "the subject of a verb with no object"
        case .agentive: "the subject of a verb with an object"
        case .patientive: "the object of a verb"
        case .dative: "to or for whom: the indirect object"
        case .genitive: "whose: of, 's"
        case .topical: "what the sentence is about: as for, regarding"
        case .vocative: "the one being addressed"
        }
    }
}

/// The prefixes that mark a noun's number or pick it out. Those marked + in
/// appendix H lenite the noun.
public enum NounPrefix: String, Hashable, Sendable, CaseIterable {
    case dual = "me"
    case trial = "pxe"
    case plural = "ay"
    /// The plural marked by lenition alone, without ay+.
    case shortPlural = ""
    case this = "fì"
    case that = "tsa"
    case which = "pe"
    case every = "fra"
    case these = "fay"
    case those = "tsay"
    case whichPlural = "pay"
    case allOfThese = "fray"
    case kindOf = "fne"
    /// pe+ with fne-, asking which kind (appendix F: pefnetxintìn "what role").
    case whichKind = "pefne"
    case pairOf = "munsna"

    /// Whether the prefix lenites the noun.
    public var lenites: Bool {
        switch self {
        case .dual, .trial, .plural, .shortPlural, .which, .these, .those, .whichPlural, .allOfThese: true
        case .this, .that, .every, .kindOf, .whichKind, .pairOf: false
        }
    }

    /// How appendix H writes the prefix: `ay+` lenites, `fì-` does not.
    public var notation: String {
        switch self {
        case .shortPlural: "lenition"
        case .whichKind: "pe+ fne-"
        default: rawValue + (lenites ? "+" : "-")
        }
    }

    public var name: String {
        switch self {
        case .dual: "dual"
        case .trial: "trial"
        case .plural: "plural"
        case .shortPlural: "plural"
        case .this: "this"
        case .that: "that"
        case .which: "which"
        case .every: "every"
        case .these: "these"
        case .those: "those"
        case .whichPlural: "which (plural)"
        case .allOfThese: "all of these"
        case .kindOf: "kind of"
        case .whichKind: "which kind of"
        case .pairOf: "pair of"
        }
    }

    public var explanation: String {
        switch self {
        case .dual: "two of them"
        case .trial: "three of them"
        case .plural: "more than one"
        case .shortPlural: "more than one, marked by softening the first sound instead of ay+"
        case .this: "this one"
        case .that: "that one"
        case .which: "asks which one"
        case .every: "every one of them"
        case .these: "these ones"
        case .those: "those ones"
        case .whichPlural: "asks which ones"
        case .allOfThese: "all of these ones"
        case .kindOf: "a kind or type of it"
        case .whichKind: "asks which kind"
        case .pairOf: "a pair of them"
        }
    }
}

/// Suffixes that come between a noun and its case ending.
public enum NounSuffix: String, Hashable, Sendable, CaseIterable {
    case diminutive = "tsyìp"
    case state = "fkeyk"
    case indefinite = "o"
    case interrogative = "pe"

    public var name: String {
        switch self {
        case .diminutive: "diminutive"
        case .state: "state"
        case .indefinite: "indefinite"
        case .interrogative: "which"
        }
    }

    public var explanation: String {
        switch self {
        case .diminutive: "small, or said with affection"
        case .state: "the state or condition of it"
        case .indefinite: "some, any"
        case .interrogative: "asks which or what"
        }
    }
}

/// What ends a noun: a case suffix, or an adposition attached as a suffix.
public enum NounEnding: Hashable, Sendable {
    case `case`(NounCase)
    /// An adposition written after its noun, which the dictionary's front matter says
    /// then attaches as a suffix: kelku + mì → kelkumì "in the home". Holds the
    /// adposition's normalised form.
    case adposition(String)
}

// MARK: - Derivation and attribution

/// The productive derivations of appendix H, which make a word of a different class.
public enum Derivation: String, Hashable, Sendable, CaseIterable {
    /// verb + -yu: the one who does it (taron "hunt" → taronyu "hunter").
    case agentNoun = "-yu"
    /// verb + -tswo: the ability to do it.
    case abilityNoun = "-tswo"
    /// verb + -tseng: the place where it is done (colloquial).
    case placeNoun = "-tseng"
    /// tì- + verb with «us»: the act of doing it, a gerund.
    case gerund = "tì- «us»"
    /// tsuk- + verb: able to be done.
    case able = "tsuk-"
    /// ketsuk- + verb: unable to be done.
    case unable = "ketsuk-"
    /// nì- + adjective or noun: an adverb.
    case adverb = "nì-"
    /// number + -ve: an ordinal.
    case ordinal = "-ve"

    /// The class of the word the derivation makes.
    var result: WordClass {
        switch self {
        case .agentNoun, .abilityNoun, .placeNoun, .gerund: .noun
        case .able, .unable, .ordinal: .adjective
        case .adverb: .adverb
        }
    }

    public var name: String {
        switch self {
        case .agentNoun: "agent noun"
        case .abilityNoun: "ability noun"
        case .placeNoun: "place noun"
        case .gerund: "gerund"
        case .able: "able to be"
        case .unable: "unable to be"
        case .adverb: "adverb"
        case .ordinal: "ordinal"
        }
    }

    public var explanation: String {
        switch self {
        case .agentNoun: "the one who does it"
        case .abilityNoun: "the ability to do it"
        case .placeNoun: "the place where it is done"
        case .gerund: "the act of doing it"
        case .able: "can be done"
        case .unable: "cannot be done"
        case .adverb: "in this way"
        case .ordinal: "the position in a sequence: first, second"
        }
    }
}

/// The attributive marker a, which joins an adjective or participle to its noun:
/// before the adjective when it follows the noun (ikran aean), after it when it
/// precedes the noun (txantsana ikran).
public enum Attributive: String, Hashable, Sendable, CaseIterable {
    case before
    case after
}

// MARK: - The whole inflection

/// Everything that turns a lexicon entry into a word form. The generator decides
/// which combinations a class of word accepts.
public struct Inflection: Hashable, Sendable {

    public var derivation: Derivation?
    public var infixes: VerbInfixes?
    public var prefix: NounPrefix?
    public var suffix: NounSuffix?
    public var ending: NounEnding?
    public var attributive: Attributive?
    /// The conjunction -sì "and", attached as a suffix.
    public var conjunction: Bool

    public init(
        derivation: Derivation? = nil,
        infixes: VerbInfixes? = nil,
        prefix: NounPrefix? = nil,
        suffix: NounSuffix? = nil,
        ending: NounEnding? = nil,
        attributive: Attributive? = nil,
        conjunction: Bool = false
    ) {
        self.derivation = derivation
        self.infixes = infixes
        self.prefix = prefix
        self.suffix = suffix
        self.ending = ending
        self.attributive = attributive
        self.conjunction = conjunction
    }

    public static let none = Inflection()

    /// Shorthand for a noun or pronoun in a case.
    public static func `case`(_ nounCase: NounCase, prefix: NounPrefix? = nil) -> Inflection {
        Inflection(prefix: prefix, ending: nounCase == .subjective ? nil : .case(nounCase))
    }

    /// Shorthand for a verb with infixes.
    public static func verb(_ preFirst: PreFirstInfix? = nil, _ first: FirstInfix? = nil, _ second: SecondInfix? = nil) -> Inflection {
        Inflection(infixes: VerbInfixes(preFirst: preFirst, first: first, second: second))
    }

    /// Whether nothing is added to the word.
    public var isEmpty: Bool {
        self == .none
    }

    /// Each affix the dictionary lists words made with — a derivation, a determiner
    /// prefix, a suffix before the ending, or a position-0 infix — paired with the
    /// rest of the inflection. Words such as 'itetsyìp "little daughter" and zeyko
    /// "fix" (zo with «eyk») are listed in their own right.
    ///
    /// Number prefixes and the tense, aspect and mood infixes are left out: a word
    /// that looks like a plural or a tense of another is usually a different word
    /// (sil is not the plural of til).
    var lexicalizableParts: [(part: Inflection, rest: Inflection)] {
        var parts: [(Inflection, Inflection)] = []
        if let derivation {
            var rest = self
            rest.derivation = nil
            parts.append((Inflection(derivation: derivation), rest))
        }
        if let prefix, ![.dual, .trial, .plural, .shortPlural].contains(prefix) {
            var rest = self
            rest.prefix = nil
            parts.append((Inflection(prefix: prefix), rest))
        }
        if let suffix {
            var rest = self
            rest.suffix = nil
            parts.append((Inflection(suffix: suffix), rest))
        }
        if let infixes, let preFirst = infixes.preFirst, derivation == nil {
            var remaining = infixes
            remaining.preFirst = nil
            var rest = self
            rest.infixes = remaining.isEmpty ? nil : remaining
            parts.append((Inflection(infixes: VerbInfixes(preFirst: preFirst)), rest))
            // «äpeyk» holds the «äp» of a listed reflexive, such as win säpi "hurry",
            // with «eyk» added to it.
            if preFirst == .reflexiveCausative {
                var causative = self
                causative.infixes?.preFirst = .causative
                parts.append((Inflection(infixes: VerbInfixes(preFirst: .reflexive)), causative))
            }
        }
        return parts
    }
}

/// A remark about how a form was made, shown with its analysis.
public enum FormNote: String, Hashable, Sendable, CaseIterable {
    /// The casual genitive -y of pronouns ending in a or e (ngey "your").
    case casualGenitive
    /// «eng», the optional form of «äng» before i.
    case raisedPejorative
    /// The genitive the dictionary gives as irregular.
    case irregularGenitive
    /// The vocative -ya, which appendix H gives for collective nouns only.
    case collectiveVocative
    /// A Reef-dialect form: «ei» kept before i or a pseudovowel (seii for seiyi).
    case reefForm
    /// A word written with the Reef dialect's letters (ù, or b, d and g for the
    /// ejectives), read with the forest dialect's.
    case reefSpelling

    public var explanation: String {
        switch self {
        case .casualGenitive: "casual form of the genitive"
        case .raisedPejorative: "«eng», the form «äng» may take before i"
        case .irregularGenitive: "irregular genitive, as the dictionary gives it"
        case .collectiveVocative: "the vocative -ya is used with collective nouns"
        case .reefForm: "Reef-dialect form"
        case .reefSpelling: "Reef-dialect spelling, read as the dictionary spells it"
        }
    }
}
