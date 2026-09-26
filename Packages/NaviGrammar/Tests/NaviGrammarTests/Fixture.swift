//
//  Fixture.swift
//  NaviGrammarTests
//

@testable import NaviGrammar

/// The bundled lexicon and the engine built on it, loaded once for every test.
enum Fixture {

    static let lexicon: Lexicon = {
        do {
            return try Lexicon.bundled()
        } catch {
            fatalError("The bundled lexicon does not load: \(error)")
        }
    }()

    static let analyser = Analyser(lexicon: lexicon)
    static let generator = Generator()
    static let reader = TextReader(analyser: analyser)

    /// The lexicon entry for `headword` of the given class. Stops the test run if
    /// there is none, since every caller names a word the dictionary has.
    static func entry(_ headword: String, _ wordClass: WordClass) -> LexiconEntry {
        let form = Orthography.normalize(headword)
        guard let entry = lexicon.entries(withForm: form).first(where: { $0.wordClasses.contains(wordClass) }) else {
            fatalError("The lexicon has no \(wordClass) \(headword).")
        }
        return entry
    }

    /// The generated forms of `headword` as plain strings.
    static func forms(_ headword: String, _ wordClass: WordClass, _ inflection: Inflection) -> [String] {
        generator.strings(of: entry(headword, wordClass), as: wordClass, inflection)
    }

    /// The one-line summaries of every reading of `word`.
    static func summaries(_ word: String) -> [String] {
        analyser.analyse(word).analyses.map(\.summary)
    }
}
