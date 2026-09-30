import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MatchRecord.date, order: .reverse) private var matches: [MatchRecord]
    @State private var showAdd = false
    @State private var newWon = true
    @State private var newByPin = false
    @State private var newFor = "3"
    @State private var newAgainst = "0"
    @State private var newOpponent = ""

    private var wins: Int { matches.filter(\.won).count }
    private var pins: Int { matches.filter { $0.won && $0.byPin }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.matBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        summaryRow
                        badgeWall
                        matchList
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add match result")
                }
            }
            .sheet(isPresented: $showAdd) { addSheet }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            statCard("\(wins)", "WINS", .matSuccess)
            statCard("\(matches.count - wins)", "LOSSES", .matDanger)
            statCard("\(pins)", "PINS", .volt)
            statCard(String(format: "%.0f%%", matches.isEmpty ? 0 : Double(wins) / Double(matches.count) * 100), "WIN %", .matChance)
        }
    }

    private func statCard(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, weight: .heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var badgeWall: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MILESTONES")
                .font(.caption.bold())
                .foregroundStyle(Color.volt)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    milestone(icon: "1.circle.fill", label: "First Win", unlocked: wins >= 1)
                    milestone(icon: "10.circle.fill", label: "10 Wins", unlocked: wins >= 10)
                    milestone(icon: "25.circle.fill", label: "25 Wins", unlocked: wins >= 25)
                    milestone(icon: "50.circle.fill", label: "50 Wins", unlocked: wins >= 50)
                    milestone(icon: "100.circle.fill", label: "100 Wins", unlocked: wins >= 100)
                    milestone(icon: "pin.fill", label: "First Pin", unlocked: pins >= 1)
                }
            }
        }
        .matCard()
    }

    private func milestone(icon: String, label: String, unlocked: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: unlocked ? icon : "lock.circle")
                .font(.system(size: 34))
                .foregroundStyle(unlocked ? Color.volt : Color.white.opacity(0.15))
            Text(label)
                .font(.caption2)
                .foregroundStyle(unlocked ? .primary : .secondary)
        }
        .frame(width: 84)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(unlocked ? "unlocked" : "locked")")
    }

    private var matchList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MATCH LOG")
                .font(.caption.bold())
                .foregroundStyle(Color.volt)
            if matches.isEmpty {
                Text("No matches yet. Log your first result — every state champ started at zero.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(matches) { match in
                HStack {
                    Image(systemName: match.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(match.won ? Color.matSuccess : Color.matDanger)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.byPin ? "WIN by PIN" : "\(match.pointsFor)–\(match.pointsAgainst)")
                            .font(.headline)
                        if !match.opponent.isEmpty {
                            Text("vs \(match.opponent)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(match.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .matCard()
    }

    private var addSheet: some View {
        NavigationStack {
            Form {
                Section("Result") {
                    Picker("Outcome", selection: $newWon) {
                        Text("Win").tag(true)
                        Text("Loss").tag(false)
                    }
                    .pickerStyle(.segmented)
                    Toggle("Won by pin", isOn: $newByPin)
                    TextField("Points for", text: $newFor)
                        .keyboardType(.numberPad)
                    TextField("Points against", text: $newAgainst)
                        .keyboardType(.numberPad)
                }
                Section("Details") {
                    TextField("Opponent (optional)", text: $newOpponent)
                }
            }
            .navigationTitle("Log Match")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMatch() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveMatch() {
        let record = MatchRecord()
        record.won = newWon
        record.byPin = newWon && newByPin
        record.pointsFor = Int(newFor) ?? 0
        record.pointsAgainst = Int(newAgainst) ?? 0
        record.opponent = newOpponent
        modelContext.insert(record)
        try? modelContext.save()
        newWon = true
        newByPin = false
        newFor = "3"
        newAgainst = "0"
        newOpponent = ""
        showAdd = false
    }
}
