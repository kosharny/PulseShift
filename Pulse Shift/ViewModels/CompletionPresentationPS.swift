import SwiftUI
import Combine

@MainActor final class CompletionPresentationPS: ObservableObject {
    @Published var stars = 0
    @Published var energy = 0
    @Published var finished = false
    let started = Date.now
    func reveal(stars count: Int, reward: Int, reduced: Bool) async {
        for index in 1...count {
            if !reduced { try? await Task.sleep(for: .milliseconds(170)) }
            guard !Task.isCancelled else { return }
            withAnimation(reduced ? nil : .spring(duration: 0.4, bounce: 0.45)) { stars = index }
        }
        for tick in 1...12 {
            guard !Task.isCancelled else { return }
            withAnimation(reduced ? nil : .easeOut(duration: 0.06)) { energy = reward * tick / 12 }
            if !reduced { try? await Task.sleep(for: .milliseconds(45)) }
        }
        finished = true
    }
}

