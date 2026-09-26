//
//  PronounsView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI
import NaviGrammar

/// The personal pronouns, by how many people they stand for. Choosing one shows the
/// forms its case endings make, as the grammar engine builds them.
struct PronounsView: View {

    /// The grammar engine, which builds each pronoun's forms and finds its recording
    /// once it has loaded.
    let grammar: GrammarState

    var body: some View {
        List {
            ForEach(Basics.pronouns) { group in
                Section {
                    ForEach(group.words) { word in
                        let entry = grammar.search?.dictionaryEntry(forHeadword: word.navi)
                        if let search = grammar.search, let forms = PronounForms(of: word.navi, in: search) {
                            NavigationLink {
                                PronounFormsView(word: word, forms: forms, entry: entry)
                            } label: {
                                BasicWordRow(word: word, entry: entry)
                            }
                        } else {
                            BasicWordRow(word: word, entry: entry)
                        }
                    }
                } header: {
                    Text(group.title)
                } footer: {
                    if let footer = group.footer {
                        Text(footer)
                    }
                }
            }
        }
        .navigationTitle("Pronouns")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A pronoun's form in each case, as NaviGrammar's generator makes it by the rules of
/// appendix H of the LearnNavi dictionary.
struct PronounForms: Hashable {

    struct Case: Identifiable, Hashable {
        let nounCase: NounCase
        /// Every spelling the case allows, the usual one first: oet and oeti.
        let forms: [GeneratedForm]

        var id: NounCase { nounCase }
    }

    let cases: [Case]

    /// The forms of `pronoun`, or nil when the grammar lexicon does not list it as a
    /// pronoun and so cannot inflect it.
    init?(of pronoun: String, in search: GrammarSearch) {
        let form = Orthography.normalize(pronoun)
        guard let entry = search.analyser.lexicon.entries(withForm: form).first(where: { $0.wordClasses.contains(.pronoun) }) else {
            return nil
        }
        let generator = Generator()
        cases = NounCase.regular.compactMap { nounCase in
            let forms = generator.forms(of: entry, as: .pronoun, .case(nounCase))
            return forms.isEmpty ? nil : Case(nounCase: nounCase, forms: forms)
        }
        // A pronoun that is itself a case form, such as tsaw, takes no endings.
        guard cases.count > 1 else {
            return nil
        }
    }
}

/// One pronoun's forms, case by case, with what each case is for.
private struct PronounFormsView: View {

    let word: BasicWord
    let forms: PronounForms
    let entry: NDDictionaryEntry?

    var body: some View {
        List {
            Section {
                BasicWordRow(word: word, entry: entry)
            }

            Section {
                ForEach(forms.cases) { row in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: row.forms.map(Self.label).joined(separator: ", "))
                            .font(.headline)
                        Text("\(Text(verbatim: row.nounCase.rawValue.capitalized).bold()): \(row.nounCase.explanation)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Forms")
            } footer: {
                Text("A noun or pronoun takes an ending for the part it plays in the sentence. These are the forms the rules of appendix H of the LearnNavi dictionary make.")
            }
        }
        .navigationTitle(Text(verbatim: word.navi))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// A form, with a remark where it is casual or irregular: oey (casual).
    private static func label(_ form: GeneratedForm) -> String {
        if form.notes.contains(.casualGenitive) {
            return "\(form.text) (casual)"
        }
        if form.notes.contains(.irregularGenitive) {
            return "\(form.text) (irregular)"
        }
        return form.text
    }
}

#Preview {
    NavigationStack {
        PronounsView(grammar: .loading)
    }
}
