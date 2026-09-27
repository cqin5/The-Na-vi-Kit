//
//  PronunciationView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI

/// The Na'vi alphabet of appendix G of the LearnNavi dictionary, letter by letter:
/// the sound each stands for, and a word with that sound to listen to.
struct PronunciationView: View {

    /// The grammar engine, which finds each example's recording once it has loaded.
    let grammar: GrammarState

    var body: some View {
        List {
            Section {
                Text("Each letter, or pair of letters such as px, stands for one sound, always the same one. Beside each letter is its sound as the dictionary writes pronunciations, and under it the letter's name.")
                    .font(.subheadline)
            }

            ForEach(Basics.alphabet) { group in
                Section {
                    ForEach(group.letters) { letter in
                        LetterRow(letter: letter, entry: grammar.search?.dictionaryEntry(forHeadword: letter.example.navi))
                    }
                } header: {
                    Text(group.title)
                } footer: {
                    if let footer = group.footer {
                        Text(footer)
                    }
                }
            }

            Section {
                Text("The 33 letters and their names are those of appendix G of the LearnNavi dictionary. Each word has its own stress, which the dictionary marks with ˈ in the word's pronunciation.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Pronunciation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A letter with its sound in phonetic notation and its name, then how it sounds
/// and an example word, with the dictionary's recording of the example.
private struct LetterRow: View {

    let letter: NaviLetter
    /// The dictionary's entry for the example word.
    let entry: NDDictionaryEntry?

    /// Wide enough for ts [t͡s] and for the name tìftang, at the reader's text size.
    @ScaledMetric(relativeTo: .title2) private var letterColumnWidth = 72

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Text(verbatim: letter.letter).font(.title2.weight(.semibold)))  \(Text(verbatim: "[\(letter.ipa)]").font(.footnote).foregroundStyle(.secondary))")
                    if let name = letter.name {
                        Text(verbatim: name)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: letterColumnWidth, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: letter.sound)
                        .font(.body)
                    Text("\(Text(verbatim: letter.example.navi).bold()), \(letter.example.english)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: spokenDescription))

            if let entry, entry.hasRecording {
                PronunciationButton(entry: entry)
            }
        }
        .padding(.vertical, 2)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }

    /// The row in words for VoiceOver, without the phonetic symbols.
    private var spokenDescription: String {
        let name = letter.name.map { ", called \($0)" } ?? ""
        return "\(letter.letter)\(name): \(letter.sound). For example, \(letter.example.navi), \(letter.example.english)."
    }
}

#Preview {
    NavigationStack {
        PronunciationView(grammar: .loading)
    }
}
