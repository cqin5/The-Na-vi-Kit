//
//  KeyboardSetupView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI
import UIKit

/// The Settings tab: a compact guide to adding and switching to the Na'vi keyboard,
/// the keyboard's settings, and a way to contact the developer.
struct KeyboardSetupView: View {

    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingMailError = false

    private var palette: SetupPalette { SetupPalette(colorScheme: colorScheme) }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                introduction
                instructions
                KeyboardSettingsSection(palette: palette)
                support
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .background(palette.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Could Not Send Email", isPresented: $isShowingMailError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No mail app is set up on this device. Add a mail account and try again.")
        }
        // The error haptic plays as the alert appears, not as it is dismissed.
        .sensoryFeedback(.error, trigger: isShowingMailError) { _, isShowing in isShowing }
        .tint(palette.accent)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.subheadline)
                Text(verbatim: "EYWA")
                    .font(.caption.weight(.medium))
                    .tracking(2.5)
            }
            .foregroundStyle(palette.accent)
            .accessibilityHidden(true)

            Text("Type in Na'vi.")
                .font(.system(.largeTitle, design: .serif, weight: .medium))
                .foregroundStyle(palette.ink)
                .accessibilityAddTraits(.isHeader)

            Text("Add Eywa in Settings, then select the Na'vi keyboard when typing.")
                .font(.subheadline)
                .foregroundStyle(palette.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            SetupInstruction(number: 1, title: "Open keyboard settings", palette: palette) {
                Text("In the Settings app, follow this path:")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)

                SettingsPath(palette: palette)
                    .padding(.top, 4)
            }

            Divider().padding(.horizontal, 22)

            SetupInstruction(number: 2, title: "Add Eywa", palette: palette) {
                Text("Tap **Add New Keyboard…**, then choose **Eywa** under Third-Party Keyboards.")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().padding(.horizontal, 22)

            SetupInstruction(number: 3, title: "Make the switch", palette: palette) {
                Text("When typing, touch and hold the globe key and choose **Na'vi Keyboard**.")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().padding(.horizontal, 22)

            // iOS plays a keyboard's haptics only with Full Access, which the
            // keyboard asks for as an option.
            SetupInstruction(number: 4, title: "Allow Full Access (optional)", palette: palette) {
                Text("Tap **Na'vi Keyboard** in the keyboard list, then turn on **Allow Full Access**. Eywa needs it only to play haptics, and never sends what you type anywhere.")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(palette.ink.opacity(0.06))
        }
    }

    private var support: some View {
        VStack(spacing: 12) {
            // Scripts/preflight.py keeps the keyboard free of network and
            // pasteboard access, which is what keeps this true.
            Label("Nothing you type leaves your device", systemImage: "lock")
                .font(.footnote)
                .foregroundStyle(palette.secondaryInk)

            Button(action: contactDeveloper) {
                Label("Contact Developer", systemImage: "envelope")
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.accent)
        }
    }

    /// Opens a message in the reader's default mail app.
    private func contactDeveloper() {
        guard let url = SupportMail.url else {
            isShowingMailError = true
            return
        }

        Task {
            let opened = await UIApplication.shared.open(url, options: [:])
            if !opened {
                isShowingMailError = true
            }
        }
    }
}

// MARK: - Visual language

/// Neutral surfaces, ink typography, and a restrained slate-blue accent.
private struct SetupPalette {
    let colorScheme: ColorScheme

    var background: Color {
        colorScheme == .dark ? Color(red: 0.065, green: 0.075, blue: 0.09)
            : Color(red: 0.96, green: 0.965, blue: 0.97)
    }

    var surface: Color {
        colorScheme == .dark ? Color(red: 0.105, green: 0.12, blue: 0.14) : .white
    }

    var ink: Color {
        colorScheme == .dark ? Color(red: 0.92, green: 0.94, blue: 0.96)
            : Color(red: 0.12, green: 0.16, blue: 0.20)
    }

    var accent: Color {
        colorScheme == .dark ? Color(red: 0.58, green: 0.73, blue: 0.83)
            : Color(red: 0.20, green: 0.35, blue: 0.46)
    }

    var secondaryInk: Color {
        colorScheme == .dark ? Color(red: 0.67, green: 0.70, blue: 0.74)
            : Color(red: 0.36, green: 0.39, blue: 0.43)
    }

    var tint: Color { accent.opacity(colorScheme == .dark ? 0.12 : 0.055) }
}

// MARK: - Keyboard settings

/// The keyboard's settings. The app saves them in the App Group it shares with the
/// keyboard, which the keyboard can read with or without Full Access.
private struct KeyboardSettingsSection: View {
    let palette: SetupPalette

    @AppStorage(KeyboardSettings.autoCapitalizationKey, store: KeyboardSettings.sharedStore)
    private var autoCapitalization = KeyboardSettings.defaultAutoCapitalization
    @AppStorage(KeyboardSettings.periodShortcutKey, store: KeyboardSettings.sharedStore)
    private var periodShortcut = KeyboardSettings.defaultPeriodShortcut
    @AppStorage(KeyboardSettings.keyboardClicksKey, store: KeyboardSettings.sharedStore)
    private var keyboardClicks = KeyboardSettings.defaultKeyboardClicks
    @AppStorage(KeyboardSettings.hapticsKey, store: KeyboardSettings.sharedStore)
    private var haptics = KeyboardSettings.defaultHaptics
    @AppStorage(KeyboardSettings.hapticStrengthKey, store: KeyboardSettings.sharedStore)
    private var hapticStrength = KeyboardSettings.defaultHapticStrength

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard")
                .font(.headline)
                .foregroundStyle(palette.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 0) {
                SettingRow(palette: palette) {
                    Toggle("Auto-Capitalization", isOn: $autoCapitalization)
                }

                Divider().padding(.horizontal, 22)

                SettingRow(palette: palette) {
                    Toggle("“.” Shortcut", isOn: $periodShortcut)
                }

                Divider().padding(.horizontal, 22)

                SettingRow(palette: palette) {
                    Toggle("Keyboard Clicks", isOn: $keyboardClicks)
                }

                Divider().padding(.horizontal, 22)

                SettingRow(palette: palette) {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Haptic Feedback", isOn: $haptics)

                        if haptics {
                            Picker("Strength", selection: $hapticStrength) {
                                Text("Light").tag(HapticStrength.light)
                                Text("Medium").tag(HapticStrength.medium)
                                Text("Strong").tag(HapticStrength.strong)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
            }
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(palette.ink.opacity(0.06))
            }
            // A sample of the chosen strength, as the keys will play it.
            .sensoryFeedback(trigger: hapticStrength) { _, strength in
                Self.sample(of: strength)
            }
            .sensoryFeedback(trigger: haptics) { _, isOn in
                isOn ? Self.sample(of: hapticStrength) : nil
            }

            Text("Haptic feedback plays only while Allow Full Access is on.")
                .font(.footnote)
                .foregroundStyle(palette.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
        .animation(.default, value: haptics)
    }

    private static func sample(of strength: HapticStrength) -> SensoryFeedback {
        .impact(weight: strength.usesMediumWeight ? .medium : .light, intensity: strength.intensity)
    }
}

/// One row of the settings card, inset like the setup steps above it.
private struct SettingRow<Content: View>: View {
    let palette: SetupPalette
    @ViewBuilder var content: Content

    var body: some View {
        content
            .foregroundStyle(palette.ink)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Instructions

private struct SetupInstruction<Content: View>: View {
    let number: Int
    let title: LocalizedStringKey
    let palette: SetupPalette
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(verbatim: String(format: "%02d", number))
                    .font(.system(.footnote, design: .monospaced, weight: .medium))
                    .foregroundStyle(palette.accent)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }

            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The entire Settings route remains visible, including on narrow screens or
/// at larger text sizes, where it changes from a breadcrumb to a vertical path.
private struct SettingsPath: View {
    let palette: SetupPalette

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                Text("General")
                chevron
                Text("Keyboard")
                chevron
                Text("Keyboards")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("General")
                Label("Keyboard", systemImage: "arrow.turn.down.right")
                Label("Keyboards", systemImage: "arrow.turn.down.right")
            }
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(palette.ink)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("General, then Keyboard, then Keyboards")
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(palette.accent)
    }
}

// MARK: - Support mail

private enum SupportMail {
    static let address = "cqin@me.com"
    static let subject = "Na'vi App: "

    static var url: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [URLQueryItem(name: "subject", value: subject)]
        return components.url
    }
}

#Preview("Light") {
    NavigationStack {
        KeyboardSetupView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        KeyboardSetupView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Large text") {
    NavigationStack {
        KeyboardSetupView()
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
