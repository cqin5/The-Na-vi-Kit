//
//  Basics.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

/// A word to learn and what it means. The Na'vi is spelled as the LearnNavi
/// dictionary spells it, and the pre-flight checks confirm that the dictionary has
/// it; the English is our own.
struct BasicWord: Identifiable, Hashable, Sendable {

    let navi: String
    let english: String
    /// How the word is built, or a note on its use.
    var note: String?

    var id: String { navi }
}

/// Words that belong together, shown as one section.
struct WordGroup: Identifiable, Hashable, Sendable {

    let title: String
    let words: [BasicWord]
    /// A remark on the group as a whole, such as how its words are built.
    var footer: String?

    var id: String { title }
}

/// One of the 33 letters of the Na'vi alphabet in appendix G of the LearnNavi
/// dictionary, and how it sounds.
struct NaviLetter: Identifiable, Hashable, Sendable {

    /// The letter as it is written: px, ll, '.
    let letter: String
    /// The letter's name in appendix G, where that is more than the letter itself.
    var name: String?
    /// The sound in the phonetic notation the dictionary uses.
    let ipa: String
    /// How to make the sound, compared with English where English has it.
    let sound: String
    /// A word with the sound, which the dictionary has a recording of.
    let example: BasicWord

    var id: String { letter }
}

struct LetterGroup: Identifiable, Hashable, Sendable {

    let title: String
    let letters: [NaviLetter]
    var footer: String?

    var id: String { title }
}

/// The words a learner needs first, for the phrasebook's Basics pages. Numbers are
/// built by NaviGrammar's `Numeral`, from appendix A of the dictionary.
enum Basics {

    // MARK: - Pronunciation

    /// The letters of appendix G, "The Alphabet", in its order within each group.
    static let alphabet: [LetterGroup] = [
        LetterGroup(title: "Vowels", letters: [
            NaviLetter(letter: "a", ipa: "a", sound: "a as in father",
                       example: BasicWord(navi: "atan", english: "light")),
            NaviLetter(letter: "ä", ipa: "æ", sound: "a as in cat",
                       example: BasicWord(navi: "kinä", english: "seven")),
            NaviLetter(letter: "e", ipa: "ɛ", sound: "e as in bet",
                       example: BasicWord(navi: "eltu", english: "brain")),
            NaviLetter(letter: "i", ipa: "i", sound: "i as in machine",
                       example: BasicWord(navi: "ikran", english: "banshee")),
            NaviLetter(letter: "ì", ipa: "ɪ", sound: "i as in bit",
                       example: BasicWord(navi: "kaltxì", english: "hello")),
            NaviLetter(letter: "o", ipa: "o", sound: "o as in go, without sliding into a w",
                       example: BasicWord(navi: "oe", english: "I, me")),
            NaviLetter(letter: "u", ipa: "u", sound: "oo as in food, or in some words u as in put",
                       example: BasicWord(navi: "utral", english: "tree")),
        ], footer: "Every vowel is sounded. Two vowels side by side belong to separate syllables: oe, I, is o-e."),
        LetterGroup(title: "Diphthongs", letters: [
            NaviLetter(letter: "aw", ipa: "aw", sound: "ow as in cow",
                       example: BasicWord(navi: "awnga", english: "we")),
            NaviLetter(letter: "ay", ipa: "aj", sound: "y as in my",
                       example: BasicWord(navi: "pay", english: "water")),
            NaviLetter(letter: "ew", ipa: "ɛw", sound: "e as in bet, gliding into a w",
                       example: BasicWord(navi: "kew", english: "zero")),
            NaviLetter(letter: "ey", ipa: "ɛj", sound: "ey as in hey",
                       example: BasicWord(navi: "Eywa", english: "the world spirit")),
        ], footer: "A diphthong is one syllable: one vowel gliding into another."),
        LetterGroup(title: "Pseudovowels", letters: [
            NaviLetter(letter: "ll", name: "'ll", ipa: "ḷ", sound: "an l that forms a syllable, as in bottle",
                       example: BasicWord(navi: "plltxe", english: "speak")),
            NaviLetter(letter: "rr", name: "'rr", ipa: "ṛ", sound: "a rolled r that forms a syllable",
                       example: BasicWord(navi: "trr", english: "day")),
        ], footer: "ll and rr take the place of a vowel: trr, day, is one syllable, and plltxe, speak, is two."),
        LetterGroup(title: "Ejectives", letters: [
            NaviLetter(letter: "kx", name: "kxekx", ipa: "k’", sound: "k with a pop",
                       example: BasicWord(navi: "kxetse", english: "tail")),
            NaviLetter(letter: "px", name: "pxepx", ipa: "p’", sound: "p with a pop",
                       example: BasicWord(navi: "pxey", english: "three")),
            NaviLetter(letter: "tx", name: "txetx", ipa: "t’", sound: "t with a pop",
                       example: BasicWord(navi: "txon", english: "night")),
        ], footer: "English has no sounds like these. Close your throat, as if holding your breath, and the air trapped behind your lips or tongue comes out in a sharp pop."),
        LetterGroup(title: "Other Consonants", letters: [
            NaviLetter(letter: "'", name: "tìftang", ipa: "ʔ", sound: "the catch in the throat in uh-oh",
                       example: BasicWord(navi: "'aw", english: "one")),
            NaviLetter(letter: "f", name: "fä", ipa: "f", sound: "f as in fun",
                       example: BasicWord(navi: "fìtrr", english: "today")),
            NaviLetter(letter: "h", name: "hä", ipa: "h", sound: "h as in hat",
                       example: BasicWord(navi: "hufwe", english: "wind")),
            NaviLetter(letter: "k", name: "kek", ipa: "k", sound: "k as in skin, without a puff of air",
                       example: BasicWord(navi: "kelku", english: "home")),
            NaviLetter(letter: "l", name: "lel", ipa: "l", sound: "l as in let",
                       example: BasicWord(navi: "lu", english: "be")),
            NaviLetter(letter: "m", name: "mem", ipa: "m", sound: "m as in man",
                       example: BasicWord(navi: "mune", english: "two")),
            NaviLetter(letter: "n", name: "nen", ipa: "n", sound: "n as in no",
                       example: BasicWord(navi: "nari", english: "eye")),
            NaviLetter(letter: "ng", name: "ngeng", ipa: "ŋ", sound: "ng as in sing, even at the start of a word",
                       example: BasicWord(navi: "nga", english: "you")),
            NaviLetter(letter: "p", name: "pep", ipa: "p", sound: "p as in spin, without a puff of air",
                       example: BasicWord(navi: "po", english: "he, she")),
            NaviLetter(letter: "r", name: "rer", ipa: "ɾ", sound: "a tapped r, like the tt in American better",
                       example: BasicWord(navi: "rutxe", english: "please")),
            NaviLetter(letter: "s", name: "sä", ipa: "s", sound: "s as in sun",
                       example: BasicWord(navi: "sìltsan", english: "good")),
            NaviLetter(letter: "t", name: "tet", ipa: "t", sound: "t as in stop, without a puff of air",
                       example: BasicWord(navi: "tute", english: "person")),
            NaviLetter(letter: "ts", name: "tsä", ipa: "t͡s", sound: "ts as in cats, even at the start of a word",
                       example: BasicWord(navi: "tsaheylu", english: "bond")),
            NaviLetter(letter: "v", name: "vä", ipa: "v", sound: "v as in very",
                       example: BasicWord(navi: "vol", english: "eight")),
            NaviLetter(letter: "w", name: "wä", ipa: "w", sound: "w as in wet",
                       example: BasicWord(navi: "way", english: "song")),
            NaviLetter(letter: "y", name: "yä", ipa: "j", sound: "y as in yes",
                       example: BasicWord(navi: "yawne", english: "beloved")),
            NaviLetter(letter: "z", name: "zä", ipa: "z", sound: "z as in zoo",
                       example: BasicWord(navi: "zam", english: "sixty-four")),
        ], footer: "At the end of a word, p, t and k are held rather than released, as in set, now."),
    ]

    // MARK: - Numbers

    /// The names of the digits 8 and 9, which appendix A gives for numbers such as
    /// phone numbers. They are not the values eight and nine.
    static let digitNames: [BasicWord] = [
        BasicWord(navi: "'eyt", english: "the digit 8"),
        BasicWord(navi: "nayn", english: "the digit 9"),
    ]

    /// Phrases from appendix F that use numbers.
    static let numberPhrases: [Phrase] = [
        Phrase(navi: "Ngari solalew polpxaya zìsìt?", english: "How old are you?",
               note: "Literally, as for you, how many years have gone by?"),
        Phrase(navi: "Oeri solalew zìsìt apxevol", english: "I'm 24 years old",
               note: "pxevol is three eights. Literally, as for me, twenty-four years have gone by."),
    ]

    // MARK: - Time

    static let time: [WordGroup] = [
        WordGroup(title: "Today and Tomorrow", words: [
            BasicWord(navi: "set", english: "now"),
            BasicWord(navi: "fìtrr", english: "today"),
            BasicWord(navi: "trram", english: "yesterday"),
            BasicWord(navi: "trray", english: "tomorrow"),
            BasicWord(navi: "fìtxon", english: "tonight"),
            BasicWord(navi: "txonam", english: "last night"),
            BasicWord(navi: "txonay", english: "tomorrow night"),
            BasicWord(navi: "ye'rìn", english: "soon"),
            BasicWord(navi: "tsakrr", english: "then, at that time"),
        ], footer: "fì- means this: fìtrr is this day. -am means the one before and -ay the one after: trram, yesterday, and trray, tomorrow."),
        WordGroup(title: "Days of the Week", words: [
            BasicWord(navi: "trr'awve", english: "Sunday"),
            BasicWord(navi: "trrmuve", english: "Monday"),
            BasicWord(navi: "trrpxeyve", english: "Tuesday"),
            BasicWord(navi: "trrtsìve", english: "Wednesday"),
            BasicWord(navi: "trrmrrve", english: "Thursday"),
            BasicWord(navi: "trrpuve", english: "Friday"),
            BasicWord(navi: "trrkive", english: "Saturday"),
            BasicWord(navi: "trrpeve", english: "which day?"),
        ], footer: "Names made for Earth's week: trr, day, with an ordinal, so trr'awve, Sunday, is the first day. trrpeve asks which one."),
        WordGroup(title: "Weeks, Months and Years", words: [
            BasicWord(navi: "kintrr", english: "week"),
            BasicWord(navi: "kintrram", english: "last week"),
            BasicWord(navi: "kintrray", english: "next week"),
            BasicWord(navi: "vospxì", english: "month"),
            BasicWord(navi: "vospxìam", english: "last month"),
            BasicWord(navi: "vospxìay", english: "next month"),
            BasicWord(navi: "zìsìt", english: "year"),
            BasicWord(navi: "zìsìtay", english: "next year"),
        ], footer: "Only words for time take -am and -ay."),
    ]

    /// The Pandoran day of appendix B of the dictionary, from dawn round to dawn.
    static let timesOfDay: [WordGroup] = [
        WordGroup(title: "Day", words: [
            BasicWord(navi: "trr'ong", english: "dawn"),
            BasicWord(navi: "trr'ongmaw", english: "just after dawn"),
            BasicWord(navi: "rewon", english: "morning"),
            BasicWord(navi: "srekamtrr", english: "before noon"),
            BasicWord(navi: "kxamtrr", english: "noon"),
            BasicWord(navi: "kxamtrrmaw", english: "just after noon"),
            BasicWord(navi: "ha'ngir", english: "afternoon"),
            BasicWord(navi: "kaym", english: "late afternoon, evening"),
            BasicWord(navi: "sreton'ong", english: "before nightfall"),
        ]),
        WordGroup(title: "Night", words: [
            BasicWord(navi: "txon'ong", english: "nightfall"),
            BasicWord(navi: "txon'ongmaw", english: "twilight", note: "After nightfall, before full dark."),
            BasicWord(navi: "txon", english: "night"),
            BasicWord(navi: "srekamtxon", english: "before midnight"),
            BasicWord(navi: "kxamtxon", english: "midnight"),
            BasicWord(navi: "kxamtxomaw", english: "after midnight"),
            BasicWord(navi: "sresrr'ong", english: "before dawn"),
        ], footer: "kxam is middle, so kxamtrr, the middle of the day, is noon. sre+ means before and maw after, and sre+ softens the sound that follows it: srekamtrr is the time before noon."),
    ]

    // MARK: - Pronouns

    static let pronouns: [WordGroup] = [
        WordGroup(title: "One Person", words: [
            BasicWord(navi: "oe", english: "I, me"),
            BasicWord(navi: "nga", english: "you"),
            BasicWord(navi: "po", english: "he, she"),
            BasicWord(navi: "poan", english: "he", note: "Where it matters that he is male."),
            BasicWord(navi: "poe", english: "she", note: "Where it matters that she is female."),
        ]),
        WordGroup(title: "Two People", words: [
            BasicWord(navi: "moe", english: "we two, not you"),
            BasicWord(navi: "oeng", english: "you and I"),
            BasicWord(navi: "menga", english: "you two"),
            BasicWord(navi: "mefo", english: "they two"),
        ]),
        WordGroup(title: "Three People", words: [
            BasicWord(navi: "pxoe", english: "we three, not you"),
            BasicWord(navi: "pxoeng", english: "we three, with you"),
            BasicWord(navi: "pxenga", english: "you three"),
            BasicWord(navi: "pxefo", english: "they three"),
        ]),
        WordGroup(title: "More People", words: [
            BasicWord(navi: "ayoe", english: "we, not you"),
            BasicWord(navi: "ayoeng", english: "we, with you"),
            BasicWord(navi: "awnga", english: "we, with you", note: "Another word for ayoeng."),
            BasicWord(navi: "aynga", english: "you all"),
            BasicWord(navi: "ayfo", english: "they"),
            BasicWord(navi: "fo", english: "they", note: "Short for ayfo."),
        ], footer: "Na'vi has two kinds of we: one that includes the person spoken to, and one that leaves them out."),
        WordGroup(title: "Respectful Forms", words: [
            BasicWord(navi: "ngenga", english: "you", note: "To someone you honour."),
            BasicWord(navi: "ohe", english: "I", note: "Deferential or ceremonial."),
            BasicWord(navi: "oheng", english: "you and I", note: "Honorific."),
            BasicWord(navi: "pohan", english: "he", note: "Honorific."),
            BasicWord(navi: "pohe", english: "she", note: "Honorific."),
        ]),
        WordGroup(title: "Oneself", words: [
            BasicWord(navi: "sno", english: "himself, herself, itself", note: "Points back to the subject. His or her own is sneyä."),
        ]),
    ]

    // MARK: - Questions

    static let questions: [WordGroup] = [
        WordGroup(title: "Question Words", words: [
            BasicWord(navi: "pesu", english: "who?"),
            BasicWord(navi: "tupe", english: "who?"),
            BasicWord(navi: "peu", english: "what? (a thing)"),
            BasicWord(navi: "'upe", english: "what? (a thing)"),
            BasicWord(navi: "pehem", english: "what? (an action)"),
            BasicWord(navi: "kempe", english: "what? (an action)"),
            BasicWord(navi: "peseng", english: "where?"),
            BasicWord(navi: "tsengpe", english: "where?"),
            BasicWord(navi: "pehrr", english: "when?"),
            BasicWord(navi: "krrpe", english: "when?"),
            BasicWord(navi: "pelun", english: "why?"),
            BasicWord(navi: "lumpe", english: "why?"),
            BasicWord(navi: "pefya", english: "how?"),
            BasicWord(navi: "fyape", english: "how?"),
            BasicWord(navi: "polpxay", english: "how many?"),
            BasicWord(navi: "holpxaype", english: "how many?"),
            BasicWord(navi: "pìmtxan", english: "how much?"),
            BasicWord(navi: "hìmtxampe", english: "how much?"),
            BasicWord(navi: "pefnel", english: "what kind?"),
            BasicWord(navi: "fnepe", english: "what kind?"),
        ], footer: "Most question words come in pairs that mean the same: pe+ at the front of a word or -pe at its end. tseng, place, gives peseng and tsengpe, where; pe+ softens the sound after it."),
        WordGroup(title: "Yes or No", words: [
            BasicWord(navi: "srak", english: "yes or no?", note: "Ends a question: Ngaru lu fpom srak?"),
            BasicWord(navi: "srake", english: "yes or no?", note: "Begins a question instead."),
            BasicWord(navi: "kefyak", english: "isn't it? right?"),
            BasicWord(navi: "srane", english: "yes"),
            BasicWord(navi: "kehe", english: "no"),
        ]),
    ]
}
