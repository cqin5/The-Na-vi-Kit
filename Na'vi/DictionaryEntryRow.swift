//
//  DictionaryEntryRow.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI

/// One dictionary entry: the Na'vi headword, its pronunciation and part of speech,
/// the English meaning, and a button that plays the recorded pronunciation.
///
/// Text styles scale with the reader's text size setting, and semantic colours
/// follow Dark Mode and Increase Contrast.
struct DictionaryEntryRow: View {

    let entry: NDDictionaryEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.navi)
                    .font(.headline)

                Text(verbatim: "\(entry.ipa)  \(entry.partOfSpeech)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(entry.english)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            // Borderless, so tapping elsewhere in the row doesn't trigger playback.
            Button {
                PronunciationPlayer.shared.play(fileNamed: entry.localAudioFileName)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Play pronunciation of \(entry.navi)"))
        }
        .padding(.vertical, 4)
    }
}
