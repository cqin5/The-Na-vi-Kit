//
//  test_keyboard_layout.swift
//
//  Checks the keyboard's layout code against the iOS 26 system keyboard and
//  against the sizes the keyboard meets in practice. Run it with
//  Scripts/test_keyboard_layout.sh, which compiles it together with the
//  keyboard's sources for Mac Catalyst, so no simulator is needed.
//

import UIKit

@main
@MainActor
struct KeyboardLayoutTests {

    static var failures = 0
    static var checks = 0

    static func check(_ condition: Bool, _ message: @autoclosure () -> String) {
        checks += 1
        if !condition {
            failures += 1
            print("  FAIL: \(message())")
        }
    }

    static func near(_ a: CGFloat, _ b: CGFloat, _ tolerance: CGFloat) -> Bool {
        return abs(a - b) <= tolerance
    }

    /// A keyboard view and its layout, as KeyboardViewController sets them up: the
    /// keys' view sits at the bottom of the keyboard's view, under the toolbar.
    ///
    /// The layout holds its views weakly, so callers keep all four alive.
    static func makeLayout(width: CGFloat, keysHeight: CGFloat, toolbarHeight: CGFloat = 36, scale: CGFloat = 3, globe: Bool) -> (KeyboardLayout, Keyboard, UIView, UIView) {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: width, height: keysHeight + toolbarHeight))
        let keysView = UIView(frame: CGRect(x: 0, y: toolbarHeight, width: width, height: keysHeight))
        container.addSubview(keysView)
        container.traitOverrides.displayScale = scale
        container.updateTraitsIfNeeded()
        keysView.updateTraitsIfNeeded()
        let keyboard = defaultKeyboard(includesGlobeKey: globe)
        let layout = KeyboardLayout(model: keyboard, superview: keysView, layoutConstants: LayoutConstants.self, globalColors: GlobalColors.self, darkMode: false, solidColorMode: false)
        return (layout, keyboard, keysView, container)
    }

    /// Frames every key must satisfy whatever the size: inside the view, not
    /// overlapping, a gap between neighbours, and one height per page.
    static func checkGeometry(_ label: String, keyboard: Keyboard, frames: [Key: CGRect], bounds: CGRect, page: Int) {
        let rows = keyboard.pages[page].rows
        check(frames.count == rows.reduce(0) { $0 + $1.count }, "\(label): \(frames.count) frames for \(rows.reduce(0) { $0 + $1.count }) keys")

        let heights = Set(frames.values.map { ($0.height * 3).rounded() })
        check(heights.count == 1, "\(label): keys of different heights \(heights)")

        for (r, row) in rows.enumerated() {
            let rowFrames = row.compactMap { frames[$0] }
            for frame in rowFrames {
                check(frame.width > 0 && frame.height > 0, "\(label) row \(r): empty frame \(frame)")
                check(frame.minX >= -0.01 && frame.maxX <= bounds.width + 0.01 && frame.minY >= -0.01 && frame.maxY <= bounds.height + 0.01,
                      "\(label) row \(r): \(frame) outside \(bounds)")
            }
            for (a, b) in zip(rowFrames, rowFrames.dropFirst()) {
                check(b.minX - a.maxX >= 4.9, "\(label) row \(r): gap of \(b.minX - a.maxX) between \(a) and \(b)")
            }
        }
    }

    static func main() {
        print("Model")
        for globe in [true, false] {
            let keyboard = defaultKeyboard(includesGlobeKey: globe)
            check(keyboard.pages.count == 3, "three pages")
            for (p, page) in keyboard.pages.enumerated() {
                let types = page.rows[3].map { $0.type }
                let expected: [Key.KeyType] = (globe ? [.modeChange, .keyboardChange, .space, .return] : [.modeChange, .space, .return])
                check(types == expected, "page \(p) bottom row \(types), expected \(expected) with globe \(globe)")
            }
        }

        print("iOS 26 system keyboard, 402-point iPhone in portrait")
        // Measured from the system keyboard in the iOS 26.5 simulator, in points,
        // as (x, width); rows start 6 points below the toolbar and are 43 tall.
        let systemLetterRow: [(CGFloat, CGFloat)] = [(6.67, 33.33), (46.0, 33.67), (85.67, 33.33), (125.0, 33.67), (164.67, 33.33), (204.0, 33.67), (243.67, 33.33), (283.0, 33.67), (322.67, 33.33), (362.0, 33.67)]
        let systemShiftRow: [(CGFloat, CGFloat)] = [(6.67, 45.33), (65.67, 33.66), (105.34, 33.33), (144.67, 33.67), (184.33, 33.34), (223.66, 33.67), (263.33, 33.34), (302.66, 33.67), (350.0, 45.67)]
        let systemPunctuationRow: [(CGFloat, CGFloat)] = [(7.0, 44.67), (66.0, 48.67), (121.33, 48.67), (176.67, 48.67), (232.0, 48.67), (287.33, 48.67), (350.33, 45.0)]
        let systemBottomRow: [(CGFloat, CGFloat)] = [(6.66, 43.34), (56.0, 43.34), (105.33, 191.34), (302.67, 93.0)]
        let systemRowTops: [CGFloat] = [6, 60, 114, 168]

        do {
            let (layout, keyboard, view, container) = makeLayout(width: 402, keysHeight: 214, globe: true)
            defer { withExtendedLifetime(container) {} }
            let frames = layout.generateKeyFrames(keyboard, bounds: view.bounds, page: 0)!
            let rows = keyboard.pages[0].rows
            for (r, expected) in [(0, systemLetterRow), (2, systemShiftRow), (3, systemBottomRow)] {
                let actual = rows[r].map { frames[$0]! }
                check(actual.count == expected.count, "row \(r): \(actual.count) keys, expected \(expected.count)")
                for (frame, (x, width)) in zip(actual, expected) {
                    // one pixel at 3x, plus the measurements' own rounding
                    check(near(frame.minX, x, 0.4) && near(frame.width, width, 0.7), "row \(r): key at \(frame.minX), \(frame.width) wide; system \(x), \(width)")
                }
            }
            for (r, top) in systemRowTops.enumerated() {
                let frame = frames[rows[r][0]]!
                check(near(frame.minY, top, 0.34) && near(frame.height, 43, 0.34), "row \(r): top \(frame.minY), height \(frame.height); system \(top), 43")
            }

            let numbers = layout.generateKeyFrames(keyboard, bounds: view.bounds, page: 1)!
            let punctuation = keyboard.pages[1].rows[2].map { numbers[$0]! }
            for (frame, (x, width)) in zip(punctuation, systemPunctuationRow) {
                check(near(frame.minX, x, 0.7) && near(frame.width, width, 1.0), "punctuation row: key at \(frame.minX), \(frame.width) wide; system \(x), \(width)")
            }
        }

        do {
            // Without a globe key, 123 takes the room the globe key would have had.
            let (layout, keyboard, view, container) = makeLayout(width: 402, keysHeight: 214, globe: false)
            defer { withExtendedLifetime(container) {} }
            let frames = layout.generateKeyFrames(keyboard, bounds: view.bounds, page: 0)!
            let bottom = keyboard.pages[0].rows[3].map { frames[$0]! }
            check(bottom.count == 3, "bottom row has \(bottom.count) keys")
            check(near(bottom[0].minX, 6.67, 0.34) && near(bottom[0].maxX, 99.33, 0.34), "123 spans \(bottom[0].minX)–\(bottom[0].maxX), expected 6.67–99.33")
            check(near(bottom[1].minX, 105.33, 0.34) && near(bottom[1].width, 191.34, 0.7), "space bar at \(bottom[1].minX), \(bottom[1].width) wide")
            check(near(bottom[0].width, bottom[2].width, 0.7), "123 (\(bottom[0].width)) and Return (\(bottom[2].width)) differ")
        }

        print("Other sizes")
        // iPhone widths in portrait, and a landscape-shaped strip for each phone.
        let portraitWidths: [CGFloat] = [320, 375, 390, 393, 402, 414, 420, 428, 430, 440]
        let landscapeWidths: [CGFloat] = [568, 667, 736, 812, 844, 852, 874, 926, 932, 956]
        for globe in [true, false] {
            for width in portraitWidths {
                let (layout, keyboard, view, container) = makeLayout(width: width, keysHeight: 214, globe: globe)
                defer { withExtendedLifetime(container) {} }
                for page in 0..<keyboard.pages.count {
                    guard let frames = layout.generateKeyFrames(keyboard, bounds: view.bounds, page: page) else {
                        check(false, "portrait \(width): no frames for page \(page)")
                        continue
                    }
                    checkGeometry("portrait \(width) page \(page) globe \(globe)", keyboard: keyboard, frames: frames, bounds: view.bounds, page: page)
                    // Shift and Delete sit symmetrically.
                    let row = keyboard.pages[page].rows[2]
                    let first = frames[row.first!]!, last = frames[row.last!]!
                    check(near(first.minX, width - last.maxX, 0.34) && near(first.width, last.width, 0.7), "portrait \(width) page \(page): side keys \(first) and \(last) not symmetric")
                }
            }
            for width in landscapeWidths {
                let (layout, keyboard, view, container) = makeLayout(width: width, keysHeight: 162, toolbarHeight: 32, globe: globe)
                defer { withExtendedLifetime(container) {} }
                for page in 0..<keyboard.pages.count {
                    guard let frames = layout.generateKeyFrames(keyboard, bounds: view.bounds, page: page) else {
                        check(false, "landscape \(width): no frames for page \(page)")
                        continue
                    }
                    checkGeometry("landscape \(width) page \(page) globe \(globe)", keyboard: keyboard, frames: frames, bounds: view.bounds, page: page)
                }
            }
        }
        // iPad keyboards are wide enough to use the landscape spacing in both orientations.
        for (width, height) in [(744, 264), (820, 264), (834, 264), (1024, 264), (1180, 352), (1366, 352)] as [(CGFloat, CGFloat)] {
            let (layout, keyboard, view, container) = makeLayout(width: width, keysHeight: height, scale: 2, globe: true)
            defer { withExtendedLifetime(container) {} }
            for page in 0..<keyboard.pages.count {
                if let frames = layout.generateKeyFrames(keyboard, bounds: view.bounds, page: page) {
                    checkGeometry("iPad \(width) page \(page)", keyboard: keyboard, frames: frames, bounds: view.bounds, page: page)
                }
                else {
                    check(false, "iPad \(width): no frames for page \(page)")
                }
            }
        }

        print("Degenerate sizes")
        do {
            let (layout, keyboard, view, container) = makeLayout(width: 402, keysHeight: 214, globe: false)
            withExtendedLifetime((view, container)) {
                check(layout.generateKeyFrames(keyboard, bounds: .zero, page: 0) == nil, "zero bounds give frames")
                // too short for four rows and their gaps
                check(layout.generateKeyFrames(keyboard, bounds: CGRect(x: 0, y: 0, width: 402, height: 20), page: 0) == nil, "a 20-point-tall keyboard gives frames")
                for height in [30, 44, 60] as [CGFloat] {
                    let frames = layout.generateKeyFrames(keyboard, bounds: CGRect(x: 0, y: 0, width: 402, height: height), page: 0) ?? [:]
                    check(frames.values.allSatisfy { $0.width > 0 && $0.height > 0 }, "a \(height)-point-tall keyboard gives keys of no size")
                }
                check(layout.generateKeyFrames(keyboard, bounds: CGRect(x: 0, y: 0, width: 40, height: 214), page: 0) == nil, "a 40-point-wide keyboard gives frames")
                check(layout.generateKeyFrames(keyboard, bounds: CGRect(x: 0, y: 0, width: 402, height: 214), page: 7) == nil, "a missing page gives frames")
            }
        }

        print("Popups")
        do {
            // A popup keeps inside the keyboard's view, including in the top row
            // under the toolbar and at both edges.
            for globe in [true, false] {
                let (layout, keyboard, view, container) = makeLayout(width: 402, keysHeight: 214, globe: globe)
                let frames = layout.generateKeyFrames(keyboard, bounds: view.bounds, page: 0)!
                for (r, row) in keyboard.pages[0].rows.enumerated() {
                    for key in row where key.isCharacter {
                        let keyView = ImageKey()
                        keyView.frame = frames[key]!
                        keyView.delegate = layout
                        view.addSubview(keyView)
                        keyView.text = key.keyCapForCase(false)
                        keyView.layoutIfNeeded()
                        keyView.showPopup()

                        let popup = container.convert(keyView.popup!.frame, from: keyView)
                        let keyFrame = container.convert(keyView.bounds, from: keyView)
                        check(popup.minY >= 1.99, "row \(r) '\(keyView.text)': popup top \(popup.minY) above the keyboard")
                        check(popup.minX >= -0.01 && popup.maxX <= container.bounds.width + 0.01, "row \(r) '\(keyView.text)': popup \(popup) past the sides")
                        check(popup.height >= 33.9, "row \(r) '\(keyView.text)': popup only \(popup.height) tall")
                        check(popup.maxY <= keyFrame.minY + 0.01 || r == 0, "row \(r) '\(keyView.text)': popup covers its key")
                        if r > 0 {
                            check(near(popup.height, 54, 0.01) && near(keyFrame.minY - popup.maxY, 12, 0.01), "row \(r) '\(keyView.text)': popup \(popup.height) tall, \(keyFrame.minY - popup.maxY) above its key")
                        }

                        let path = keyView.displayView.path!
                        let box = path.boundingBoxOfPath
                        let expected = keyView.popup!.frame.union(keyView.bounds)
                        check(near(box.minX, expected.minX, 0.01) && near(box.maxX, expected.maxX, 0.01) && near(box.minY, expected.minY, 0.01) && near(box.maxY, expected.maxY, 0.01),
                              "row \(r) '\(keyView.text)': shape \(box) is not the popup and key \(expected)")
                        check(path.contains(CGPoint(x: keyView.bounds.midX, y: keyView.popup!.frame.maxY + 0.5)), "row \(r) '\(keyView.text)': shape broken between popup and key")

                        keyView.hidePopup()
                        check(keyView.displayView.path!.boundingBoxOfPath.equalTo(keyView.bounds), "row \(r) '\(keyView.text)': shape not back to the key after the popup")
                        keyView.removeFromSuperview()
                    }
                }
            }

            // A popup forced down over its key, as on a very short keyboard, still
            // makes one shape.
            let key = CGRect(x: 0, y: 0, width: 33.5, height: 43)
            let low = KeyboardKeyBackground.path(forKey: key, cornerRadius: 8, popup: CGRect(x: -12.67, y: -30, width: 58.84, height: 40), popupCornerRadius: 13)
            check(low.boundingBoxOfPath.equalTo(CGRect(x: -12.67, y: -30, width: 58.84, height: 73)), "overlapping popup shape \(low.boundingBoxOfPath)")
            check(low.contains(CGPoint(x: 16, y: 20)) && low.contains(CGPoint(x: -10, y: 0)), "overlapping popup shape has holes")
        }

        print("Key caps")
        do {
            let key = ImageKey()
            key.frame = CGRect(x: 0, y: 0, width: 33.5, height: 43)
            key.capStyle = .letter

            var baselines = [String: CGFloat]()
            for (text, size) in [("w", 24.5), ("W", 22), ("ì", 24.5), ("Ì", 22), ("kx", 22), ("Kx", 20), ("'", 22)] as [(String, CGFloat)] {
                key.text = text
                key.layoutIfNeeded()
                let font = key.label.font!
                check(near(font.pointSize, size, 0.01), "'\(text)' at \(font.pointSize) points, expected \(size)")
                // UILabel centres its line box, so this is where the text sits.
                baselines[text] = key.label.frame.midY + (font.ascender + font.descender) / 2
            }
            for (text, baseline) in baselines {
                check(near(baseline, 21.5 + 6.4, 0.01), "'\(text)' sits on a baseline at \(baseline), expected \(21.5 + 6.4)")
            }

            key.capStyle = .label(18)
            key.text = "123"
            key.layoutIfNeeded()
            check(near(key.label.font.pointSize, 18, 0.01), "'123' at \(key.label.font.pointSize) points")

            // Shorter keys, as in landscape, get smaller type, never larger.
            key.frame = CGRect(x: 0, y: 0, width: 47, height: 33.5)
            key.capStyle = .letter
            key.text = "w"
            key.layoutIfNeeded()
            check(key.label.font.pointSize < 24.5 && key.label.font.pointSize >= 24.5 * 0.75, "'w' on a short key at \(key.label.font.pointSize) points")
            key.frame = CGRect(x: 0, y: 0, width: 76, height: 59)
            key.layoutIfNeeded()
            check(near(key.label.font.pointSize, 24.5, 0.01), "'w' on a tall key at \(key.label.font.pointSize) points")

            key.symbolName = "shift.fill"
            key.layoutIfNeeded()
            check(key.symbolView.image != nil, "no image for shift.fill")
            key.symbolName = nil
            check(key.symbolView.image == nil, "symbol kept after clearing it")
        }

        print("\(checks - failures) of \(checks) checks passed")
        exit(failures == 0 ? 0 : 1)
    }
}
