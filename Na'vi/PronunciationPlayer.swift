//
//  PronunciationPlayer.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import AVFoundation
import Foundation

/// Plays the bundled pronunciation recordings.
///
/// Playback is owned by the app rather than by a table view cell, so scrolling the
/// list no longer cuts a recording short when the cell that started it is reused.
/// The audio session is configured once and released again when the clip ends, so
/// whatever the listener had playing before can resume.
@MainActor
final class PronunciationPlayer {

    static let shared = PronunciationPlayer()

    private var player: AVAudioPlayer?
    private var releaseTask: Task<Void, Never>?
    private var hasConfiguredCategory = false

    private init() {}

    /// Plays the named recording from the app bundle, replacing anything already playing.
    func play(fileNamed fileName: String) {
        guard !fileName.isEmpty,
              let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            return
        }

        configureCategoryIfNeeded()

        do {
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            self.player = player
            player.play()

            scheduleSessionRelease(after: player.duration)
        } catch {
            assertionFailure("Could not play \(fileName): \(error)")
        }
    }

    /// Uses the playback category so recordings are audible even when the ring
    /// switch is set to silent.
    private func configureCategoryIfNeeded() {
        guard !hasConfiguredCategory else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            hasConfiguredCategory = true
        } catch {
            assertionFailure("Could not configure the audio session: \(error)")
        }
    }

    private func scheduleSessionRelease(after duration: TimeInterval) {
        releaseTask?.cancel()
        releaseTask = Task { [duration] in
            try? await Task.sleep(for: .seconds(duration + 0.1))
            guard !Task.isCancelled else { return }

            player = nil
            try? AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        }
    }
}
