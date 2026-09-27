//
//  DictionaryEntryRow.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI

/// One dictionary entry: the Na'vi headword, its pronunciation and part of speech,
/// the English meaning, and a button that plays the recorded pronunciation. Entries
/// without a written pronunciation or a recording leave those out.
///
/// Text styles scale with the reader's text size setting, and semantic colours
/// follow Dark Mode and Increase Contrast.
struct DictionaryEntryRow: View {

    let entry: NDDictionaryEntry

    /// Counts taps on the play button. Each plays a light tap, felt at once,
    /// while the recording takes a moment to start.
    @State private var playCount = 0

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.navi)
                    .font(.headline)

                Text(verbatim: [entry.ipa, entry.partOfSpeech].filter { !$0.isEmpty }.joined(separator: "  "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(entry.english)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            if entry.hasRecording {
                // Borderless, so tapping elsewhere in the row doesn't trigger playback.
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
        .padding(.vertical, 4)
    }
}
