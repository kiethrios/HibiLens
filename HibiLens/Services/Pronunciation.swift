import AVFoundation
import Foundation

struct PronunciationRequest: Equatable {
    let text: String
    let languageCode: String
    let rate: Float

    init(
        text: String,
        languageCode: String,
        rate: Float = AVSpeechUtteranceDefaultSpeechRate
    ) {
        self.text = text
        self.languageCode = languageCode
        self.rate = rate
    }
}

enum PronunciationText {
    static func source(preferred: String?, fallback: String) -> String {
        if let preferred = preferred?.trimmingCharacters(in: .whitespacesAndNewlines),
           !preferred.isEmpty {
            return preferred
        }
        return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum PronunciationAudioSessionPolicy {
    static let category: AVAudioSession.Category = .playback
    static let mode: AVAudioSession.Mode = .spokenAudio
    static let options: AVAudioSession.CategoryOptions = []

    static func activate(audioSession: AVAudioSession = .sharedInstance()) throws {
        try audioSession.setCategory(category, mode: mode, options: options)
        try audioSession.setActive(true)
    }
}

@MainActor
final class SpeechPronouncer {
    private let synthesizer: AVSpeechSynthesizer

    init(synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()) {
        self.synthesizer = synthesizer
    }

    func pronounce(_ request: PronunciationRequest) {
        let text = request.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        try? PronunciationAudioSessionPolicy.activate()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: request.languageCode)
        utterance.rate = request.rate

        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}
