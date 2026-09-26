//
//  KeyboardLayout.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/25/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

// Spacing measured from the iOS 26 system keyboard, in portrait on a 402-point-wide
// iPhone. Landscape keeps the spacing the keyboard used before.
class LayoutConstants: NSObject {
    // A layout at least this many times wider than it is tall is treated as
    // landscape. Portrait phones reach about 2.1, landscape phones start near 4.
    class var landscapeRatio: CGFloat { get { return 2.5 }}
    
    class var sideEdgesPortrait: CGFloat { get { return 6.5 }}
    class var sideEdgesLandscape: CGFloat { get { return 3 }}
    
    // above the first row, below the toolbar
    class var topEdgePortrait: CGFloat { get { return 6 }}
    class var topEdgeLandscape: CGFloat { get { return 4 }}
    class var bottomEdge: CGFloat { get { return 3 }}
    
    class var rowGapPortrait: CGFloat { get { return 11 }}
    class var rowGapLandscape: CGFloat { get { return 7 }}
    class var keyGap: CGFloat { get { return 6 }}
    
    // Shift and Delete, and the keys in their place on the other pages, are this
    // many times as wide as a letter key.
    class var sideKeyWidthRatio: CGFloat { get { return 1.36 }}
    // A row between Shift and Delete with fewer keys than this, such as the
    // punctuation row, spreads its keys across the width this many letters take.
    class var standardCharacterCount: Int { get { return 7 }}
    
    // keyboard area shrinks in size in landscape on 6 and 6+
    class var keyboardShrunkSizeArray: [CGFloat] { get { return [522, 524] }}
    class var keyboardShrunkSizeWidthThreshholds: [CGFloat] { get { return [700] }}
    class var keyboardShrunkSizeBaseWidthThreshhold: CGFloat { get { return 600 }}
    
    class var keyCornerRadius: CGFloat { get { return 8 }}
    class var popupCornerRadius: CGFloat { get { return 13 }}
    
    // A popup is this much wider than its key. For a key of the reference height,
    // its body is this tall and ends this far above the key.
    class var popupWidthIncrement: CGFloat { get { return 25.33 }}
    class var popupBodyHeight: CGFloat { get { return 54 }}
    class var popupGap: CGFloat { get { return 12 }}
    // Near the top of the keyboard, where a popup has less room, it keeps at least
    // these, and stays this far inside the keyboard's edges.
    class var popupMinimumBodyHeight: CGFloat { get { return 34 }}
    class var popupMinimumGap: CGFloat { get { return 4 }}
    class var popupMargin: CGFloat { get { return 2 }}
    
    // `isPad` comes from the keyboard's trait collection, supplied by the layout.
    class func keyboardIsShrunk(_ width: CGFloat, isPad: Bool) -> Bool {
        return (isPad ? false : width >= self.keyboardShrunkSizeBaseWidthThreshhold)
    }
    class func keyboardShrunkSize(_ width: CGFloat, isPad: Bool) -> CGFloat {
        if isPad {
            return width
        }
        
        if width >= self.keyboardShrunkSizeBaseWidthThreshhold {
            return self.findThreshhold(self.keyboardShrunkSizeArray, threshholds: self.keyboardShrunkSizeWidthThreshholds, measurement: width)
        }
        else {
            return width
        }
    }
    
    class func findThreshhold(_ elements: [CGFloat], threshholds: [CGFloat], measurement: CGFloat) -> CGFloat {
        assert(elements.count == threshholds.count + 1, "elements and threshholds do not match")
        return elements[self.findThreshholdIndex(threshholds, measurement: measurement)]
    }
    class func findThreshholdIndex(_ threshholds: [CGFloat], measurement: CGFloat) -> Int {
        for (i, threshhold) in Array(threshholds.reversed()).enumerated() {
            if measurement >= threshhold {
                let actualIndex = threshholds.count - i
                return actualIndex
            }
        }
        return 0
    }
}

// The iOS 26 system keyboard gives every key the same fill, and shows Shift's
// state through its symbol alone. The fills are opaque, as the system's are, so
// Reduce Transparency needs no colours of its own.
class GlobalColors: NSObject {
    class var lightModeKey: UIColor { get { return UIColor.white }}
    class var darkModeKey: UIColor { get { return UIColor(white: 61/255, alpha: 1) }}
    // a key without a popup, such as Delete, while it is held down
    class var lightModePressedKey: UIColor { get { return UIColor(red: 199/255, green: 202/255, blue: 209/255, alpha: 1) }}
    class var darkModePressedKey: UIColor { get { return UIColor(white: 92/255, alpha: 1) }}
    class var lightModePopup: UIColor { get { return UIColor.white }}
    class var darkModePopup: UIColor { get { return UIColor(white: 80/255, alpha: 1) }}
    class var lightModeTextColor: UIColor { get { return UIColor.black }}
    class var darkModeTextColor: UIColor { get { return UIColor.white }}
    // Return, in fields where it performs an action such as a search
    class var accentKey: UIColor { get { return UIColor(red: 0, green: 122/255, blue: 1, alpha: 1) }}
    class var pressedAccentKey: UIColor { get { return UIColor(red: 0, green: 98/255, blue: 204/255, alpha: 1) }}
    class var accentTextColor: UIColor { get { return UIColor.white }}
    
    class func key(_ darkMode: Bool) -> UIColor {
        return darkMode ? self.darkModeKey : self.lightModeKey
    }
    
    class func pressedKey(_ darkMode: Bool) -> UIColor {
        return darkMode ? self.darkModePressedKey : self.lightModePressedKey
    }
    
    class func popup(_ darkMode: Bool) -> UIColor {
        return darkMode ? self.darkModePopup : self.lightModePopup
    }
    
    class func text(_ darkMode: Bool) -> UIColor {
        return darkMode ? self.darkModeTextColor : self.lightModeTextColor
    }
}

/// The dictionary key for grouping pooled key views by size. A local type avoids
/// conforming CGSize, an imported type, to Hashable, an imported protocol.
struct KeySize: Hashable {
    let width: CGFloat
    let height: CGFloat
    
    init(_ size: CGSize) {
        self.width = size.width
        self.height = size.height
    }
}

// handles the layout for the keyboard, including key spacing and arrangement
class KeyboardLayout: NSObject, KeyboardKeyProtocol {
    
    class var shouldPoolKeys: Bool { get { return true }}
    
    var layoutConstants: LayoutConstants.Type
    var globalColors: GlobalColors.Type
    
    unowned var model: Keyboard
    unowned var superview: UIView
    var modelToView: [Key:KeyboardKey] = [:]
    var viewToModel: [KeyboardKey:Key] = [:]
    
    var keyPool: [KeyboardKey] = []
    var nonPooledMap: [String:KeyboardKey] = [:]
    var sizeToKeyMap: [KeySize:[KeyboardKey]] = [:]
    
    var darkMode: Bool
    var solidColorMode: Bool
    var initialized: Bool
    
    /// The field's Return key type. Return turns blue where it performs an action.
    var returnKeyType: UIReturnKeyType = .default
    
    required init(model: Keyboard, superview: UIView, layoutConstants: LayoutConstants.Type, globalColors: GlobalColors.Type, darkMode: Bool, solidColorMode: Bool) {
        self.layoutConstants = layoutConstants
        self.globalColors = globalColors
        
        self.initialized = false
        self.model = model
        self.superview = superview
        
        self.darkMode = darkMode
        self.solidColorMode = solidColorMode
    }
    
    // TODO: remove this method
    func initialize() {
        assert(!self.initialized, "already initialized")
        self.initialized = true
    }
    
    func viewForKey(_ model: Key) -> KeyboardKey? {
        return self.modelToView[model]
    }
    
    func keyForView(_ key: KeyboardKey) -> Key? {
        return self.viewToModel[key]
    }
    
    //////////////////////////////////////////////
    // CALL THESE FOR LAYOUT/APPEARANCE CHANGES //
    //////////////////////////////////////////////
    
    func layoutKeys(_ pageNum: Int, uppercase: Bool, characterUppercase: Bool, shiftState: ShiftState) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // pre-allocate all keys if no cache
        if !type(of: self).shouldPoolKeys {
            if self.keyPool.isEmpty {
                for p in 0..<self.model.pages.count {
                    self.positionKeys(p)
                }
                self.updateKeyAppearance()
                self.updateKeyCaps(true, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: shiftState)
            }
        }
        
        self.positionKeys(pageNum)
        
        // reset state
        for (p, page) in self.model.pages.enumerated() {
            for (_, row) in page.rows.enumerated() {
                for (_, key) in row.enumerated() {
                    if let keyView = self.modelToView[key] {
                        keyView.hidePopup()
                        keyView.isHighlighted = false
                        keyView.isHidden = (p != pageNum)
                    }
                }
            }
        }
        
        if type(of: self).shouldPoolKeys {
            self.updateKeyAppearance()
            self.updateKeyCaps(true, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: shiftState)
        }
        
        CATransaction.commit()
    }
    
    func positionKeys(_ pageNum: Int) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let setupKey = { (view: KeyboardKey, model: Key, frame: CGRect) -> Void in
            view.frame = frame
            self.modelToView[model] = view
            self.viewToModel[view] = model
        }
        
        if var keyMap = self.generateKeyFrames(self.model, bounds: self.superview.bounds, page: pageNum) {
            if type(of: self).shouldPoolKeys {
                self.modelToView.removeAll(keepingCapacity: true)
                self.viewToModel.removeAll(keepingCapacity: true)
                
                self.resetKeyPool()
                
                var foundCachedKeys = [Key]()
                
                // pass 1: reuse any keys that match the required size
                for (key, frame) in keyMap {
                    if let keyView = self.pooledKey(key: key, model: self.model, frame: frame) {
                        foundCachedKeys.append(key)
                        setupKey(keyView, key, frame)
                    }
                }
                
                _ = foundCachedKeys.map {
                    keyMap.removeValue(forKey: $0)
                }
                
                // pass 2: fill in the blanks
                for (key, frame) in keyMap {
                    let keyView = self.generateKey()
                    setupKey(keyView, key, frame)
                }
            }
            else {
                for (key, frame) in keyMap {
                    if let keyView = self.pooledKey(key: key, model: self.model, frame: frame) {
                        setupKey(keyView, key, frame)
                    }
                }
            }
        }
        
        CATransaction.commit()
    }
    
    func updateKeyAppearance() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        for (key, view) in self.modelToView {
            self.setAppearanceForKey(view, model: key, darkMode: self.darkMode, solidColorMode: self.solidColorMode)
        }
        
        CATransaction.commit()
    }
    
    // on fullReset, we update the keys with shapes, images, etc. as if from scratch; otherwise, just update the text
    // WARNING: if key cache is disabled, DO NOT CALL WITH fullReset MORE THAN ONCE
    func updateKeyCaps(_ fullReset: Bool, uppercase: Bool, characterUppercase: Bool, shiftState: ShiftState) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if fullReset {
            for (_, key) in self.modelToView {
                (key as? ImageKey)?.symbolName = nil
            }
        }
        
        for (model, key) in self.modelToView {
            self.updateKeyCap(key, model: model, fullReset: fullReset, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: shiftState)
        }
        
        CATransaction.commit()
    }
    
    func updateKeyCap(_ key: KeyboardKey, model: Key, fullReset: Bool, uppercase: Bool, characterUppercase: Bool, shiftState: ShiftState) {
        if fullReset {
            // type
            switch model.type {
            case Key.KeyType.character:
                key.capStyle = .letter
            case
            Key.KeyType.modeChange,
            Key.KeyType.space,
            Key.KeyType.return:
                // "#+=" is drawn smaller than "123" and "ABC", as on the system keyboard.
                let cap = model.keyCapForCase(true)
                let isSymbols = !cap.isEmpty && cap.allSatisfy { !$0.isLetter && !$0.isNumber }
                key.capStyle = .label(isSymbols ? 14 : 18)
            default:
                key.capStyle = .character
            }
            
            // label inset
            switch model.type {
            case
            Key.KeyType.modeChange:
                key.labelInset = 3
            default:
                key.labelInset = 0
            }
            
            // symbols
            switch model.type {
            case Key.KeyType.backspace:
                (key as? ImageKey)?.symbolName = "delete.left"
            case Key.KeyType.keyboardChange:
                (key as? ImageKey)?.symbolName = "globe"
            default:
                break
            }
            
            key.cornerRadius = self.layoutConstants.keyCornerRadius
            key.popupCornerRadius = self.layoutConstants.popupCornerRadius
        }
        
        if model.type == Key.KeyType.shift {
            switch shiftState {
            case .disabled:
                (key as? ImageKey)?.symbolName = "shift"
            case .enabled:
                (key as? ImageKey)?.symbolName = "shift.fill"
            case .locked:
                (key as? ImageKey)?.symbolName = "capslock.fill"
            }
        }
        
        self.updateKeyCapText(key, model: model, uppercase: uppercase, characterUppercase: characterUppercase)
    }
    
    func updateKeyCapText(_ key: KeyboardKey, model: Key, uppercase: Bool, characterUppercase: Bool) {
        if model.type == .character {
            key.text = model.keyCapForCase(characterUppercase)
        }
        else {
            key.text = model.keyCapForCase(uppercase)
        }
    }
    
    ///////////////
    // END CALLS //
    ///////////////
    
    func setAppearanceForKey(_ key: KeyboardKey, model: Key, darkMode: Bool, solidColorMode: Bool) {
        if model.type == Key.KeyType.other {
            self.setAppearanceForOtherKey(key, model: model, darkMode: darkMode, solidColorMode: solidColorMode)
        }
        
        key.color = self.globalColors.key(darkMode)
        key.textColor = self.globalColors.text(darkMode)
        key.downTextColor = nil
        key.popupColor = self.globalColors.popup(darkMode)
        
        switch model.type {
        case
        Key.KeyType.character,
        Key.KeyType.specialCharacter,
        Key.KeyType.period:
            // On iPhone a popup shows the press; on iPad, where there are no
            // popups, the key darkens instead.
            key.downColor = (self.isPad ? self.globalColors.pressedKey(darkMode) : nil)
        case
        Key.KeyType.shift:
            // The symbol shows Shift's state, so the key itself never changes.
            key.downColor = nil
        case
        Key.KeyType.return:
            if self.returnKeyIsAccented {
                key.color = self.globalColors.accentKey
                key.textColor = self.globalColors.accentTextColor
                key.downColor = self.globalColors.pressedAccentKey
            }
            else {
                key.downColor = self.globalColors.pressedKey(darkMode)
            }
        case
        Key.KeyType.space,
        Key.KeyType.backspace,
        Key.KeyType.modeChange,
        Key.KeyType.keyboardChange:
            key.downColor = self.globalColors.pressedKey(darkMode)
        case
        Key.KeyType.other:
            break
        }
    }
    
    /// Whether Return is drawn blue, as the system keyboard draws it in fields
    /// where it performs an action rather than starting a new line.
    var returnKeyIsAccented: Bool {
        switch self.returnKeyType {
        case .go, .google, .join, .route, .search, .send, .yahoo, .done, .emergencyCall, .continue:
            return true
        default:
            return false
        }
    }
    
    func setAppearanceForOtherKey(_ key: KeyboardKey, model: Key, darkMode: Bool, solidColorMode: Bool) { /* override this to handle special keys */ }
    
    // TODO: avoid array copies
    // TODO: sizes stored not rounded?
    
    ///////////////////////////
    // KEY POOLING FUNCTIONS //
    ///////////////////////////
    
    // if pool is disabled, always returns a unique key view for the corresponding key model
    func pooledKey(key aKey: Key, model: Keyboard, frame: CGRect) -> KeyboardKey? {
        if !type(of: self).shouldPoolKeys {
            // TODO: O(N^2) in terms of total # of keys since pooledKey is called for each key, but probably doesn't matter
            var id = ""
            search: for (p, page) in model.pages.enumerated() {
                for (r, row) in page.rows.enumerated() {
                    for (k, key) in row.enumerated() where key == aKey {
                        id = "p\(p)r\(r)k\(k)"
                        break search
                    }
                }
            }

            if let key = self.nonPooledMap[id] {
                return key
            }
            else {
                let key = generateKey()
                self.nonPooledMap[id] = key
                return key
            }
        }
        else {
            if var keyArray = self.sizeToKeyMap[KeySize(frame.size)] {
                if let key = keyArray.last {
                    if keyArray.count == 1 {
                        self.sizeToKeyMap.removeValue(forKey: KeySize(frame.size))
                    }
                    else {
                        keyArray.removeLast()
                        self.sizeToKeyMap[KeySize(frame.size)] = keyArray
                    }
                    return key
                }
                else {
                    return nil
                }
                
            }
            else {
                return nil
            }
        }
    }
    
    func createNewKey() -> KeyboardKey {
        return ImageKey()
    }
    
    // if pool is disabled, always generates a new key
    func generateKey() -> KeyboardKey {
        let createAndSetupNewKey = { () -> KeyboardKey in
            let keyView = self.createNewKey()
            
            keyView.isEnabled = true
            keyView.delegate = self
            
            self.superview.addSubview(keyView)
            
            self.keyPool.append(keyView)
            
            return keyView
        }
        
        if type(of: self).shouldPoolKeys {
            if !self.sizeToKeyMap.isEmpty {
                var (size, keyArray) = self.sizeToKeyMap[self.sizeToKeyMap.startIndex]
                
                if let key = keyArray.last {
                    if keyArray.count == 1 {
                        self.sizeToKeyMap.removeValue(forKey: size)
                    }
                    else {
                        keyArray.removeLast()
                        self.sizeToKeyMap[size] = keyArray
                    }
                    
                    return key
                }
                else {
                    return createAndSetupNewKey()
                }
            }
            else {
                return createAndSetupNewKey()
            }
        }
        else {
            return createAndSetupNewKey()
        }
    }
    
    // if pool is disabled, doesn't do anything
    func resetKeyPool() {
        if type(of: self).shouldPoolKeys {
            self.sizeToKeyMap.removeAll(keepingCapacity: true)
            
            for key in self.keyPool {
                if var keyArray = self.sizeToKeyMap[KeySize(key.frame.size)] {
                    keyArray.append(key)
                    self.sizeToKeyMap[KeySize(key.frame.size)] = keyArray
                }
                else {
                    var keyArray = [KeyboardKey]()
                    keyArray.append(key)
                    self.sizeToKeyMap[KeySize(key.frame.size)] = keyArray
                }
                key.isHidden = true
            }
        }
    }
    
    //////////////////////
    // LAYOUT FUNCTIONS //
    //////////////////////
    
    /// Whether the keyboard is laying out for iPad, read from the host's traits
    /// rather than from the device.
    private var isPad: Bool {
        return self.superview.traitCollection.userInterfaceIdiom == .pad
    }
    
    /// The scale of the display the keyboard is currently on.
    ///
    /// Read from the trait collection rather than the main screen, so the value
    /// follows the window the keyboard is actually in.
    private var displayScale: CGFloat {
        let scale = self.superview.traitCollection.displayScale
        return scale > 0 ? scale : 1
    }

    func rounded(_ measurement: CGFloat) -> CGFloat {
        let scale = displayScale
        return round(measurement * scale) / scale
    }
    
    /// A frame whose edges fall on the display's pixel grid, so neighbouring keys
    /// keep an even gap between them.
    func pixelAlignedFrame(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        let minX = self.rounded(x)
        let maxX = self.rounded(x + width)
        let minY = self.rounded(y)
        let maxY = self.rounded(y + height)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    func generateKeyFrames(_ model: Keyboard, bounds: CGRect, page pageToLayout: Int) -> [Key:CGRect]? {
        if bounds.height == 0 || bounds.width == 0 || pageToLayout >= model.pages.count {
            return nil
        }
        
        let page = model.pages[pageToLayout]
        let constants = self.layoutConstants
        let isLandscape = (bounds.width / bounds.height >= constants.landscapeRatio)
        
        let sideEdges = (isLandscape ? constants.sideEdgesLandscape : constants.sideEdgesPortrait)
        let topEdge = (isLandscape ? constants.topEdgeLandscape : constants.topEdgePortrait)
        let rowGap = (isLandscape ? constants.rowGapLandscape : constants.rowGapPortrait)
        let keyGap = constants.keyGap
        
        // On wide phones in landscape the keys keep to a narrower area in the middle.
        let areaWidth = constants.keyboardShrunkSize(bounds.width - 2 * sideEdges, isPad: self.isPad)
        let area = CGRect(x: (bounds.width - areaWidth) / 2, y: topEdge, width: areaWidth, height: bounds.height - topEdge - constants.bottomEdge)
        
        let numRows = page.rows.count
        if numRows == 0 {
            return [:]
        }
        // on the pixel grid, so every row is the same height
        let keyHeight = self.rounded((area.height - CGFloat(numRows - 1) * rowGap) / CGFloat(numRows))

        // Letter keys are as wide as the longest row allows.
        let mostKeysInRow = page.rows.map { $0.count }.max() ?? 1
        let letterKeyWidth = (area.width - CGFloat(mostKeysInRow - 1) * keyGap) / CGFloat(mostKeysInRow)

        // Too small to hold the keys, as can happen for a moment while the host
        // resizes the keyboard: keep the previous layout rather than draw keys
        // with negative sizes.
        if keyHeight <= 0 || letterKeyWidth <= 0 {
            return nil
        }

        var keyMap = [Key:CGRect]()
        
        for (r, row) in page.rows.enumerated() {
            let frame = CGRect(x: area.minX, y: area.minY + CGFloat(r) * (keyHeight + rowGap), width: area.width, height: keyHeight)
            let frames: [CGRect]
            
            // basic character row: only typable characters
            if self.characterRowHeuristic(row) {
                frames = self.layoutCharacterRow(row, keyWidth: letterKeyWidth, gapWidth: keyGap, frame: frame)
            }
            // character row with side buttons: shift, backspace, etc.
            else if self.doubleSidedRowHeuristic(row) {
                frames = self.layoutCharacterWithSidesRow(row, frame: frame, keyWidth: letterKeyWidth, keyGap: keyGap)
            }
            // bottom row with things like space, return, etc.
            else {
                frames = self.layoutSpecialKeysRow(row, keyWidth: letterKeyWidth, keyGap: keyGap, frame: frame)
            }
            
            assert(row.count == frames.count, "row and frames don't match")
            for (k, key) in row.enumerated() {
                keyMap[key] = frames[k]
            }
        }
        
        return keyMap
    }
    
    func characterRowHeuristic(_ row: [Key]) -> Bool {
        return (row.count >= 1 && row[0].isCharacter)
    }
    
    func doubleSidedRowHeuristic(_ row: [Key]) -> Bool {
        return (row.count >= 3 && !row[0].isCharacter && row[1].isCharacter)
    }
    
    // Keys of one width, centred in the row.
    func layoutCharacterRow(_ row: [Key], keyWidth: CGFloat, gapWidth: CGFloat, frame: CGRect) -> [CGRect] {
        let count = CGFloat(row.count)
        var gap = gapWidth
        var sideSpace = (frame.width - count * keyWidth - (count - 1) * gapWidth) / 2
        
        // avoiding rounding errors
        if sideSpace < 0 {
            sideSpace = 0
            gap = (row.count > 1 ? (frame.width - count * keyWidth) / (count - 1) : 0)
        }
        
        return row.indices.map { k in
            self.pixelAlignedFrame(x: frame.minX + sideSpace + CGFloat(k) * (keyWidth + gap), y: frame.minY, width: keyWidth, height: frame.height)
        }
    }
    
    // Shift and Delete, or the keys in their place, at the ends, and the keys
    // between them centred.
    func layoutCharacterWithSidesRow(_ row: [Key], frame: CGRect, keyWidth: CGFloat, keyGap: CGFloat) -> [CGRect] {
        let characterCount = row.count - 2
        let standardCount = self.layoutConstants.standardCharacterCount
        let standardWidth = CGFloat(standardCount) * keyWidth + CGFloat(standardCount - 1) * keyGap
        
        let charactersWidth: CGFloat
        let characterWidth: CGFloat
        if characterCount < standardCount {
            charactersWidth = standardWidth
            characterWidth = (standardWidth - CGFloat(characterCount - 1) * keyGap) / CGFloat(characterCount)
        }
        else {
            characterWidth = keyWidth
            charactersWidth = CGFloat(characterCount) * keyWidth + CGFloat(characterCount - 1) * keyGap
        }
        
        let charactersX = frame.minX + (frame.width - charactersWidth) / 2
        let sideWidth = max(0, min(keyWidth * self.layoutConstants.sideKeyWidthRatio, charactersX - frame.minX - keyGap))
        
        var frames = [CGRect]()
        frames.append(self.pixelAlignedFrame(x: frame.minX, y: frame.minY, width: sideWidth, height: frame.height))
        for k in 0..<characterCount {
            frames.append(self.pixelAlignedFrame(x: charactersX + CGFloat(k) * (characterWidth + keyGap), y: frame.minY, width: characterWidth, height: frame.height))
        }
        frames.append(self.pixelAlignedFrame(x: frame.maxX - sideWidth, y: frame.minY, width: sideWidth, height: frame.height))
        
        return frames
    }
    
    // The bottom row. As on the system keyboard, the space bar starts where the
    // third key of a nine-key row would and Return where the eighth would, so the
    // keys on either side of the space bar share about two and a half letters'
    // width.
    func layoutSpecialKeysRow(_ row: [Key], keyWidth: CGFloat, keyGap: CGFloat, frame: CGRect) -> [CGRect] {
        guard let spaceIndex = row.firstIndex(where: { $0.type == Key.KeyType.space }) else {
            let width = (frame.width - CGFloat(row.count - 1) * keyGap) / CGFloat(row.count)
            return self.layoutCharacterRow(row, keyWidth: width, gapWidth: keyGap, frame: frame)
        }
        
        let unit = keyWidth + keyGap
        let keysBefore = spaceIndex
        let keysAfter = row.count - spaceIndex - 1
        let spaceStart = (keysBefore > 0 ? frame.minX + 2.5 * unit : frame.minX)
        let afterStart = frame.minX + 7.5 * unit
        let spaceEnd = (keysAfter > 0 ? afterStart - keyGap : frame.maxX)
        
        var frames = [CGRect]()
        
        if keysBefore > 0 {
            let width = (spaceStart - keyGap - frame.minX - CGFloat(keysBefore - 1) * keyGap) / CGFloat(keysBefore)
            for k in 0..<keysBefore {
                frames.append(self.pixelAlignedFrame(x: frame.minX + CGFloat(k) * (width + keyGap), y: frame.minY, width: width, height: frame.height))
            }
        }
        
        frames.append(self.pixelAlignedFrame(x: spaceStart, y: frame.minY, width: spaceEnd - spaceStart, height: frame.height))
        
        if keysAfter > 0 {
            let width = (frame.maxX - afterStart - CGFloat(keysAfter - 1) * keyGap) / CGFloat(keysAfter)
            for k in 0..<keysAfter {
                frames.append(self.pixelAlignedFrame(x: afterStart + CGFloat(k) * (width + keyGap), y: frame.minY, width: width, height: frame.height))
            }
        }
        
        return frames
    }
    
    ////////////////
    // END LAYOUT //
    ////////////////
    
    func frameForPopup(_ key: KeyboardKey) -> CGRect {
        let scale = key.bounds.height / KeyboardKey.referenceHeight
        let width = key.bounds.width + self.layoutConstants.popupWidthIncrement
        let bodyHeight = self.layoutConstants.popupBodyHeight * scale
        let gap = self.layoutConstants.popupGap * scale
        
        return CGRect(x: (key.bounds.width - width) / 2, y: -gap - bodyHeight, width: width, height: bodyHeight)
    }
    
    // A keyboard extension cannot draw outside its own view, so a popup that
    // would reach past the top or the sides of the keyboard is moved or shortened.
    func willShowPopup(_ key: KeyboardKey) {
        guard let popup = key.popup else {
            return
        }
        
        // the keyboard's whole view, which also holds the toolbar above the keys
        let container = self.superview.superview ?? self.superview
        let margin = self.layoutConstants.popupMargin
        let keyFrame = container.convert(key.bounds, from: key)
        var frame = container.convert(popup.frame, from: key)
        
        if frame.minY < margin {
            // Close the gap to the key first, then shorten the popup. Near the top
            // of a short keyboard it may still have to cover the top of its key.
            let scale = key.bounds.height / KeyboardKey.referenceHeight
            let room = keyFrame.minY - margin
            var gap = max(self.layoutConstants.popupMinimumGap * scale, room - frame.height)
            var bodyHeight = room - gap
            let minimumBodyHeight = self.layoutConstants.popupMinimumBodyHeight * scale
            if bodyHeight < minimumBodyHeight {
                bodyHeight = minimumBodyHeight
                gap = room - bodyHeight
            }
            
            frame.origin.y = keyFrame.minY - gap - bodyHeight
            frame.size.height = bodyHeight
        }
        
        if frame.minX < margin {
            frame.origin.x = keyFrame.minX
        }
        
        if frame.maxX > container.bounds.width - margin {
            frame.origin.x = keyFrame.maxX - frame.width
        }
        
        popup.frame = container.convert(frame, to: key)
    }
    
    func willHidePopup(_ key: KeyboardKey) {
    }
}
