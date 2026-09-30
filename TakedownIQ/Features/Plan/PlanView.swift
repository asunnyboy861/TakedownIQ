import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var allDrills: [DrillItem]
    
    @Query private var streaks: [StreakState]
    @State private var timerDrill: DrillItem?
    @State private var secondsLeft = 0
    @State private var timerRunning = false
    @State private var timer: Timer?
    @State private var burst = false

    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.matBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        progressCard
                        ForEach(pending.sorted { $0.order < $1.order }) { drill in
                            drillCard(drill)
                        }
                        if !completed.isEmpty {
                            completedSection
                        }
                        tomorrowPreview
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Plan")
            .onDisappear { timer?.invalidate() }
            .alert("Drill complete — streak +1", isPresented: $burst) {}
        }
    }

    private var todays: [DrillItem] { allDrills.filter { Calendar.current.isDateInToday($0.day) } }
    private var pending: [DrillItem] { todays.filter { !$0.done } }
    private var completed: [DrillItem] { todays.filter { $0.done } }

    private var progressCard: some View {
        let total = pending.count + completed.count
        return VStack(alignment: .leading, spacing: 6) {
            Text("TODAY")
                .font(.caption.bold())
                .foregroundStyle(Color.volt)
            Text("\(completed.count)/\(total) drills done")
                .font(.system(.title, weight: .heavy))
            ProgressView(value: total == 0 ? 1 : Double(completed.count) / Double(total))
                .tint(.volt)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .matCard()
    }

    private func drillCard(_ drill: DrillItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(drill.title)
                    .font(.headline)
                Spacer()
                Text("\(drill.minutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(drill.cue)
                .font(.caption)
                .foregroundStyle(Color.volt)
            HStack(spacing: 10) {
                if timerDrill?.id == drill.id, timerRunning {
                    Text(timeString(secondsLeft))
                        .font(.title3.monospacedDigit().weight(.heavy))
                        .foregroundStyle(Color.matSuccess)
                    Button("Pause") { timerRunning = false; timer?.invalidate() }
                        .font(.caption)
                    Button("Done") { complete(drill) }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.volt)
                } else {
                    Button {
                        startTimer(drill)
                    } label: {
                        Label("Start Timer", systemImage: "timer")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.volt)
                    Spacer()
                    Button {
                        complete(drill)
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mark \(drill.title) complete")
                }
            }
        }
        .matCard()
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DONE TODAY")
                .font(.caption.bold())
                .foregroundStyle(Color.matSuccess)
            ForEach(completed) { drill in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.matSuccess)
                    Text(drill.title)
                        .font(.subheadline)
                        .strikethrough()
                    Spacer()
                    Text("\(drill.minutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .matCard()
    }

    private var tomorrowPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOMORROW'S PLAN")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            let preview = PlanTemplates.todayPlan(profile: profiles.first ?? UserProfile())
            ForEach(Array(preview.drills.prefix(3).enumerated()), id: \.offset) { _, drill in
                Text("• \(drill.title) — \(drill.minutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(preview.hype)
                .font(.caption.italic())
                .foregroundStyle(Color.volt)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .matCard()
    }

    private func startTimer(_ drill: DrillItem) {
        timerDrill = drill
        secondsLeft = drill.minutes * 60
        timerRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                guard timerRunning else { return }
                secondsLeft -= 1
                if secondsLeft <= 0 {
                    timerRunning = false
                    burst = true
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
            }
        }
    }

    private func complete(_ drill: DrillItem) {
        timer?.invalidate()
        timerRunning = false
        drill.done = true
        if let streak = streaks.first {
            StreakEngine.touch(streak)
        }
        try? modelContext.save()
        burst = true
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
