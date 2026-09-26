//
//  Phrasebook.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

/// A phrase and what it means. The Na'vi is as appendix F of the LearnNavi
/// dictionary gives it, most of it from Dr. Paul Frommer's blog; the English is our
/// own. The pre-flight checks confirm that every phrase appears in appendix F. An
/// ellipsis stands where the learner puts a word in, as X does in appendix F.
struct Phrase: Identifiable, Hashable, Sendable {

    let navi: String
    let english: String
    /// A literal reading or a note on use, where the meaning is not literal.
    var note: String?

    var id: String { navi }
}

struct PhraseTopic: Identifiable, Hashable, Sendable {

    let title: String
    /// The SF Symbol shown beside the topic in the phrasebook's list.
    let symbol: String
    let phrases: [Phrase]

    var id: String { title }
}

enum Phrasebook {

    static let topics: [PhraseTopic] = [
        PhraseTopic(title: "Greetings and Goodbyes", symbol: "hand.wave", phrases: [
            Phrase(navi: "Kaltxì", english: "Hello", note: "Casual."),
            Phrase(navi: "Oel ngati kameie", english: "I see you", note: "A familiar greeting."),
            Phrase(navi: "Ngaru lu fpom srak?", english: "How are you?", note: "Literally, is there well-being for you?"),
            Phrase(navi: "Ngaru tut", english: "And you?", note: "Returns a question that was asked with the dative, like the one above."),
            Phrase(navi: "Smon nìprrte'", english: "Pleased to meet you"),
            Phrase(navi: "Zola'u nìprrte'", english: "Welcome", note: "Literally, you have come with pleasure."),
            Phrase(navi: "Tolätxaw nìprrte'", english: "Welcome back"),
            Phrase(navi: "Kìyevame", english: "Goodbye, see you soon"),
            Phrase(navi: "Eywa ngahu", english: "Goodbye", note: "Literally, Eywa be with you."),
            Phrase(navi: "Makto zong", english: "Take care on your way"),
            Phrase(navi: "Txon lefpom", english: "Good night", note: "Literally, peaceful night."),
        ]),
        PhraseTopic(title: "Courtesy", symbol: "heart", phrases: [
            Phrase(navi: "Irayo", english: "Thank you"),
            Phrase(navi: "Oe irayo si ngaru", english: "I thank you"),
            Phrase(navi: "Kea tìkin", english: "No need to thank me"),
            Phrase(navi: "Pum ngeyä", english: "Thank you, too", note: "A reply to thanks; literally, yours: the thanks should go to you."),
            Phrase(navi: "Nìprrte'", english: "Gladly; it was a pleasure"),
            Phrase(navi: "Oeru meuia", english: "It is an honour for me"),
            Phrase(navi: "Oeru txoa livu", english: "Please forgive me", note: "Literally, may there be forgiveness for me."),
            Phrase(navi: "'Awa swawtsyìp", english: "Just a moment"),
            Phrase(navi: "Tsun miväkxu hìkrr srak?", english: "May I interrupt for a moment?"),
            Phrase(navi: "Rutxe tivìng mikyun, ma frapo", english: "Your attention, please, everyone"),
            Phrase(navi: "Tstunwi", english: "That's kind of you"),
        ]),
        PhraseTopic(title: "Getting to Know Someone", symbol: "person.text.rectangle", phrases: [
            Phrase(navi: "Fyape fko syaw ngar?", english: "What's your name?", note: "Literally, how are you called?"),
            Phrase(navi: "Oeru syaw fko Txewì", english: "My name is Txewì"),
            Phrase(navi: "Ngenga lu tupe?", english: "Who are you?", note: "With the respectful form of you."),
            Phrase(navi: "Nga zola'u ftu peseng?", english: "Where have you come from?"),
            Phrase(navi: "Fìpor syaw fko Ìstaw", english: "This is Ìstaw", note: "Introducing someone: this one is called Ìstaw."),
            Phrase(navi: "Ngaru oeyä lertut", english: "Let me introduce my colleague"),
            Phrase(navi: "Srake smon ngar oeyä meylan alu Entu sì Kamun?", english: "Do you know my friends Entu and Kamun?"),
            Phrase(navi: "Nga läpivawk nì'it nì'ul ko", english: "Tell me a little more about yourself"),
            Phrase(navi: "Tìk'ìnìri kempe si nga?", english: "What do you do in your free time?"),
            Phrase(navi: "Nga pesuhu käteng nìtrrtrr?", english: "Who do you usually spend your time with?"),
            Phrase(navi: "Oe tskxekeng si säsulìnur alu tsko swizaw", english: "I practise my hobby, archery"),
        ]),
        PhraseTopic(title: "Learning Na'vi", symbol: "graduationcap", phrases: [
            Phrase(navi: "… nìNa'vi slu pelì'u?", english: "How do you say … in Na'vi?",
                   note: "Put the word you want in place of the dots. Literally, … becomes what word in Na'vi?"),
            Phrase(navi: "Tsalì'uri alu …, ral lu 'upe?", english: "What does the word … mean?",
                   note: "Literally, as for that word, …, what is its meaning?"),
            Phrase(navi: "Ke tslolam", english: "I didn't understand"),
            Phrase(navi: "Rutxe liveyn", english: "Could you say that again, please?"),
            Phrase(navi: "Tsun nga law sivi nì'it srak?", english: "Could you make that a little clearer?"),
            Phrase(navi: "Srake fnan ngal lì'fyati leNa'vi?", english: "Are you good at Na'vi?"),
            Phrase(navi: "Ftia oel lì'fyati leNa'vi nì'o' nìwotx", english: "Learning Na'vi is great fun for me"),
        ]),
        PhraseTopic(title: "Conversation", symbol: "bubble.left.and.bubble.right", phrases: [
            Phrase(navi: "Pefya nga fpìl?", english: "What do you think?", note: "Literally, how do you think?"),
            Phrase(navi: "Tì'efumì oeyä", english: "In my opinion"),
            Phrase(navi: "Tìomummì oeyä", english: "As far as I know", note: "Literally, in my knowledge."),
            Phrase(navi: "Tìyawr ngaru", english: "You're right"),
            Phrase(navi: "Tìkxey ngaru", english: "You're wrong"),
            Phrase(navi: "Ke tare", english: "It doesn't matter"),
        ]),
        PhraseTopic(title: "Feelings and Encouragement", symbol: "face.smiling", phrases: [
            Phrase(navi: "Nga yawne lu oer", english: "I love you", note: "Literally, you are beloved to me."),
            Phrase(navi: "Ngari txe'lan mawey livu", english: "Don't worry", note: "Literally, may your heart be calm."),
            Phrase(navi: "Ke zene win säpivi", english: "Take your time; no need to hurry"),
            Phrase(navi: "'Ivong nìk'ong", english: "Slowly is fine"),
            Phrase(navi: "Oeru teya si", english: "That fills me with joy"),
            Phrase(navi: "Srefereiey nìprrte'", english: "I'm looking forward to it"),
            Phrase(navi: "Sivako", english: "You can do it!"),
            Phrase(navi: "Sasya!", english: "I can do it!"),
            Phrase(navi: "Soleia!", english: "You did it!"),
            Phrase(navi: "Seykxel sì nitram", english: "Congratulations", note: "Literally, strong and happy."),
            Phrase(navi: "Etrìpa syayvi", english: "Good luck"),
            Phrase(navi: "Yewla!", english: "What a shame!"),
        ]),
        PhraseTopic(title: "Sayings", symbol: "text.quote", phrases: [
            Phrase(navi: "Fwa kan ke tam; zene swizawit livonu.", english: "Aiming is not enough; the arrow has to fly",
                   note: "Good intentions are not enough; what counts is action."),
            Phrase(navi: "Kxetse sì mikyun kop plltxe", english: "The tail and the ears speak too",
                   note: "Body language matters."),
            Phrase(navi: "Säfpìl asteng tìkan ateng", english: "Great minds think alike",
                   note: "Literally, the same thought, the same aim."),
            Phrase(navi: "Kem amuiä, kum afe'", english: "The right action, a bad result",
                   note: "Said when something done properly still turns out badly."),
            Phrase(navi: "Txo ke nìyo' tsakrr nìyol", english: "If not flawless, then at least brief"),
            Phrase(navi: "Txìm a'aw ke tsun hiveyn mì tal mefa'liyä.", english: "You can't sit on two direhorses at once",
                   note: "Take one position instead of trying to hold two."),
            Phrase(navi: "Fwäkì ke fwefwi", english: "A mantis doesn't whistle",
                   note: "It is not in their nature."),
            Phrase(navi: "Taronyut yom smarìl", english: "The prey eats the hunter",
                   note: "Everything has gone wrong at once."),
            Phrase(navi: "Loreyu 'awnampi", english: "Like a helicoradian that has been touched",
                   note: "Painfully shy."),
            Phrase(navi: "Kenten mì kumpay", english: "Like a fan lizard in gel",
                   note: "Unable to act freely or naturally."),
            Phrase(navi: "Srefwa sngap zize'", english: "Before the hellwasp stings",
                   note: "As quickly as possible."),
            Phrase(navi: "Tsun pehem?", english: "What can one do?"),
        ]),
    ]
}
