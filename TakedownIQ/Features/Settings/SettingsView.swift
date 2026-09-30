import SwiftUI
import SwiftData
import StoreKit
import UserNotifications

struct SettingsView: View {
    @Binding var showPaywall: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showCoachChat = false
    @State private var showHealthKitInfo = false
    @State private var healthKitToggle = false

    var body: some View {
        NavigationStack {
            Form {
                coachSection
                proSection
                healthSection
                preferencesSection
                legalSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.matBG)
            .navigationTitle("Coach")
            .sheet(isPresented: $showCoachChat) { CoachChatView() }
            .sheet(isPresented: $showHealthKitInfo) { HealthKitInfoView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear {
                healthKitToggle = profiles.first?.healthKitEnabled ?? false
            }
        }
    }

    private var coachSection: some View {
        Section("Coach") {
            Button {
                showCoachChat = true
            } label: {
                Label("Ask Coach TD", systemImage: "bubble.left.and.text.bubble.right.fill")
                    .foregroundStyle(Color.volt)
            }
            NavigationLink {
                WeightView()
            } label: {
                Label("Safe Cut", systemImage: "scalemass.fill")
            }
        }
    }

    private var proSection: some View {
        Section("Takedown IQ Pro") {
            if purchaseManager.isPro {
                Label("Pro active — thanks for backing the app!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Color.matSuccess)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "bolt.fill")
                        .foregroundStyle(Color.volt)
                }
            }
            Button("Restore Purchases") {
                Task { await purchaseManager.restorePurchases() }
            }
            Button("Manage Subscription") { showManageSubscriptions() }
        }
    }

    private var healthSection: some View {
        Section {
            HStack {
                Image(systemName: "heart.circle.fill").foregroundStyle(.red).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HealthKit Integration").font(.headline)
                    Text("Read weight from Apple Health via HealthKit").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { showHealthKitInfo = true } label: {
                    Text("Learn More").font(.caption).foregroundStyle(.blue)
                }.buttonStyle(.plain)
            }.padding(.vertical, 2)
            Toggle("Sync weigh-ins to HealthKit", isOn: $healthKitToggle)
                .onChange(of: healthKitToggle) { enabled in
                    profiles.first?.healthKitEnabled = enabled
                    try? modelContext.save()
                    if enabled {
                        Task { _ = await HealthKitWeightService.shared.requestAuthorization() }
                    }
                }
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
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Use kilograms (kg)", isOn: Binding(
                get: { profiles.first?.usesMetric ?? false },
                set: { newValue in
                    profiles.first?.usesMetric = newValue
                    try? modelContext.save()
                }
            ))
            Toggle("Sunday weigh-in reminder", isOn: .constant(false))
                .disabled(true)
        }
    }

    private var legalSection: some View {
        Section("Legal & Support") {
            Link(destination: AppState.policyBaseURL.appending(path: "support.html")) {
                Label("Support", systemImage: "questionmark.circle")
            }
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
            Link(destination: AppState.policyBaseURL.appending(path: "privacy.html")) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: AppState.policyBaseURL.appending(path: "terms.html")) {
                Label("Terms of Use", systemImage: "doc.text")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            Text("13+ · Safe Cut content is educational, not medical advice. Never restrict fluids to make weight.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } footer: {
            Text(AppState.appVersion)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func showManageSubscriptions() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        Task { try? await AppStore.showManageSubscriptions(in: scene) }
    }
}
