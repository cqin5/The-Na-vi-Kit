//
//  RoundTripTests.swift
//  NaviGrammarTests
//
//  Generates every case and number form of every noun and pronoun, and every
//  placement of every verb infix, then checks that the analyser traces each form back
//  to the word and inflection it came from. Forms with more than one reading are
//  counted and, when NAVIGRAMMAR_REPORT is set to a file path, listed there.
//

import Foundation
import Testing
@testable import NaviGrammar

@Suite("Round trip over the whole lexicon")
struct RoundTripTests {

    /// One inflection to generate and analyse back.
    struct Case: Sendable {
        let entry: LexiconEntry
        let wordClass: WordClass
        let inflection: Inflection
    }

    struct Outcome: Sendable {
        var forms = 0
        /// Forms whose own reading the analyser did not find.
        var failures: [String] = []
        /// Forms read from more than one lexicon entry.
        var ambiguousAcrossWords: [String: [String]] = [:]
        /// Forms read as more than one inflection of the same entry.
        var ambiguousWithinWord: [String: [String]] = [:]
        /// Forms whose own reading is not the first.
        var outranked = 0
        /// Forms read as a word the dictionary lists, which the form's own reading builds.
        var folded = 0

        mutating func merge(_ other: Outcome) {
            forms += other.forms
            failures += other.failures
            ambiguousAcrossWords.merge(other.ambiguousAcrossWords) { first, _ in first }
            ambiguousWithinWord.merge(other.ambiguousWithinWord) { first, _ in first }
            outranked += other.outranked
            folded += other.folded
        }
    }

    @Test("Every case and number of every noun and pronoun")
    func nouns() async {
        var cases: [Case] = []
        for entry in Fixture.lexicon.entries where !entry.isMultiword {
            for wordClass in Set(entry.wordClasses) where wordClass.isNominal {
                let prefixes: [NounPrefix?] = wordClass == .noun ? [nil, .dual, .trial, .plural, .shortPlural] : [nil]
                for prefix in prefixes {
                    for nounCase in NounCase.regular {
                        cases.append(Case(entry: entry, wordClass: wordClass, inflection: .case(nounCase, prefix: prefix)))
                    }
                }
            }
        }

        let outcome = await Self.check(cases)
        Self.report(outcome, title: "Nouns and pronouns")
        #expect(outcome.forms > 40_000)
        #expect(outcome.failures.isEmpty, "\(outcome.failures.count) forms were not traced back: \(outcome.failures.prefix(20))")
    }

    @Test("Every placement of every verb infix")
    func verbs() async {
        let preFirsts: [PreFirstInfix?] = [nil] + PreFirstInfix.allCases
        let firsts: [FirstInfix?] = [nil] + FirstInfix.allCases
        let seconds: [SecondInfix?] = [nil] + SecondInfix.allCases

        var cases: [Case] = []
        for entry in Fixture.lexicon.entries where entry.infixTemplate != nil {
            for preFirst in preFirsts {
                for first in firsts {
                    for second in seconds {
                        let infixes = VerbInfixes(preFirst: preFirst, first: first, second: second)
                        if !infixes.isEmpty {
                            cases.append(Case(entry: entry, wordClass: .verb, inflection: Inflection(infixes: infixes)))
                        }
                    }
                }
            }
        }

        let outcome = await Self.check(cases)
        Self.report(outcome, title: "Verbs")
        #expect(outcome.forms > 200_000)
        #expect(outcome.failures.isEmpty, "\(outcome.failures.count) forms were not traced back: \(outcome.failures.prefix(20))")
    }

    // MARK: - Checking

    /// Generates and analyses every case, spread over the available cores.
    static func check(_ cases: [Case]) async -> Outcome {
        let chunkSize = max(1, cases.count / (ProcessInfo.processInfo.activeProcessorCount * 4))
        return await withTaskGroup(of: Outcome.self) { group in
            for start in stride(from: 0, to: cases.count, by: chunkSize) {
                let chunk = Array(cases[start..<min(start + chunkSize, cases.count)])
                group.addTask { check(chunk: chunk) }
            }
            var total = Outcome()
            for await outcome in group {
                total.merge(outcome)
            }
            return total
        }
    }

    private static func check(chunk: [Case]) -> Outcome {
        var outcome = Outcome()
        for item in chunk {
            for form in Fixture.generator.forms(of: item.entry, as: item.wordClass, item.inflection) {
                outcome.forms += 1
                let analysis = Fixture.analyser.analyse(form.text)
                let readings = analysis.analyses
                let isOwn = { (reading: Analysis) in
                    reading.entry.id == item.entry.id && reading.inflection == item.inflection
                }
                // A reading folded into a word the dictionary lists is traced back too.
                if !readings.contains(where: isOwn) && analysis.folded.contains(where: isOwn) {
                    outcome.folded += 1
                    continue
                }
                let own = readings.firstIndex(where: isOwn)
                guard let own else {
                    outcome.failures.append("\(form.text) ← \(item.entry.headword) \(item.inflection) :: \(readings.map(\.summary))")
                    continue
                }
                if own != 0 {
                    outcome.outranked += 1
                }
                let entries = Set(readings.map(\.entry.id))
                if entries.count > 1 {
                    outcome.ambiguousAcrossWords[form.text] = readings.map(\.summary)
                } else if readings.count > 1 {
                    outcome.ambiguousWithinWord[form.text] = readings.map(\.summary)
                }
            }
        }
        return outcome
    }

    /// Prints a summary, and writes every ambiguous form to the file named by the
    /// NAVIGRAMMAR_REPORT environment variable, appending, if it is set.
    static func report(_ outcome: Outcome, title: String) {
        let summary = """
            \(title): \(outcome.forms) forms generated, \(outcome.failures.count) not traced back, \
            \(outcome.folded) read as a listed word they build; \
            \(outcome.ambiguousAcrossWords.count) also read as another word, \
            \(outcome.ambiguousWithinWord.count) read as more than one inflection of the same word, \
            \(outcome.outranked) with another reading ranked first.
            """
        print(summary)

        guard let path = ProcessInfo.processInfo.environment["NAVIGRAMMAR_REPORT"] else {
            return
        }
        var text = "## \(title)\n\n\(summary)\n"
        if !outcome.failures.isEmpty {
            text += "\n### Not traced back (\(outcome.failures.count))\n\n" + outcome.failures.sorted().map { "- \($0)\n" }.joined()
        }
        for (heading, forms) in [("Also read as another word", outcome.ambiguousAcrossWords),
                                 ("More than one inflection of the same word", outcome.ambiguousWithinWord)] {
            text += "\n### \(heading) (\(forms.count))\n\n"
            for form in forms.keys.sorted() {
                text += "- \(form): \(forms[form, default: []].joined(separator: " | "))\n"
            }
        }
        let url = URL(fileURLWithPath: path)
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data((text + "\n").utf8))
            try? handle.close()
        } else {
            try? (text + "\n").write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
