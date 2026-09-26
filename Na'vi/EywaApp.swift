//
//  EywaApp.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI

/// The app's entry point. SwiftUI's app life cycle is scene-based, which the iOS 27
/// SDK requires, so no application or scene delegate is needed.
@main
struct EywaApp: App {

    var body: some Scene {
        WindowGroup {
            AppTabView()
        }
    }
}

// MARK: - Tabs

/// The app's tabs, stored by name so that a restored scene reopens on the tab last used.
enum AppTab: String {
    case dictionary
    case translate
    case phrasebook
    case settings
}

/// The dictionary, the Translate screen, the phrasebook and settings, each in a tab
/// with a navigation stack of its own. The vocabulary and the grammar engine load
/// here, once, because three of the tabs need them.
///
/// The tab bar takes on Liquid Glass from the system on iOS 26 and later.
struct AppTabView: View {

    @SceneStorage("selectedTab") private var selection = AppTab.dictionary
    @State private var sections: [DictionarySection] = []
    @State private var hasLoaded = false
    @State private var grammar = GrammarState.loading

    var body: some View {
        TabView(selection: $selection) {
            Tab("Dictionary", systemImage: "character.book.closed", value: AppTab.dictionary) {
                NavigationStack {
                    DictionaryView(sections: sections, hasLoaded: hasLoaded, grammar: grammar.search)
                }
            }

            Tab("Translate", systemImage: "translate", value: AppTab.translate) {
                NavigationStack {
                    TranslateScreen(grammar: grammar)
                }
            }

            Tab("Phrasebook", systemImage: "quote.bubble", value: AppTab.phrasebook) {
                NavigationStack {
                    PhrasebookView(grammar: grammar)
                }
            }

            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    KeyboardSetupView()
                }
            }
        }
        .task {
            guard !hasLoaded else {
                return
            }

            // Decoding the vocabulary takes long enough to be felt on the main
            // thread, so it runs on a background task, and so does loading the
            // grammar engine, which needs the vocabulary to find base entries.
            let loaded = await Task.detached(priority: .userInitiated) {
                NDDictionary.loadSections()
            }.value
            sections = loaded
            hasLoaded = true
            let search = await Task.detached(priority: .userInitiated) {
                GrammarSearch.load(sections: loaded)
            }.value
            grammar = search.map { GrammarState.ready($0) } ?? .unavailable
        }
    }
}

#Preview {
    AppTabView()
}
