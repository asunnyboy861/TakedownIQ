import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showPaywall = false

    private var hasOnboarded: Bool { profiles.first?.onboarded ?? false }

    var body: some View {
        Group {
            if hasOnboarded {
                TabView {
                    HomeView(showPaywall: $showPaywall)
                        .tabItem { Label("Home", systemImage: "flame.fill") }
                    PlanView()
                        .tabItem { Label("Plan", systemImage: "checklist") }
                    LibraryView()
                        .tabItem { Label("Library", systemImage: "books.vertical.fill") }
                    StatsView()
                        .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                    SettingsView(showPaywall: $showPaywall)
                        .tabItem { Label("Coach", systemImage: "person.crop.circle.fill") }
                }
                .sheet(isPresented: $showPaywall) { PaywallView() }
            } else {
                OnboardingView()
            }
        }
        .background(Color.matBG)
        .onAppear { ensureStreakState() }
    }

    private func ensureStreakState() {
        let descriptor = FetchDescriptor<StreakState>()
        if (try? modelContext.fetchCount(descriptor)) == 0 {
            modelContext.insert(StreakState())
        }
    }
}
