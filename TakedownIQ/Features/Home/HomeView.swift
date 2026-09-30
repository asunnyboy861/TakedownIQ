import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var filmVM: FilmViewModel
    @Binding var showPaywall: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var streaks: [StreakState]
    @Query private var results: [BreakdownResult]
    @Query(filter: #Predicate<DrillItem> { !$0.done }) private var pendingDrills: [DrillItem]
    @Query(filter: #Predicate<EventObservation> { $0.isFixed }) private var fixedEvents: [EventObservation]
    @Query(filter: #Predicate<EventObservation> { $0.kindRaw == "mistake" }) private var mistakeEvents: [EventObservation]
    @State private var showFilm = false
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.matBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerRow
                        filmButton
                        quotaCard
                        drillsPreview
                        fixRateCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Takedown IQ")
            .fullScreenCover(isPresented: $showFilm) { FilmCaptureView() }
            .sheet(item: $resultToShow) { result in
                NavigationStack { BreakdownResultView(result: result) }
            }
            .onReceive(filmVM.$activeResult) { newResult in
                if let newResult {
                    showFilm = false
                    filmVM.activeResult = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        resultToShow = newResult
                    }
                }
            }
        }
    }

    @State private var resultToShow: BreakdownResult?

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label("\(streaks.first?.current ?? 0)", systemImage: "flame.fill")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(Color.volt)
                    .accessibilityLabel("Current streak \(streaks.first?.current ?? 0) days")
                Text("day streak · best \(streaks.first?.best ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            NavigationLink {
                PaywallView()
            } label: {
                Text(purchaseManager.isPro ? "PRO" : "FREE")
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(purchaseManager.isPro ? Color.volt : Color.matSurface, in: Capsule())
                    .foregroundStyle(purchaseManager.isPro ? .black : .secondary)
            }
        }
    }

    private var filmButton: some View {
        Button {
            showFilm = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "camera.fill")
                Text("FILM IT")
            }
        }
        .buttonStyle(VoltButtonStyle())
        .frame(height: 120)
        .accessibilityHint("Film or pick a match video for AI breakdown")
    }

    private var quotaCard: some View {
        let used = QuotaEngine.shared.breakdownsUsedToday(isPro: purchaseManager.isPro)
        let limit = purchaseManager.isPro ? 30 : 1
        return HStack {
            Gauge(value: Double(min(used, limit)), in: 0...Double(limit)) {
                Image(systemName: "film.stack")
            } currentValueLabel: {
                Text("\(max(limit - used, 0)) left")
                    .font(.caption.bold())
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.volt)
            VStack(alignment: .leading, spacing: 2) {
                Text(purchaseManager.isPro ? "Pro breakdowns today: \(used)" : "Free breakdowns today: \(used)/1")
                    .font(.subheadline.weight(.semibold))
                if !purchaseManager.isPro {
                    Button("Unlimited with Pro") { showPaywall = true }
                        .font(.caption)
                        .foregroundStyle(Color.volt)
                }
            }
            Spacer()
        }
        .matCard()
    }

    private var drillsPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY'S DRILLS")
                .font(.caption.bold())
                .foregroundStyle(Color.volt)
            if pendingDrills.isEmpty {
                Text("All drills done. Tomorrow's plan is loading.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(pendingDrills.sorted { $0.order < $1.order }.prefix(3)) { drill in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundStyle(Color.volt)
                        Text(drill.title)
                            .font(.subheadline)
                        Spacer()
                        Text("\(drill.minutes) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .matCard()
        .contentShape(Rectangle())
        .onTapGesture { }
    }

    private var fixRateCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FIX RATE")
                .font(.caption.bold())
                .foregroundStyle(Color.volt)
            Text("Fixed \(fixedEvents.count) of \(mistakeEvents.count) mistakes")
                .font(.system(.title2, weight: .heavy))
            Text("Mark mistakes fixed on your breakdown cards as you drill them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .matCard()
    }
}
