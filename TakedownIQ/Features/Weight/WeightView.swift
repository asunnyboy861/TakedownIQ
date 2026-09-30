import SwiftUI
import SwiftData
import Charts

struct WeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \WeighIn.date) private var weighIns: [WeighIn]
    @State private var weightInput = ""
    @State private var showHydration = false
    @State private var showReport = false
    @State private var showHealthKitInfo = false
    @StateObject private var healthKit = HealthKitWeightService.shared
    @State private var latestAdvice = SafeCutEngine.evaluate(history: [], targetLB: 0)

    private var profile: UserProfile { profiles.first ?? UserProfile() }
    private var usesMetric: Bool { profile.usesMetric }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.matBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        verdictCard
                        weighInEntry
                        curveChart
                        targetCard
                        healthKitSection
                        weeklyReportCard
                        disclaimerFooter
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Safe Cut")
            .sheet(isPresented: $showHydration) { hydrationSheet }
            .sheet(isPresented: $showHealthKitInfo) { HealthKitInfoView() }
            .sheet(isPresented: $showReport) { reportSheet }
            .onAppear { refreshAdvice() }
        }
    }

    private var verdictCard: some View {
        let color: Color = {
            switch latestAdvice.verdict {
            case .stop: .matDanger
            case .slowDown: .matChance
            default: .matSuccess
            }
        }()
        return VStack(alignment: .leading, spacing: 8) {
            Text(latestAdvice.headline)
                .font(.title2.weight(.heavy))
                .foregroundStyle(color)
            Text(latestAdvice.detail)
                .font(.subheadline)
            if latestAdvice.verdict == .slowDown || latestAdvice.verdict == .stop {
                Button("Complete hydration check") { showHydration = true }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.volt)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .matCard()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(color.opacity(0.5), lineWidth: latestAdvice.verdict == .stop ? 2 : 1)
        )
    }

    private var weighInEntry: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY'S WEIGH-IN")
                .font(.caption.bold())
                .foregroundStyle(Color.volt)
            HStack(spacing: 10) {
                TextField(unitLabel, text: $weightInput)
                    .keyboardType(.decimalPad)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .padding(12)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                Button {
                    logWeight()
                } label: {
                    Text("LOG")
                }
                .buttonStyle(.borderedProminent)
                .tint(.volt)
                .foregroundStyle(.black)
                if healthKit.isAvailable {
                    Button {
                        Task {
                            if await healthKit.latestWeight() != nil {
                                if let w = await healthKit.latestWeight() {
                                    weightInput = String(format: "%.1f", converted(w))
                                }
                            } else if await healthKit.requestAuthorization() {
                                if let w = await healthKit.latestWeight() {
                                    weightInput = String(format: "%.1f", converted(w))
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Pull latest weight from HealthKit")
                }
            }
        }
        .matCard()
    }

    private var curveChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SAFE CURVE (≤1.0% PER WEEK)")
                .font(.caption.bold())
                .foregroundStyle(Color.volt)
            if weighIns.count < 2 {
                Text("Log 2+ weigh-ins to draw your safe curve.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(weighIns) { entry in
                        LineMark(x: .value("Date", entry.date), y: .value("Weight", converted(entry.weightLB)))
                            .foregroundStyle(Color.volt)
                            .symbol(Circle())
                    }
                }
                .chartYScale(domain: yDomain)
                .frame(height: 180)
            }
        }
        .matCard()
    }

    private var targetCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TARGET CLASS")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(profile.weightClassLB > 0 ? "\(Int(converted(profile.weightClassLB))) \(unitLabel)" : "Not set")
                    .font(.headline)
            }
            Spacer()
            Text("We coach the cut, not the crash.")
                .font(.caption.italic())
                .foregroundStyle(Color.volt)
        }
        .matCard()
    }

    private var healthKitSection: some View {
        Section {
            HStack {
                Image(systemName: "heart.circle.fill").foregroundStyle(.red).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HealthKit Integration").font(.headline)
                    Text("Read your weight from Apple Health via HealthKit").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { showHealthKitInfo = true } label: {
                    Text("Learn More").font(.caption).foregroundStyle(.blue)
                }.buttonStyle(.plain)
            }.padding(.vertical, 2)
        } header: {
            HStack {
                Text("Apple Health (HealthKit)")
                Spacer()
                Image(systemName: "heart.text.square.fill").foregroundStyle(.red)
            }
        } footer: {
            Text("This app uses the HealthKit framework to read your body weight from the Apple Health app (read-only) to keep your weight cut inside the safe curve. This requires your explicit permission. No health data is written to HealthKit.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var weeklyReportCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PARENT WEEKLY REPORT")
                .font(.caption.bold())
                .foregroundStyle(Color.volt)
            Text("A one-tap card your parents and coach can actually trust: weight trend, safe-curve verdict, and protein reminder.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Generate Report") { showReport = true }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.volt)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .matCard()
    }

    private var disclaimerFooter: some View {
        Text("Safe Cut is educational guidance, not medical advice. Never restrict water. If cutting stops feeling safe, move up a class or talk to a doctor.")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private var hydrationSheet: some View {
        NavigationStack {
            Form {
                Section("Hydration Self-Check") {
                    Text("Answer honestly — this protects you.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Toggle("Drinking water regularly today?", isOn: .constant(true))
                    Toggle("No dizziness or cramps?", isOn: .constant(true))
                    Toggle("Slept 8+ hours?", isOn: .constant(true))
                }
                Section {
                    Text("If any answer is NO: stop the cut, drink water with electrolytes, and eat a normal meal. Never use saunas, sweat suits, or restricted fluids — those are how wrestlers get hurt.")
                        .font(.caption)
                        .foregroundStyle(Color.matChance)
                }
            }
            .navigationTitle("Hydration Check")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { showHydration = false } }
            }
        }
        .presentationDetents([.medium])
    }

    private var reportSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                WeeklyReportCardView(advice: latestAdvice, entries: weighIns.suffix(7), usesMetric: usesMetric)
                Button("Share with Parent / Coach") {
                    shareReport()
                }
                .buttonStyle(VoltButtonStyle())
                Spacer()
            }
            .padding(20)
            .background(Color.matBG)
            .navigationTitle("Weekly Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { showReport = false } }
            }
        }
    }

    private func shareReport() {
        let renderer = ImageRenderer(content: WeeklyReportCardView(advice: latestAdvice, entries: weighIns.suffix(7), usesMetric: usesMetric).frame(width: 340).background(Color.matBG))
        renderer.scale = 2
        guard let image = renderer.uiImage else { return }
        let items = [image, "Takedown IQ weekly weight report — we coach the cut, not the crash."] as [Any]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first?.present(activityVC, animated: true)
    }

    private func logWeight() {
        guard let value = Double(weightInput), value > 0 else { return }
        let entry = WeighIn()
        entry.weightLB = usesMetric ? value / 2.20462 : value
        entry.date = .now
        modelContext.insert(entry)
        try? modelContext.save()
        weightInput = ""
        refreshAdvice()
    }

    private func refreshAdvice() {
        latestAdvice = SafeCutEngine.evaluate(history: weighIns, targetLB: profile.weightClassLB)
    }

    private var unitLabel: String { usesMetric ? "kg" : "lb" }

    private func converted(_ lb: Double) -> Double { usesMetric ? lb / 2.20462 : lb }

    private var yDomain: ClosedRange<Double> {
        let values = weighIns.map { converted($0.weightLB) }
        guard let minV = values.min(), let maxV = values.max(), maxV > minV else { return 0...100 }
        return (minV - 2)...(maxV + 2)
    }
}

struct WeeklyReportCardView: View {
    let advice: SafeCutAdvice
    let entries: [WeighIn]
    let usesMetric: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundStyle(Color.volt)
                Text("TAKEDOWN IQ — SAFE CUT REPORT")
                    .font(.caption.bold())
                    .foregroundStyle(Color.volt)
                Spacer()
            }
            Text(advice.headline)
                .font(.title3.weight(.heavy))
            Text(advice.detail)
                .font(.caption)
            if let first = entries.first, let last = entries.last {
                let delta = last.weightLB - first.weightLB
                Text(String(format: "7-day trend: %+.1f %@", converted(delta), usesMetric ? "kg" : "lb"))
                    .font(.subheadline.monospacedDigit())
            }
            Text("Verdict: \(verdictText)")
                .font(.caption.weight(.bold))
                .foregroundStyle(verdictColor)
            Text("We coach the cut, not the crash.")
                .font(.caption2.italic())
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var verdictText: String {
        switch advice.verdict {
        case .start: "Baseline"
        case .maintain: "Maintaining"
        case .pace: "On the safe curve"
        case .slowDown: "Slightly fast — slowing down"
        case .stop: "STOP — safety line crossed"
        }
    }

    private var verdictColor: Color {
        switch advice.verdict {
        case .stop: .matDanger
        case .slowDown: .matChance
        default: .matSuccess
        }
    }

    private func converted(_ lb: Double) -> Double { usesMetric ? lb / 2.20462 : lb }
}

struct HealthKitInfoView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 60)).foregroundStyle(.red)
                    Text("HealthKit Integration").font(.title.bold())
                    Text("Safe Cut reads your body weight from Apple Health through the HealthKit framework so your weigh-ins land on the safe curve automatically. This access is read-only and requires your explicit permission. No health data is written back to Apple Health.")
                        .multilineTextAlignment(.center).padding(.horizontal)
                }
            }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
