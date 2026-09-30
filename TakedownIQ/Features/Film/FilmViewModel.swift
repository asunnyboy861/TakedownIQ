import Foundation
import SwiftData
import SwiftUI

@MainActor
final class FilmViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var progressStage = ""
    @Published var memeLine = ""
    @Published var errorText: String?
    @Published var activeResult: BreakdownResult?

    static let memes = [
        "Watching your footwork...",
        "Counting your escapes...",
        "Shaking head at the sprawl...",
        "Freezing the exact 2 seconds you lost...",
        "Cooking up your drill prescription...",
        "Asking Coach TD for a second opinion..."
    ]

    private var memeTimer: Timer?
    private var runningTask: Task<Void, Never>?

    func processVideo(url: URL, identityContext: String, modelContext: ModelContext, profile: UserProfile, isPro: Bool, completion: @escaping (BreakdownResult?) -> Void) {
        guard QuotaEngine.shared.canRunBreakdown(isPro: isPro) else {
            errorText = "quota"
            completion(nil)
            return
        }
        isProcessing = true
        errorText = nil
        startMemes()
        runningTask = Task {
            do {
                progressStage = "Compressing your film..."
                let compressed = try await FrameExtractor.compress(url: url)
                progressStage = "Finding the moments..."
                let frames = try await FrameExtractor.extract(url: compressed)
                guard frames.count >= 6 else {
                    stopMemes()
                    isProcessing = false
                    errorText = "Tough angle — we couldn't find enough clear frames. Film from hip height, landscape, with your whole body in frame."
                    completion(nil)
                    return
                }

                let result = BreakdownResult(
                    videoLocalPath: compressed.lastPathComponent,
                    duration: frames.last?.t ?? 0
                )
                result.identityContext = identityContext
                result.status = .running
                modelContext.insert(result)
                try? modelContext.save()
                activeResult = result

                QuotaEngine.shared.recordBreakdownRun()
                if let streak = try? modelContext.fetch(FetchDescriptor<StreakState>()).first {
                    StreakEngine.touch(streak)
                }
                try? modelContext.save()

                let thumbnails = await Task.detached(priority: .utility) { () -> [Double: String] in
                    var map: [Double: String] = [:]
                    for frame in frames {
                        if let path = FrameStore.save(frame: frame) {
                            map[(frame.t * 10).rounded() / 10] = path
                        }
                    }
                    return map
                }.value

                progressStage = "Coach TD is watching..."
                let aggregate = try await GLMClient.shared.runBreakdown(frames: frames, profile: profile, identityContext: identityContext)

                for draft in aggregate.observations {
                    let obs = EventObservation()
                    obs.t = draft.t
                    obs.kind = draft.kind
                    obs.title = draft.title
                    obs.whereText = draft.whereText
                    obs.whyText = draft.whyText
                    obs.drillID = draft.drillID
                    obs.confidence = draft.confidence
                    obs.unclear = draft.unclear
                    obs.result = result
                    obs.thumbPath = thumbnails[(draft.t * 10).rounded() / 10]
                    modelContext.insert(obs)
                }
                result.summary = aggregate.summary
                result.topDrillIDs = aggregate.topDrills
                result.status = .done
                try? modelContext.save()
                stopMemes()
                isProcessing = false
                completion(result)
            } catch is CancellationError {
                stopMemes()
                isProcessing = false
            } catch {
                stopMemes()
                isProcessing = false
                errorText = "The breakdown queue hit a snag. It saved as a retry — check the Home tab in a minute."
                completion(nil)
            }
        }
    }

    func cancel() {
        runningTask?.cancel()
        stopMemes()
        isProcessing = false
    }

    private func startMemes() {
        memeLine = Self.memes.randomElement() ?? "Working..."
        memeTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.memeLine = Self.memes.randomElement() ?? "Working..."
            }
        }
    }

    private func stopMemes() {
        memeTimer?.invalidate()
        memeTimer = nil
    }

}

