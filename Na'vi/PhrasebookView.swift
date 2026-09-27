//
//  PhrasebookView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI

/// The phrasebook: the basics a learner needs first, such as pronunciation and
/// numbers, then everyday phrases by topic. Each page and each topic has a screen of
/// its own, so that the list stays short enough to take in at a glance.
struct PhrasebookView: View {

    /// The grammar engine, which reads a chosen phrase and finds each word's
    /// recording. Everything is listed before it has loaded.
    let grammar: GrammarState

    var body: some View {
        List {
            Section("Basics") {
                ForEach(BasicsPage.allCases) { page in
                    NavigationLink {
                        destination(for: page)
                    } label: {
                        BasicsPageLabel(page: page)
                    }
                }
            }

            Section("Phrases") {
                ForEach(Phrasebook.topics) { topic in
                    NavigationLink {
                        PhraseTopicView(topic: topic, grammar: grammar)
                    } label: {
                        LabeledContent {
                            Text(topic.phrases.count, format: .number)
                        } label: {
                            Label(topic.title, systemImage: topic.symbol)
                        }
                    }
                }
            }

            Section {
                Text("The phrases are those of appendix F of the LearnNavi dictionary, most of which come from Dr. Paul Frommer's blog, naviteri.org. The numbers, the times of day and the alphabet follow appendices A, B and G, and every word is in the dictionary. The English renderings are this app's.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Phrasebook")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func destination(for page: BasicsPage) -> some View {
        switch page {
        case .pronunciation:
            PronunciationView(grammar: grammar)
        case .numbers:
            NumbersView(grammar: grammar)
        case .time:
            WordListView(title: page.title, groups: Basics.time, grammar: grammar)
        case .timesOfDay:
            WordListView(title: page.title, groups: Basics.timesOfDay, grammar: grammar)
        case .pronouns:
            PronounsView(grammar: grammar)
        case .questions:
            WordListView(title: page.title, groups: Basics.questions, grammar: grammar)
        }
    }
}

/// The pages of the Basics section, in the order they are listed.
private enum BasicsPage: CaseIterable, Identifiable {
    case pronunciation
    case numbers
    case time
    case timesOfDay
    case pronouns
    case questions

    var id: Self { self }

    var title: String {
        switch self {
        case .pronunciation: "Pronunciation"
        case .numbers: "Numbers"
        case .time: "Time"
        case .timesOfDay: "Times of Day"
        case .pronouns: "Pronouns"
        case .questions: "Questions"
        }
    }

    var subtitle: String {
        switch self {
        case .pronunciation: "The 33 letters and how they sound"
        case .numbers: "Counting in eights, with a converter"
        case .time: "Today, weekdays, months and years"
        case .timesOfDay: "Pandora's day, from dawn to midnight"
        case .pronouns: "I, you, we, and the forms they take"
        case .questions: "Who, what, where, and yes or no"
        }
    }

    var symbol: String {
        switch self {
        case .pronunciation: "mouth"
        case .numbers: "number"
        case .time: "calendar"
        case .timesOfDay: "sun.horizon"
        case .pronouns: "person.2"
        case .questions: "questionmark.bubble"
        }
    }
}

/// A Basics page's name, with a line on what it covers.
private struct BasicsPageLabel: View {

    let page: BasicsPage

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(page.title)
                Text(page.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: page.symbol)
        }
    }
}

/// The phrases of one topic. Choosing one reads it word by word.
struct PhraseTopicView: View {

    let topic: PhraseTopic
    /// The grammar engine, which reads a chosen phrase.
    let grammar: GrammarState

    var body: some View {
        List {
            Section {
                ForEach(topic.phrases) { phrase in
                    NavigationLink {
                        TranslateScreen(grammar: grammar, text: phrase.navi)
                    } label: {
                        PhraseRow(phrase: phrase)
                    }
                }
            } footer: {
                Text("Choose a phrase to read it word by word.")
            }
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A phrase, what it means, and any note on it.
struct PhraseRow: View {

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

#Preview {
    NavigationStack {
        PhrasebookView(grammar: .loading)
    }
}
