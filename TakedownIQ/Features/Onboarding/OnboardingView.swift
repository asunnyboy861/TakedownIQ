import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var page = 0
    @State private var level = WrestlerLevel.beginner
    @State private var position = WrestlerPosition.all
    @State private var weeksToEvent = 8.0
    @State private var weeklyDays = 4
    @State private var generating = false

    var body: some View {
        ZStack {
            Color.matBG.ignoresSafeArea()
            VStack(spacing: 24) {
                if page == 0 { valuePage }
                else if page == 1 { quizPage }
                else { permissionPage }
            }
            .padding(24)
        }
        .accessibilityLabel("Onboarding")
    }

    private var valuePage: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("FILM")
                .font(.system(size: 64, weight: .heavy)).foregroundStyle(Color.volt)
            Text("FIX")
                .font(.system(size: 64, weight: .heavy)).foregroundStyle(Color.matSuccess)
            Text("WIN")
                .font(.system(size: 64, weight: .heavy)).foregroundStyle(Color.matDanger)
            Spacer()
            Text("Your AI wrestling coach watches your film and tells you exactly which 2 seconds you lost — and the drill that fixes it.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { withAnimation { page = 1 } }) {
                Text("GET STARTED")
            }
            .buttonStyle(VoltButtonStyle())
        }
    }

    private var quizPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("15 seconds.\n4 questions.")
                    .font(.largeTitle.weight(.heavy))
                questionLabel("Where do you want to get better?")
                ForEach(WrestlerPosition.allCases) { p in
                    choiceRow(title: p.rawValue, selected: position == p) { position = p }
                }
                questionLabel("How long have you been wrestling?")
                ForEach(WrestlerLevel.allCases) { l in
                    choiceRow(title: l.rawValue, selected: level == l) { level = l }
                }
                questionLabel("Big event in \(Int(weeksToEvent)) weeks")
                Slider(value: $weeksToEvent, in: 1...24, step: 1)
                    .tint(.volt)
                questionLabel("Days per week")
                Stepper("\(weeklyDays) days", value: $weeklyDays, in: 1...7)
                    .tint(.volt)
                Button(action: { withAnimation { page = 2 } }) {
                    Text("NEXT")
                }
                .buttonStyle(VoltButtonStyle())
            }
        }
    }

    private var permissionPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("3 quick permissions.\nAll optional.")
                .font(.largeTitle.weight(.heavy))
                .multilineTextAlignment(.center)
            permissionRow(icon: "camera.fill", title: "Camera", detail: "Film your matches for breakdowns")
            permissionRow(icon: "photo.on.rectangle", title: "Photo Library", detail: "Pick videos you already filmed")
            permissionRow(icon: "bell.fill", title: "Notifications", detail: "Weigh-in reminders and streak nudges")
            Text("Say no to any of these — the app still works.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(action: finish) {
                if generating {
                    ProgressView().tint(.black)
                } else {
                    Text("BUILD MY PLAN")
                }
            }
            .buttonStyle(VoltButtonStyle())
            .disabled(generating)
            Spacer()
        }
    }

    private func questionLabel(_ text: String) -> some View {
        Text(text).font(.headline).foregroundStyle(Color.volt)
    }

    private func choiceRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
            }
            .padding(14)
            .background(selected ? Color.volt.opacity(0.15) : Color.matSurface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? Color.volt : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private func permissionRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.volt)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .matCard()
    }

    private func finish() {
        generating = true
        let profile = profiles.first ?? {
            let p = UserProfile()
            modelContext.insert(p)
            return p
        }()
        profile.level = level
        profile.position = position
        profile.weeksToEvent = Int(weeksToEvent)
        profile.weeklyDays = weeklyDays
        profile.onboarded = true
        try? modelContext.save()

        Task {
            let plan: DrillPlanDraft
            if AppleAICoach.available, let fm = try? await AppleAICoach.todayPlan(profile: profile) {
                plan = fm
            } else {
                plan = PlanTemplates.todayPlan(profile: profile)
            }
            let today = Calendar.current.startOfDay(for: .now)
            for (index, drill) in plan.drills.enumerated() {
                let item = DrillItem()
                item.day = today
                item.title = drill.title
                item.minutes = drill.minutes
                item.focusRaw = drill.focus
                item.cue = drill.cue
                item.order = index
                modelContext.insert(item)
            }
            try? modelContext.save()
            await MainActor.run { generating = false }
        }
    }
}
