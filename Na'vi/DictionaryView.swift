//
//  DictionaryView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI

/// The Na'vi–English dictionary: every entry grouped by first letter, with a letter
/// index. Looking a word up has a tab of its own, `DictionarySearchView`.
///
/// Navigation bar and list take on Liquid Glass from the system on iOS 26 and later.
struct DictionaryView: View {

    let sections: [DictionarySection]

    var body: some View {
        DictionaryList(sections: sections, wordForms: [])
            .navigationTitle("Na'vi-English")
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// Looks a word up in the dictionary, in Na'vi or English. Searching for an
/// inflected word, such as oel, also lists the entry of the word it comes from,
/// with the grammar of the form.
///
/// It fills the tab bar's search tab. On iOS 26 and later the search field sits at
/// the bottom of the screen, so while typing it rests on top of the keyboard.
struct DictionarySearchView: View {

    let sections: [DictionarySection]
    /// Whether the vocabulary has loaded, so that an empty list means no results.
    let hasLoaded: Bool
    /// The grammar engine, which reads the search text as an inflected word, once
    /// it has loaded.
    let grammar: GrammarSearch?

    @State private var query = ""

    var body: some View {
        // A query of only spaces matches everything, so it counts as no query.
        let isEmptyQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let visibleSections = isEmptyQuery ? [] : NDDictionary.filtered(sections, matching: query)
        let wordForms = grammar?.wordForms(matching: query) ?? []

        DictionaryList(sections: visibleSections, wordForms: wordForms)
            .overlay {
                if isEmptyQuery {
                    ContentUnavailableView(
                        "Look Up a Word",
                        systemImage: "character.book.closed",
                        description: Text("Type a word in Na'vi or in English.")
                    )
                } else if hasLoaded && visibleSections.isEmpty && wordForms.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Look up")
    }
}

// MARK: - List

/// The sections as a plain list with a letter index on the trailing edge, after
/// any inflected forms the search text was read as.
private struct DictionaryList: View {

    let sections: [DictionarySection]
    let wordForms: [WordFormMatch]

    var body: some View {
        if #available(iOS 26.0, *) {
            List {
                WordFormSection(matches: wordForms)
                ForEach(sections) { section in
                    Section {
                        ForEach(section.entries) { entry in
                            DictionaryEntryRow(entry: entry)
                        }
                    } header: {
                        Text(verbatim: section.indexLabel)
                    }
                    .sectionIndexLabel(Text(verbatim: section.indexLabel))
                }
            }
            .listStyle(.plain)
            .listSectionIndexVisibility(.visible)
        } else {
            // SwiftUI's section index arrived in iOS 26, so earlier releases get a
            // compact index of their own.
            ScrollViewReader { proxy in
                List {
                    WordFormSection(matches: wordForms)
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.entries) { entry in
                                DictionaryEntryRow(entry: entry)
                            }
                        } header: {
                            Text(verbatim: section.indexLabel)
                        }
                        .id(section.id)
                    }
                }
                .listStyle(.plain)
                .safeAreaInset(edge: .trailing, spacing: 0) {
                    SectionIndexBar(labels: sections.map(\.indexLabel)) { index in
                        proxy.scrollTo(sections[index].id, anchor: .top)
                    }
                }
            }
        }
    }
}

/// The inflected forms the search text was read as, above the ordinary results.
private struct WordFormSection: View {

    let matches: [WordFormMatch]

    var body: some View {
        if !matches.isEmpty {
            Section {
                ForEach(matches) { match in
                    WordFormRow(match: match)
                }
            } header: {
                Text("Word Forms")
            }
        }
    }
}

/// A compact letter index for releases before iOS 26. Tapping a letter jumps to
/// its section.
private struct SectionIndexBar: View {

    let labels: [String]
    let select: (Int) -> Void

    /// Counts jumps. Each plays a selection tick, the haptic for moving between
    /// discrete values.
    @State private var jumps = 0

    var body: some View {
        VStack(spacing: 1) {
            ForEach(labels.indices, id: \.self) { index in
                Button {
                    jumps += 1
                    select(index)
                } label: {
                    Text(verbatim: labels[index])
                        .font(.caption2.weight(.semibold))
                        .frame(width: 20, height: 16)
                        .contentShape(Rectangle())
                }
            }
        }
        .buttonStyle(.borderless)
        .sensoryFeedback(.selection, trigger: jumps)
        // The index has to fit the screen's height, so its letters stop growing
        // at the largest standard text size.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .padding(.trailing, 2)
    }
}

#Preview("Dictionary") {
    NavigationStack {
        DictionaryView(sections: NDDictionary.loadSections())
    }
}

#Preview("Search") {
    let sections = NDDictionary.loadSections()
    NavigationStack {
        DictionarySearchView(sections: sections, hasLoaded: true, grammar: GrammarSearch.load(sections: sections))
    }
}
