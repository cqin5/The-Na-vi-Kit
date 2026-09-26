//
//  WordListView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI

/// Words to learn in groups, such as the days of the week, each with the dictionary's
/// recording of it where there is one.
struct WordListView: View {

    let title: String
    let groups: [WordGroup]
    /// The grammar engine, which finds each word's dictionary entry once it has loaded.
    let grammar: GrammarState

    var body: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.words) { word in
                        BasicWordRow(word: word, entry: grammar.search?.dictionaryEntry(forHeadword: word.navi))
                    }
                } header: {
                    Text(group.title)
                } footer: {
                    if let footer = group.footer {
                        Text(footer)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A word, its pronunciation and meaning, and a button that plays the dictionary's
/// recording of it. Words without a recording, or not yet looked up, leave those out.
struct BasicWordRow: View {

    let word: BasicWord
    /// The dictionary's entry for the word, for its pronunciation and recording.
    let entry: NDDictionaryEntry?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                if let ipa = entry?.ipa, !ipa.isEmpty {
                    Text("\(Text(verbatim: word.navi).font(.headline))  \(Text(verbatim: ipa).font(.subheadline).foregroundStyle(.secondary))")
                } else {
                    Text(verbatim: word.navi)
                        .font(.headline)
                }
                Text(verbatim: word.english)
                    .font(.subheadline)
                if let note = word.note {
                    Text(verbatim: note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // VoiceOver reads the word and its meaning, not the phonetic symbols.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: [word.navi, word.english, word.note].compactMap { $0 }.joined(separator: ", ")))

            if let entry, entry.hasRecording {
                PronunciationButton(entry: entry)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Plays a dictionary entry's recording. It is borderless, so that tapping elsewhere
/// in its row does not play it.
struct PronunciationButton: View {

    let entry: NDDictionaryEntry

    /// Counts taps. Each plays a light tap, felt at once, while the recording takes a
    /// moment to start.
    @State private var playCount = 0

    var body: some View {
        Button {
            playCount += 1
            PronunciationPlayer.shared.play(fileNamed: entry.localAudioFileName)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .imageScale(.large)
        }
        .buttonStyle(.borderless)
        .sensoryFeedback(.impact(weight: .light), trigger: playCount)
        .accessibilityLabel(Text("Play pronunciation of \(entry.navi)"))
    }
}

#Preview {
    NavigationStack {
        WordListView(title: "Time", groups: Basics.time, grammar: .loading)
    }
}
