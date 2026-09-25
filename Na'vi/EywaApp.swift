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
            DictionaryView()
        }
    }
}
