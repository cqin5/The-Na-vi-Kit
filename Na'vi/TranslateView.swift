//
//  TranslateView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI
import NaviGrammar

/// Reads a passage of Na'vi word by word: for each word, the word it comes from,
/// that word's meaning and the grammar of the form. Words the dictionary does not
/// know are marked rather than guessed at, and every reading of an ambiguous word is
/// listed. The text never leaves the device.
struct TranslateView: View {

    let grammar: GrammarSearch

    @State private var text: String
    @State private var reading: Reading?
    /// Counts pastes and clears, which replace the whole passage. Each plays a
    /// light tap.
    @State private var replacements = 0

    /// - Parameter text: text to read straight away, such as a phrase from the phrasebook.
    init(grammar: GrammarSearch, text: String = "") {
        self.grammar = grammar
        _text = State(initialValue: text)
    }

    var body: some View {
        List {
            Section {
                TextField("Paste or type Na'vi", text: $text, axis: .vertical)
                    .lineLimit(3...10)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Na'vi text")

                HStack {
                    PasteButton(payloadType: String.self) { strings in
                        if let pasted = strings.first {
                            text = pasted
                            replacements += 1
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonBorderShape(.capsule)

                    Spacer()

                    Button("Clear", systemImage: "xmark.circle", role: .destructive) {
                        text = ""
                        replacements += 1
                    }
                    .labelStyle(.iconOnly)
                    .disabled(text.isEmpty)
                }
                .buttonStyle(.borderless)
                .sensoryFeedback(.impact(weight: .light), trigger: replacements)
            } footer: {
                Text("Each word is looked up and taken apart on this device.")
            }

            if let reading, !reading.words.isEmpty {
                Section {
                    ForEach(reading.words) { word in
                        ReadingWordRow(word: word, phrase: reading.phrase(startingAt: word.id))
                    }
                } header: {
                    Text(summary(of: reading))
                }
            }

            SourcesSection(metadata: grammar.analyser.lexicon.metadata)
        }
        .navigationTitle("Translate")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: text) {
            // Wait for typing to pause, then read off the main thread.
            do {
                try await Task.sleep(for: .milliseconds(200))
            } catch {
                return
            }
            let reader = grammar.reader
            let passage = text
            let result = await Task.detached(priority: .userInitiated) {
                reader.read(passage)
            }.value
            if !Task.isCancelled {
                reading = result
            }
        }
    }

    private func summary(of reading: Reading) -> String {
        let unknown = reading.unknownWords.count
        let words = reading.words.count == 1 ? "1 word" : "\(reading.words.count) words"
        return unknown == 0 ? words : "\(words), \(unknown) not in the dictionary"
    }
}

/// The Translate screen once the grammar engine has loaded, which it does just after
/// the vocabulary when the app opens. Until then the screen shows its progress, and
/// if the engine cannot be loaded, says so.
struct TranslateScreen: View {

    let grammar: GrammarState
    /// Text to read straight away, such as a phrase from the phrasebook.
    var text = ""

    var body: some View {
        switch grammar {
        case .ready(let search):
            TranslateView(grammar: search, text: text)
        case .loading:
            ProgressView()
                .navigationTitle("Translate")
                .navigationBarTitleDisplayMode(.inline)
        case .unavailable:
            ContentUnavailableView(
                "Translation Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text("The grammar data that Translate needs could not be loaded.")
            )
            .navigationTitle("Translate")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Words

/// One word of the passage and its readings.
private struct ReadingWordRow: View {

    let word: ReadingWord
    /// The multi-word dictionary entry that starts with this word, if any.
    let phrase: PhraseMatch?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: word.text)
                .font(.headline)

            if let best = word.analysis.analyses.first {
                ReadingView(analysis: best)
                let others = word.analysis.analyses.dropFirst()
                if !others.isEmpty {
                    OtherReadings(analyses: Array(others))
                }
            } else {
                UnknownWordLabel(reason: word.analysis.unknownReason)
            }

            if let phrase, let best = phrase.analyses.first {
                PhraseLabel(analysis: best)
            }
        }
        .padding(.vertical, 2)
    }
}

/// A reading: the base word and its meaning, then how the form is built.
private struct ReadingView: View {

    let analysis: Analysis

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(Text(verbatim: analysis.baseWord).bold())  \(analysis.entry.gloss)")
                .font(.subheadline)

            if !analysis.features.isEmpty {
                Text(verbatim: analysis.features.map(\.label).joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.tint)
                Text(verbatim: analysis.features.map(\.explanation).filter { !$0.isEmpty }.joined(separator: "; "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(analysis.remarks, id: \.self) { remark in
                Text(verbatim: remark)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The other readings of an ambiguous word, most likely first.
private struct OtherReadings: View {

    let analyses: [Analysis]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Also possible")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(analyses) { analysis in
                Text(verbatim: "\(analysis.summary) — \(analysis.entry.gloss)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A multi-word dictionary entry that begins with this word, such as irayo si.
private struct PhraseLabel: View {

    let analysis: Analysis

    var body: some View {
        IconLabel {
            Image(systemName: "link")
        } content: {
            Text(verbatim: "\(analysis.summary) — \(analysis.entry.gloss)")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .accessibilityLabel(Text("Phrase: \(analysis.summary), \(analysis.entry.gloss)"))
    }
}

/// Marks a word the dictionary does not know, and says why.
private struct UnknownWordLabel: View {

    let reason: UnknownReason?

    var body: some View {
        IconLabel {
            Image(systemName: "questionmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Not in the dictionary")
                    .font(.subheadline.weight(.semibold))
                Text(explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var explanation: String {
        switch reason {
        case .notNaviSpelling:
            "It uses letters Na'vi does not use, as a name or a word from another language might."
        case .notFound, .empty, nil:
            "No dictionary word, with the endings, prefixes and infixes this app knows, makes this form. It may be a name, a newer word, or a form the rules here do not cover."
        }
    }
}

/// An icon beside its text, or above it at the accessibility text sizes, where
/// text flowing around an icon beside it becomes hard to read.
private struct IconLabel<Icon: View, Content: View>: View {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let icon: Icon
    private let content: Content

    init(@ViewBuilder icon: () -> Icon, @ViewBuilder content: () -> Content) {
        self.icon = icon()
        self.content = content()
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        layout {
            icon
            // Without this, the layout can hold the text to one line and truncate it.
            content
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Sources

/// Where the words and the grammar come from.
private struct SourcesSection: View {

    let metadata: [String: String]

    var body: some View {
        Section("Sources") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Words, meanings and the grammar of their endings and infixes come from the LearnNavi Na'vi dictionary, compiled by Roland “Tìtstewan” R. S. and others and originally created by Richard Littauer. Where that dictionary leaves a rule out, the app follows Dr. Paul Frommer's own usage on naviteri.org.")
                Text("The Na'vi language was created by Dr. Paul Frommer.")
                if let retrieved = metadata["retrieved"] {
                    Text("Dictionary data retrieved \(retrieved).")
                        .foregroundStyle(.secondary)
                }
                Text("Readings are worked out by rule. A form the rules do not produce is marked as unknown, never guessed.")
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
            .padding(.vertical, 4)
        }
    }
}
