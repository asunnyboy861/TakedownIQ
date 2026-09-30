import SwiftUI

struct LibraryView: View {
    @State private var query = ""
    @State private var filter: String?

    private var filtered: [Technique] {
        var list = TechniqueLibrary.search(query)
        if let filter {
            list = list.filter { $0.position == filter }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.matBG.ignoresSafeArea()
                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip(nil, label: "All")
                            filterChip("neutral", label: "Neutral")
                            filterChip("top", label: "Top")
                            filterChip("bottom", label: "Bottom")
                            filterChip("conditioning", label: "Conditioning")
                        }
                        .padding(.horizontal, 16)
                    }
                    List {
                        ForEach(filtered) { technique in
                            NavigationLink {
                                TechniqueDetailView(technique: technique)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(technique.title)
                                        .font(.headline)
                                    Text("\(technique.position) · \(technique.summary)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .listRowBackground(Color.matSurface)
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $query, prompt: "Search techniques")
                }
                .padding(.top, 8)
            }
            .navigationTitle("Library")
        }
    }

    private func filterChip(_ value: String?, label: String) -> some View {
        Button {
            filter = (filter == value) ? nil : value
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(filter == value ? Color.volt : Color.matSurface, in: Capsule())
                .foregroundStyle(filter == value ? .black : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct TechniqueDetailView: View {
    let technique: Technique

    var body: some View {
        ZStack {
            Color.matBG.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(technique.title)
                        .font(.largeTitle.weight(.heavy))
                    Text(technique.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    section("STEPS", systemImage: "list.number", items: technique.steps, color: .volt)
                    section("KEY POINTS", systemImage: "key.fill", items: technique.keyPoints, color: .matSuccess)
                    section("COMMON MISTAKES", systemImage: "exclamationmark.triangle.fill", items: technique.commonMistakes, color: .matDanger)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, systemImage: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundStyle(color)
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .matCard()
    }
}
