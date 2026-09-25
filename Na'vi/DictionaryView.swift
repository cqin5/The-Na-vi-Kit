//
//  DictionaryView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI

/// The Na'vi–English dictionary: every entry grouped by first letter, with search
/// and a letter index.
///
/// Navigation bar, search field and list take on Liquid Glass from the system on
/// iOS 26 and later; on iPhone the search field sits at the bottom of the screen.
struct DictionaryView: View {

    @State private var sections: [DictionarySection] = []
    @State private var hasLoaded = false
    @State private var query = ""
    @State private var isShowingKeyboardSetup = false

    var body: some View {
        let visibleSections = NDDictionary.filtered(sections, matching: query)

        NavigationStack {
            DictionaryList(sections: visibleSections)
                .overlay {
                    if hasLoaded && visibleSections.isEmpty && !query.isEmpty {
                        ContentUnavailableView.search(text: query)
                    }
                }
                .navigationTitle("Na'vi-English")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $query, prompt: "Look up")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Set Up Keyboard", systemImage: "keyboard") {
                            isShowingKeyboardSetup = true
                        }
                    }
                }
        }
        .sheet(isPresented: $isShowingKeyboardSetup) {
            KeyboardSetupView()
        }
        .task {
            guard !hasLoaded else {
                return
            }

            // Decoding the vocabulary takes long enough to be felt on the main
            // thread, so it runs on a background task.
            sections = await Task.detached(priority: .userInitiated) {
                NDDictionary.loadSections()
            }.value
            hasLoaded = true
        }
    }
}

// MARK: - List

/// The sections as a plain list with a letter index on the trailing edge.
private struct DictionaryList: View {

    let sections: [DictionarySection]

    var body: some View {
        if #available(iOS 26.0, *) {
            List {
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

/// A compact letter index for releases before iOS 26. Tapping a letter jumps to
/// its section.
private struct SectionIndexBar: View {

    let labels: [String]
    let select: (Int) -> Void

    var body: some View {
        VStack(spacing: 1) {
            ForEach(labels.indices, id: \.self) { index in
                Button {
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
        // The index has to fit the screen's height, so its letters stop growing
        // at the largest standard text size.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .padding(.trailing, 2)
    }
}

#Preview {
    DictionaryView()
}
