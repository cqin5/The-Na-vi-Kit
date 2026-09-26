//
//  PhrasebookView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI

/// Everyday phrases and sayings, by topic. Choosing one reads it word by word.
struct PhrasebookView: View {

    /// The grammar engine, which reads a chosen phrase. The phrases themselves are
    /// listed before it has loaded.
    let grammar: GrammarState

    var body: some View {
        List {
            ForEach(Phrasebook.topics) { topic in
                Section(topic.title) {
                    ForEach(topic.phrases) { phrase in
                        NavigationLink {
                            TranslateScreen(grammar: grammar, text: phrase.navi)
                        } label: {
                            PhraseRow(phrase: phrase)
                        }
                    }
                }
            }

            Section {
                Text("The Na'vi phrases are those of appendix F of the LearnNavi dictionary, most of which come from Dr. Paul Frommer's blog, naviteri.org. The English renderings are this app's.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Phrasebook")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PhraseRow: View {

    let phrase: Phrase

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: phrase.navi)
                .font(.headline)
            Text(verbatim: phrase.english)
                .font(.subheadline)
            if let note = phrase.note {
                Text(verbatim: note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .padding(.vertical, 2)
    }
}
