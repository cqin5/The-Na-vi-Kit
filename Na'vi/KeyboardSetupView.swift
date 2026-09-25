//
//  KeyboardSetupView.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import SwiftUI
import UIKit

/// How to turn on the Na'vi keyboard, with a way to contact the developer.
struct KeyboardSetupView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingMailError = false

    private let steps = [
        SetupStep(number: 1, instruction: "1. In Settings, go to General", imageName: "Add-Keyboard-Step-1"),
        SetupStep(number: 2, instruction: "2. Go to Keyboard", imageName: "Add-Keyboard-Step-2"),
        SetupStep(number: 3, instruction: "3. Go to Keyboards", imageName: "Add-Keyboard-Step-3"),
        SetupStep(number: 4, instruction: "4. Add New Keyboard", imageName: "Add-Keyboard-Step-4"),
        SetupStep(number: 5, instruction: "5. Add Eywa", imageName: "Add-Keyboard-Step-5"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    ForEach(steps) { step in
                        SetupStepView(step: step)
                    }

                    Button("Contact Developer") {
                        contactDeveloper()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Turn on Na'vi Keyboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Could Not Send Email", isPresented: $isShowingMailError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No mail app is set up on this device. Add a mail account and try again.")
            }
        }
    }

    /// Opens a message to the developer in whichever app the reader has chosen as
    /// their default mail app.
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

// MARK: - Steps

private struct SetupStep: Identifiable {
    let number: Int
    let instruction: LocalizedStringKey
    let imageName: String

    var id: Int { number }
}

private struct SetupStepView: View {

    let step: SetupStep

    var body: some View {
        VStack(spacing: 12) {
            Text(step.instruction)
                .font(.headline)
                .multilineTextAlignment(.center)

            // The instruction carries the meaning; the screenshot only illustrates it.
            Image(step.imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.separator)
                }
                .frame(maxWidth: 500)
                .accessibilityHidden(true)
        }
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

#Preview {
    KeyboardSetupView()
}
