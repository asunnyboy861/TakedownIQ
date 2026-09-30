import SwiftUI
import SwiftData
import AVKit

struct BreakdownResultView: View {
    @Environment(\.modelContext) private var modelContext
    let result: BreakdownResult
    @State private var seekTarget: Double?
    @State private var showDrillAdded = false

    private var player: AVPlayer {
        if let path = result.videoLocalPath {
            let dir = FileManager.default.temporaryDirectory
            let url = dir.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: url.path) {
                return AVPlayer(url: url)
            }
        }
        return AVPlayer()
    }

    var body: some View {
        ZStack {
            Color.matBG.ignoresSafeArea()
            VStack(spacing: 0) {
                if !player.currentItemNil {
                    VideoPlayerContainer(player: player, seekTo: $seekTarget)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        summaryCard
                        ForEach(result.sortedEvents) { event in
                            EventCard(event: event) {
                                seekTarget = event.t
                            }
                        }
                        if result.sortedEvents.isEmpty {
                            emptyCard
                        }
                    }
                    .padding(16)
                }
                addButton
            }
            if showDrillAdded {
                VStack {
                    Spacer()
                    Text("ADDED TO TODAY'S DRILLS")
                        .font(.system(.headline, weight: .heavy).uppercaseSmallCaps())
                        .padding(14)
                        .background(Color.volt, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Color.black)
                        .padding(.bottom, 90)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(duration: 0.35), value: showDrillAdded)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COACH TD'S TAKE")
                .font(.caption.bold())
                .foregroundStyle(Color.volt)
            Text(result.summary.isEmpty ? "Analyzing..." : result.summary)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .matCard()
    }

    private var emptyCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "eye.trianglebadge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Even the ref needs a break.")
                .font(.headline)
            Text("No clear technique moments found in this film. Try a tighter angle at hip height next time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .matCard()
    }

    private var addButton: some View {
        Button {
            addTopDrills()
        } label: {
            Label("ADD TO TODAY'S DRILLS", systemImage: "plus")
        }
        .buttonStyle(VoltButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .disabled(result.topDrillIDs.isEmpty)
        .opacity(result.topDrillIDs.isEmpty ? 0.5 : 1)
    }

    private func addTopDrills() {
        let today = Calendar.current.startOfDay(for: .now)
        let drafts = PlanTemplates.drillsFromPrescriptions(result.topDrillIDs)
        for (index, draft) in drafts.enumerated() {
            let item = DrillItem()
            item.day = today
            item.title = draft.title
            item.minutes = draft.minutes
            item.focusRaw = draft.focus
            item.cue = draft.cue
            item.order = -100 + index
            item.sourceBreakdownID = result.id.uuidString
            modelContext.insert(item)
        }
        try? modelContext.save()
        showDrillAdded = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showDrillAdded = false }
    }
}

private extension AVPlayer {
    var currentItemNil: Bool { currentItem == nil }
}

struct EventCard: View {
    @Environment(\.modelContext) private var modelContext
    let event: EventObservation
    let onSeek: () -> Void

    var body: some View {
        Button(action: onSeek) {
            HStack(spacing: 12) {
                thumbnail
                VStack(alignment: .leading, spacing: 4) {
                    if event.unclear || event.confidence < 0.6 {
                        unclearContent
                    } else {
                        Text(event.title)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                        Text("WHERE: \(event.whereText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("WHY: \(event.whyText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        prescriptionRow
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    KindBadge(kind: event.kind)
                    Text(timeString(event.t))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    if !event.unclear {
                        Text("conf \(Int(event.confidence * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                event.unclear || event.confidence < 0.6
                    ? AnyShapeStyle(Color.matSurface.opacity(0.5))
                    : AnyShapeStyle(Color.matSurface),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: event.unclear ? [5, 4] : []))
                    .foregroundStyle(event.unclear ? Color.matChance.opacity(0.6) : Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.kind.rawValue) at \(timeString(event.t)): \(event.unclear ? "unclear angle" : event.title)")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let path = event.thumbPath, let url = FrameStore.url(for: path),
           let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .frame(width: 72, height: 72)
                .overlay(Image(systemName: "film").foregroundStyle(.secondary))
        }
    }

    private var unclearContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tough angle — I can't call this one")
                .font(.headline)
            Text("Next time film from hip height, landscape, with your whole body in frame.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var prescriptionRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.uturn.forward.circle.fill")
                .foregroundStyle(Color.volt)
            Text(prescription)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.volt)
            Spacer()
            Button {
                event.isFixed = true
                try? modelContext.save()
            } label: {
                Image(systemName: event.isFixed ? "checkmark.seal.fill" : "checkmark.seal")
                    .foregroundStyle(event.isFixed ? Color.matSuccess : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(event.isFixed ? "Marked as fixed" : "Mark as fixed")
        }
    }

    private var prescription: String {
        if let tech = TechniqueLibrary.technique(forID: event.drillID) {
            return "NEXT: \(tech.title)"
        }
        return "NEXT: Re-attack drill"
    }

    private func timeString(_ t: Double) -> String {
        String(format: "%d:%05.2f", Int(t) / 60, t.truncatingRemainder(dividingBy: 60))
    }
}

struct VideoPlayerContainer: UIViewControllerRepresentable {
    let player: AVPlayer
    @Binding var seekTo: Double?

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.videoGravity = .resizeAspect
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        guard let target = seekTo else { return }
        seekTo = nil
        let time = CMTime(seconds: max(target - 0.3, 0), preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            player.rate = 0.5
        }
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator {
        var parent: VideoPlayerContainer
        init(parent: VideoPlayerContainer) { self.parent = parent }
    }
}
