//
//  WordFormRow.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI
import NaviGrammar

/// An inflected form found by search: the analysis on one line — "oel → oe +
/// agentive" — above the base word's dictionary entry.
struct WordFormRow: View {

    let match: WordFormMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: match.line)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                .accessibilityLabel(Text(verbatim: match.spokenLine))

            ForEach(match.analysis.remarks, id: \.self) { remark in
                Text(verbatim: remark)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if match.entries.isEmpty {
                // The app's vocabulary does not have the base word; the grammar
                // lexicon's own definition stands in.
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: match.analysis.baseWord)
                        .font(.headline)
                    Text(verbatim: match.analysis.entry.partsOfSpeech.map(\.name).joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(verbatim: match.analysis.entry.gloss)
                }
                .accessibilityElement(children: .combine)
                .padding(.vertical, 4)
            } else {
                ForEach(match.entries) { entry in
                    DictionaryEntryRow(entry: entry)
                }
            }
        }
    }
}
