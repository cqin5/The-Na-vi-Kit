//
//  NumbersView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI
import NaviGrammar

/// Na'vi numbers, which count in eights: a converter, the words to count with, and how
/// larger numbers are built. The number words come from NaviGrammar's `Numeral`,
/// which follows appendix A of the LearnNavi dictionary.
struct NumbersView: View {

    /// The grammar engine, which finds each word's recording once it has loaded.
    let grammar: GrammarState

    @State private var text = ""

    private static let zeroToSeven = (0..<8).compactMap { Numeral($0) }
    private static let powersOfEight = [8, 64, 512, 4096].compactMap { Numeral($0) }
    private static let eightPlusUnits = (9...15).compactMap { Numeral($0) }
    private static let firstToEighth = (1...8).compactMap { Numeral($0) }

    var body: some View {
        List {
            Section {
                TextField("Number", text: $text, prompt: Text(verbatim: "100, zamtsìvosìng"))
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .accessibilityLabel("Number to convert")
                if let reading = Numeral.read(text) {
                    ConversionView(reading: reading, entry: reading.numeral.flatMap { entry(for: $0.word) })
                }
            } header: {
                Text("Convert")
            } footer: {
                Text("Type a number to see it in Na'vi, or a Na'vi number to see its value.")
            }

            Section {
                ForEach(Self.zeroToSeven, id: \.value) { numeral in
                    NumberRow(label: numeral.value.formatted(), word: numeral.word, entry: entry(for: numeral.word))
                }
            } header: {
                Text("Zero to Seven")
            } footer: {
                Text("Na'vi counts in eights. vol, eight, does the work of our ten, and zam, sixty-four, of our hundred.")
            }

            Section {
                ForEach(Self.powersOfEight, id: \.value) { numeral in
                    NumberRow(label: numeral.value.formatted(), word: numeral.word,
                              detail: "\(numeral.octal) in base eight", entry: entry(for: numeral.word))
                }
            } header: {
                Text("Powers of Eight")
            } footer: {
                Text("me-, pxe-, tsì-, mrr-, pu- and ki- multiply these by two to seven: mevol is 16, and pxezam is 192.")
            }

            Section {
                ForEach(Self.eightPlusUnits, id: \.value) { numeral in
                    NumberRow(label: numeral.value.formatted(), word: numeral.word,
                              detail: numeral.parts.map(\.text).joined(separator: " + "), entry: entry(for: numeral.word))
                }
            } header: {
                Text("Adding Units")
            } footer: {
                Text("After a larger number, one to seven take the short forms -aw, -mun, -pey, -sìng, -mrr, -fu and -hin, and vol drops its l before a consonant. A number is said from its largest part down: zamtsìvosìng is zam + tsìvo + sìng, 64 + 4 × 8 + 4, which is 100.")
            }

            Section {
                ForEach(Self.firstToEighth, id: \.value) { numeral in
                    if let ordinal = numeral.ordinal {
                        NumberRow(label: englishOrdinal(numeral.value), word: ordinal, entry: entry(for: ordinal))
                    }
                }
            } header: {
                Text("First to Eighth")
            } footer: {
                Text("-ve makes an ordinal, and some numbers are shortened before it: mune, two, gives muve, second. The converter gives the ordinals up to the fifteenth.")
            }

            Section {
                ForEach(Basics.digitNames) { word in
                    BasicWordRow(word: word, entry: entry(for: word.navi))
                }
            } header: {
                Text("The Digits 8 and 9")
            } footer: {
                Text("For phone numbers and the like. They name the digits, not the values: eight is vol.")
            }

            Section {
                ForEach(Basics.numberPhrases) { phrase in
                    PhraseRow(phrase: phrase)
                }
            } header: {
                Text("Using Numbers")
            } footer: {
                Text("A number goes with its noun as an adjective does, joined to it by a, and the noun stays singular: 'awa tute, one person. Say how many only once: you two are teachers is Menga lu karyu, with karyu, teacher, in the singular.")
            }

            Section {
                Text("The number words, and the way they combine, are those of appendix A of the LearnNavi dictionary.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Numbers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func entry(for word: String) -> NDDictionaryEntry? {
        grammar.search?.dictionaryEntry(forHeadword: word)
    }
}

/// A number, its Na'vi word and the recording of it where the dictionary has one, on
/// one line: 9, volaw, vol + aw. A row with no detail of its own shows the word's
/// pronunciation instead.
private struct NumberRow: View {

    /// The number in digits, or its ordinal, such as 1st.
    let label: String
    let word: String
    var detail: String?
    /// The dictionary's entry for the word, for its pronunciation and recording.
    let entry: NDDictionaryEntry?

    /// Wide enough for 4,096 at the reader's text size.
    @ScaledMetric(relativeTo: .body) private var labelWidth = 52

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(verbatim: label)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: labelWidth, alignment: .trailing)
                Text(verbatim: word)
                    .font(.headline)
                if let secondary = detail ?? entry?.ipa, !secondary.isEmpty {
                    Text(verbatim: secondary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // VoiceOver reads the number and the word, not the phonetic symbols.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: [label, word, detail].compactMap { $0 }.joined(separator: ", ")))

            if let entry, entry.hasRecording {
                PronunciationButton(entry: entry)
            }
        }
        // Separators start at the row's edge, not at the number, whose width varies.
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

/// An English ordinal in digits: 1st, 2nd, 3rd, 11th.
private func englishOrdinal(_ value: Int) -> String {
    let suffix = switch (value % 10, value % 100) {
    case (_, 11...13): "th"
    case (1, _): "st"
    case (2, _): "nd"
    case (3, _): "rd"
    default: "th"
    }
    return "\(value)\(suffix)"
}

/// What the converter's text reads as: a number's Na'vi word, its value and how the
/// word is built, or why there is no such number.
private struct ConversionView: View {

    let reading: Numeral.Reading
    /// The dictionary's entry for the number word, for its recording.
    let entry: NDDictionaryEntry?

    var body: some View {
        switch reading {
        case .digits(let numeral), .word(let numeral):
            NumeralView(numeral: numeral, entry: entry)
        case .tooLarge:
            Text("Na'vi number words go up to \(Numeral.largest.formatted()), which is \(String(Numeral.largest, radix: 8)) in base eight.")
                .foregroundStyle(.secondary)
        case .notANumber:
            Text("Not a number. Type a whole number from 0 to \(Numeral.largest.formatted()), or a Na'vi number.")
                .foregroundStyle(.secondary)
        }
    }
}

/// A number's Na'vi word, its value in our numbers and in base eight, how the word is
/// built, and its ordinal where the dictionary gives one.
private struct NumeralView: View {

    let numeral: Numeral
    let entry: NDDictionaryEntry?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: numeral.word)
                    .font(.title3.weight(.semibold))
                Text("\(numeral.value.formatted()) · \(numeral.octal) in base eight")
                    .font(.subheadline)
                if numeral.parts.count > 1 {
                    Text(verbatim: numeral.parts.map(\.text).joined(separator: " + "))
                        .font(.subheadline)
                }
                if let arithmetic {
                    Text(verbatim: arithmetic)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let ordinal = numeral.ordinal {
                    Text("Ordinal: \(Text(verbatim: ordinal).bold()), \(englishOrdinal(numeral.value))")
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            if let entry, entry.hasRecording {
                PronunciationButton(entry: entry)
            }
        }
        .padding(.vertical, 4)
    }

    /// The sum the word stands for, as 64 + 4 × 8 + 4. Nil when it would only repeat
    /// the value, as it would for pxey or zam.
    private var arithmetic: String? {
        let terms = numeral.parts.map { part in
            if part.place == 1 {
                "\(part.digit)"
            } else if part.digit == 1 {
                part.place.formatted()
            } else {
                "\(part.digit) × \(part.place.formatted())"
            }
        }
        return terms.count == 1 && !terms[0].contains("×") ? nil : terms.joined(separator: " + ")
    }
}

#Preview {
    NavigationStack {
        NumbersView(grammar: .loading)
    }
}
