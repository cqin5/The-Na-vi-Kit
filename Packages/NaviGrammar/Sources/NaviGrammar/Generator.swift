//
//  Generator.swift
//  NaviGrammar
//

/// A word form the generator produced, with any remark about how it was made.
public struct GeneratedForm: Hashable, Sendable, CustomStringConvertible {

    /// The form, normalised: lower case, with the straight apostrophe.
    public let text: String
    public let notes: Set<FormNote>

    init(_ text: String, _ notes: Set<FormNote> = []) {
        self.text = text
        self.notes = notes
    }

    public var description: String {
        text
    }

    fileprivate func map(_ transform: (String) -> String) -> GeneratedForm {
        GeneratedForm(transform(text), notes)
    }

    fileprivate func adding(_ notes: Set<FormNote>) -> GeneratedForm {
        GeneratedForm(text, self.notes.union(notes))
    }
}

/// Inflects lexicon entries.
///
/// The rules are those of appendix H of the LearnNavi dictionary, version 16.1.0,
/// with lenition as documented in `Orthography`. The generator returns every
/// spelling a combination allows — `ngat` and `ngati` for the patientive of nga
/// "you" — and nothing for a combination its class of word does not take, such as a
/// case ending on a verb. The analyser accepts a reading only when the generator
/// produces the word being analysed from it, so the two cannot disagree.
public struct Generator: Sendable {

    public init() {}

    /// Every form of `entry`, taken as a word of class `base`, with `inflection`.
    /// Empty when the entry is not of that class or does not take the inflection.
    public func forms(of entry: LexiconEntry, as base: WordClass, _ inflection: Inflection) -> [GeneratedForm] {
        guard entry.wordClasses.contains(base) else {
            return []
        }
        // Inflecting a multi-word entry would mean guessing which word takes the
        // ending; only verbs, whose template says which word takes the infixes, are
        // inflected.
        if entry.isMultiword && !(inflection.isEmpty || (inflection.onlyInfixes && base == .verb)) {
            return []
        }

        let cores: [GeneratedForm]
        let coreClass: WordClass

        if let derivation = inflection.derivation {
            guard inflection.infixes == nil, let derived = derive(entry, as: base, derivation) else {
                return []
            }
            cores = derived
            coreClass = derivation.result
        } else if let infixes = inflection.infixes {
            guard base == .verb, !infixes.isEmpty, let template = entry.infixTemplate else {
                return []
            }
            cores = verbForms(template, infixes)
            // A participle describes a noun, and takes the attributive marker as an
            // adjective does.
            coreClass = infixes.first?.isParticiple == true ? .adjective : .verb
        } else {
            cores = [GeneratedForm(entry.form)]
            coreClass = base
        }

        switch coreClass {
        case .noun, .pronoun, .properNoun:
            let attachesToHeadword = inflection.derivation == nil
            return nominalForms(cores, as: coreClass, entry: entry, attachesToHeadword: attachesToHeadword, inflection)
        case .adjective:
            return adjectivalForms(cores, inflection)
        case .number:
            // Numbers join their noun with the attributive a as adjectives do
            // (appendix F: 'awa swawtsyìp, txìm a'aw).
            return inflection.conjunction ? [] : adjectivalForms(cores, inflection)
        case .verb, .adverb, .adposition, .other:
            let hasMore = inflection.prefix != nil || inflection.suffix != nil || inflection.ending != nil
                || inflection.attributive != nil || inflection.conjunction
            return hasMore ? [] : cores
        }
    }

    /// The forms as plain strings.
    public func strings(of entry: LexiconEntry, as base: WordClass, _ inflection: Inflection) -> [String] {
        forms(of: entry, as: base, inflection).map(\.text)
    }

    // MARK: - Verbs

    /// The verb with its infixes: position 0 then position 1 before the template's
    /// middle, position 2 after it.
    func verbForms(_ template: InfixTemplate, _ infixes: VerbInfixes) -> [GeneratedForm] {
        let preFirst = infixes.preFirst?.rawValue ?? ""
        let firsts = infixes.first?.spellings ?? [""]
        var forms: [GeneratedForm] = []

        for wordIndex in template.slottedWordIndices {
            guard case .slotted(let onset, let middle, let coda) = template.words[wordIndex] else {
                continue
            }
            let before = template.words[..<wordIndex].map(\.bare)
            let after = template.words[(wordIndex + 1)...].map(\.bare)
            for first in firsts {
                for second in secondSpellings(infixes.second, before: coda) {
                    let front = preFirst + first
                    var rest = middle + second.infix + coda
                    // A syllable cannot begin with ll or rr, so «ol» absorbs a following
                    // ll: vll → vol, plltxe → poltxe
                    // (https://naviteri.org/2012/06/spring-vocabulary-part-3/). What «er»
                    // does before rr is not documented, so no form is given.
                    if front.hasSuffix("l") && rest.hasPrefix("ll") {
                        rest.removeFirst(2)
                    } else if front.hasSuffix("r") && rest.hasPrefix("rr") {
                        continue
                    }
                    let word = onset + front + rest
                    forms.append(GeneratedForm((before + [word] + after).joined(separator: " "), second.notes))
                }
            }
        }
        return forms
    }

    /// The spellings of a position-2 infix before `coda`, the text that follows it.
    private func secondSpellings(_ second: SecondInfix?, before coda: String) -> [(infix: String, notes: Set<FormNote>)] {
        switch second {
        case nil:
            return [("", [])]
        case .laudative where coda.hasPrefix("i") || coda.hasPrefix("ll") || coda.hasPrefix("rr"):
            // Before i or a pseudovowel, «ei» becomes «eiy»: seiyi, veiyll
            // (https://naviteri.org/2012/06/spring-vocabulary-part-3/). The Reef dialect
            // keeps «ei»: seii (https://naviteri.org/2023/01/2653/).
            return [("eiy", []), ("ei", [.reefForm])]
        case .pejorative where coda.hasPrefix("i"):
            // Appendix H: before the vowel i, «äng» may be raised to «eng».
            return [("äng", []), ("eng", [.raisedPejorative])]
        case .some(let second):
            return [(second.rawValue, [])]
        }
    }

    // MARK: - Derivation

    private func derive(_ entry: LexiconEntry, as base: WordClass, _ derivation: Derivation) -> [GeneratedForm]? {
        switch derivation {
        case .agentNoun, .abilityNoun, .placeNoun, .able, .unable:
            // Productive on any verb (appendix H), which here means a one-word verb:
            // where the suffix would go on a compound is not recorded.
            guard base == .verb, !entry.isMultiword, entry.infixTemplate != nil else {
                return nil
            }
            let form = entry.form
            switch derivation {
            case .agentNoun: return [GeneratedForm(form + "yu")]
            case .abilityNoun: return [GeneratedForm(form + "tswo")]
            case .placeNoun: return [GeneratedForm(form + "tseng")]
            case .able: return [GeneratedForm("tsuk" + form)]
            default: return [GeneratedForm("ketsuk" + form)]
            }
        case .gerund:
            guard base == .verb, !entry.isMultiword, let template = entry.infixTemplate else {
                return nil
            }
            return verbForms(template, VerbInfixes(first: .activeParticiple)).map { $0.map { "tì" + $0 } }
        case .adverb:
            guard base == .adjective || base == .noun else {
                return nil
            }
            return [GeneratedForm("nì" + entry.form)]
        case .ordinal:
            guard base == .number else {
                return nil
            }
            return [GeneratedForm(entry.form + "ve")]
        }
    }

    // MARK: - Nouns and pronouns

    /// `attachesToHeadword` is false for a derived noun, whose stem is not the
    /// headword: its genitive is regular even when the headword's is not.
    private func nominalForms(
        _ cores: [GeneratedForm],
        as wordClass: WordClass,
        entry: LexiconEntry,
        attachesToHeadword: Bool,
        _ inflection: Inflection
    ) -> [GeneratedForm] {
        guard inflection.attributive == nil else {
            return []
        }
        let pronounStem = wordClass == .pronoun && attachesToHeadword && inflection.suffix == nil
        switch wordClass {
        case .pronoun:
            // Pronouns have their own words for number (moe, ayoe, ...), so they take
            // no number prefix; of the other suffixes, appendix H gives -tsyìp for them.
            guard inflection.prefix == nil, inflection.suffix == nil || inflection.suffix == .diminutive,
                  inflection.ending != .case(.vocative) else {
                return []
            }
            // A pronoun that is itself one case (tsaw) takes no ending, except an
            // attested irregular genitive (tseyä).
            if entry.isCaseFormOfPronoun && pronounStem, let ending = inflection.ending,
               !(ending == .case(.genitive) && entry.irregularGenitive != nil) {
                return []
            }
            // The pronouns in -ng take their case endings on a stem in -a (oengaru);
            // how they take an adposition is not documented.
            if pronounStem && entry.form.hasSuffix("ng"), case .adposition = inflection.ending {
                return []
            }
        case .properNoun:
            guard inflection.prefix == nil, inflection.suffix == nil else {
                return []
            }
        default:
            break
        }

        let irregularGenitive = attachesToHeadword && inflection.suffix == nil ? entry.irregularGenitive : nil
        let loanword = attachesToHeadword && inflection.suffix == nil && entry.isLoanwordEndingInI

        var forms: [GeneratedForm] = []
        for core in cores {
            let stem = core.text + (inflection.suffix?.rawValue ?? "")
            switch inflection.ending {
            case nil:
                forms.append(GeneratedForm(stem, core.notes))
            case .case(let nounCase):
                let endings = caseForms(stem, nounCase, pronoun: pronounStem, loanword: loanword, irregularGenitive: irregularGenitive)
                forms += endings.map { $0.adding(core.notes) }
            case .adposition(let adposition):
                forms.append(GeneratedForm(stem + adposition, core.notes))
            }
        }

        if inflection.conjunction {
            forms = forms.map { $0.map { $0 + "sì" } }
        }
        if let prefix = inflection.prefix {
            forms = forms.compactMap { applying(prefix, to: $0) }
        }
        return forms
    }

    /// The case forms of appendix H. After a vowel: -l, -t or -ti, -ru or -r, -ri.
    /// After a consonant, diphthong or pseudovowel: -ìl, -it or -ti, -ur, -ìri. The
    /// genitive is -yä after a, ä, e, i and ì and -ä otherwise; a pronoun ending in a
    /// fronts it to e (nga → ngeyä), and pronouns ending in a or e also have the
    /// casual genitive -y (ngey, oey).
    ///
    /// Dr. Frommer's usage adds to these (each post is cited where it applies): the
    /// pronouns in -ng, loanwords ending in an added -ì, nouns ending in a diphthong,
    /// in a tìftang or in -ia, and the pronouns in -o, whose genitive is irregular.
    func caseForms(
        _ stem: String,
        _ nounCase: NounCase,
        pronoun: Bool,
        loanword: Bool = false,
        irregularGenitive: String? = nil
    ) -> [GeneratedForm] {
        if nounCase == .genitive, let irregularGenitive {
            return [GeneratedForm(irregularGenitive, [.irregularGenitive])]
        }
        if nounCase == .subjective {
            return [GeneratedForm(stem)]
        }
        // oeng "we two" → oengaru, oengari: the endings go on a stem in -a
        // (https://naviteri.org/2011/12/one-more-for-2011/,
        // https://naviteri.org/2023/07/trr-tsyimawnuniya-lefpom-happy-independence-day/).
        if pronoun && stem.hasSuffix("ng") {
            return caseForms(stem + "a", nounCase, pronoun: true)
        }
        // Kelnì → Kelnìl, Kelnit, Kelnur, Kelnä, Kelnìri: a loanword's added -ì gives
        // way to the ending (https://naviteri.org/2022/01/aawa-tipangkxotsyip-a-teri-horen-lifyaya-a-few-little-discussions-about-grammar/).
        if loanword && stem.hasSuffix("ì") {
            let base = String(stem.dropLast())
            let endings: [NounCase: String] = [.agentive: "ìl", .patientive: "it", .dative: "ur", .genitive: "ä", .topical: "ìri"]
            return endings[nounCase].map { [GeneratedForm(base + $0)] } ?? []
        }

        let afterVowel = Orthography.endsInVowel(stem)
        // After a diphthong the vowel forms -t and -r are used too: wayt or wayit,
        // 'etnawr or 'etnawur (https://naviteri.org/2013/01/awvea-posti-zisita-amip-first-post-of-the-new-year/).
        let afterDiphthong = Orthography.endsInDiphthong(stem)
        // After a final tìftang, -ru and -ri too: olo'ru, olo'ri
        // (https://naviteri.org/2026/04/hiia-tisung-postiya-aham-follow-up-to-the-previous-post/).
        let afterTiftang = stem.hasSuffix("'")

        let suffixes: [String]
        switch nounCase {
        case .subjective:
            suffixes = [""]
        case .agentive:
            suffixes = afterVowel ? ["l"] : ["ìl"]
        case .patientive:
            suffixes = afterVowel ? ["t", "ti"] : afterDiphthong ? ["it", "ti", "t"] : ["it", "ti"]
        case .dative:
            suffixes = afterVowel ? ["ru", "r"] : afterDiphthong ? ["ur", "ru", "r"] : afterTiftang ? ["ur", "ru"] : ["ur"]
        case .topical:
            suffixes = afterVowel ? ["ri"] : afterTiftang ? ["ìri", "ri"] : ["ìri"]
        case .vocative:
            return [GeneratedForm(stem + "ya", [.collectiveVocative])]
        case .genitive:
            return genitiveForms(stem, pronoun: pronoun)
        }
        return suffixes.map { GeneratedForm(stem + $0) }
    }

    private func genitiveForms(_ stem: String, pronoun: Bool) -> [GeneratedForm] {
        if pronoun && stem.hasSuffix("o") {
            // po, fo, mefo and ayfo have the genitives peyä, feyä, mefeyä and ayfeyä,
            // not -ä; for the other pronouns in -o no genitive is documented, so none
            // is given.
            return []
        }
        if !pronoun && stem.hasSuffix("ia") {
            // soaia → soaiä, not soaiayä (https://naviteri.org/2011/05/some-miscellaneous-vocabulary/).
            return [GeneratedForm(String(stem.dropLast()) + "ä")]
        }
        var forms: [GeneratedForm]
        if !Orthography.takesYäGenitive(stem) {
            forms = [GeneratedForm(stem + "ä")]
        } else if pronoun && stem.hasSuffix("a") {
            forms = [GeneratedForm(String(stem.dropLast()) + "eyä")]
        } else {
            forms = [GeneratedForm(stem + "yä")]
        }
        if pronoun, let last = stem.last, last == "a" || last == "e" {
            let fronted = last == "a" ? String(stem.dropLast()) + "e" : stem
            forms.append(GeneratedForm(fronted + "y", [.casualGenitive]))
        }
        return forms
    }

    /// Adds a number or determiner prefix. Leniting prefixes lenite the word, and a
    /// vowel doubled across the boundary is written once: me+ 'eylan → meylan,
    /// pe+ 'ekxinum → pekxinum (appendix H, under pxe+;
    /// https://naviteri.org/2012/07/meetings-waterfalls-and-more/).
    func applying(_ prefix: NounPrefix, to form: GeneratedForm) -> GeneratedForm? {
        if prefix == .shortPlural {
            let lenited = Orthography.lenite(form.text)
            return lenited == form.text ? nil : GeneratedForm(lenited, form.notes)
        }
        var stem = prefix.lenites ? Orthography.lenite(form.text) : form.text
        if let last = prefix.rawValue.last, Orthography.vowels.contains(last), stem.first == last {
            stem.removeFirst()
        }
        return GeneratedForm(prefix.rawValue + stem, form.notes)
    }

    // MARK: - Adjectives and participles

    private func adjectivalForms(_ cores: [GeneratedForm], _ inflection: Inflection) -> [GeneratedForm] {
        guard inflection.prefix == nil, inflection.suffix == nil, inflection.ending == nil else {
            return []
        }
        var forms = cores
        switch inflection.attributive {
        case .before: forms = forms.map { $0.map { "a" + $0 } }
        case .after: forms = forms.map { $0.map { $0 + "a" } }
        case nil: break
        }
        if inflection.conjunction {
            forms = forms.map { $0.map { $0 + "sì" } }
        }
        return forms
    }
}

extension Inflection {

    /// Whether the inflection adds verb infixes and nothing else.
    var onlyInfixes: Bool {
        infixes != nil && derivation == nil && prefix == nil && suffix == nil && ending == nil
            && attributive == nil && !conjunction
    }
}
