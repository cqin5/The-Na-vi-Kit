//
//  DefaultKeyboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

func defaultKeyboard() -> Keyboard {
    let defaultKeyboard = Keyboard()
    
    let lettersRow1 = ["kx","w","e","r","t","y","u","i","o","p"]
    let lettersRow2 = ["a","s","tx","f","ng","'","h","ì","k","l"]
    let lettersRow3 = ["z","ä","ts","v","px","n","m"]

    
    for key in lettersRow1 {
        let keyModel = Key(.character)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 0)
    }
    
    for key in lettersRow2 {
        let keyModel = Key(.character)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 0)
    }
    
    let keyModel = Key(.shift)
    defaultKeyboard.addKey(keyModel, row: 2, page: 0)
    
    for key in lettersRow3 {
        let keyModel = Key(.character)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 0)
    }
    
    let backspace = Key(.backspace)
    defaultKeyboard.addKey(backspace, row: 2, page: 0)
    
    let keyModeChangeNumbers = Key(.modeChange)
    keyModeChangeNumbers.uppercaseKeyCap = "123"
    keyModeChangeNumbers.toMode = 1
    defaultKeyboard.addKey(keyModeChangeNumbers, row: 3, page: 0)
    
    let keyboardChange = Key(.keyboardChange)

    if UIDevice.current.hasBottom == false {
        defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
    }
    
    
//    let settings = Key(.Settings)
//    defaultKeyboard.addKey(settings, row: 3, page: 0)
    
    let space = Key(.space)
    space.uppercaseKeyCap = "mo"
    space.uppercaseOutput = " "
    space.lowercaseOutput = " "
    defaultKeyboard.addKey(space, row: 3, page: 0)
    
    let returnKey = Key(.return)
    returnKey.uppercaseKeyCap = "tätxaw"
    returnKey.uppercaseOutput = "\n"
    returnKey.lowercaseOutput = "\n"
    defaultKeyboard.addKey(returnKey, row: 3, page: 0)
    
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 1)
    }
    
    for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 1)
    }
    
    let keyModeChangeSpecialCharacters = Key(.modeChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    defaultKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
    
    for key in [".", ",", "?", "!", "'"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 1)
    }
    
    defaultKeyboard.addKey(Key(backspace), row: 2, page: 1)
    
    let keyModeChangeLetters = Key(.modeChange)
    keyModeChangeLetters.uppercaseKeyCap = "ABC"
    keyModeChangeLetters.toMode = 0
    defaultKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
    
    
    if UIDevice.current.hasBottom == false {
        defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 1)
    }

    
//    defaultKeyboard.addKey(Key(settings), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(space), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(returnKey), row: 3, page: 1)
    
    for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 2)
    }
    
    for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 2)
    }
    
    defaultKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
    
    for key in [".", ",", "?", "!", "'"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 2)
    }
    
    defaultKeyboard.addKey(Key(backspace), row: 2, page: 2)
    
    defaultKeyboard.addKey(Key(keyModeChangeLetters), row: 3, page: 2)
    
    
    if UIDevice.current.hasBottom == false {
        defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 2)
    }

    
//    defaultKeyboard.addKey(Key(settings), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(space), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(returnKey), row: 3, page: 2)
    
    return defaultKeyboard
}
