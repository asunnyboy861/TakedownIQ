import SwiftUI
import SwiftData

struct CoachChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.createdAt) private var messages: [ChatMessage]
    @Query private var profiles: [UserProfile]
    @Query private var streaks: [StreakState]
    @State private var input = ""
    @State private var sending = false
    @State private var showPaywall = false
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.matBG.ignoresSafeArea()
                VStack(spacing: 0) {
                    if !AppleAICoach.available {
                        fallbackBanner
                    }
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                if messages.isEmpty {
                                    emptyState
                                }
                                ForEach(messages) { message in
                                    bubble(message).id(message.id)
                                }
                                if sending {
                                    HStack {
                                        ProgressView().tint(.volt)
                                        Text("Coach TD is thinking...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .onChange(of: messages.count) { _ in
                            if let last = messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    inputBar
                }
            }
            .navigationTitle("Coach TD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    if !purchaseManager.isPro {
                        Button("Pro") { showPaywall = true }
                            .font(.caption.bold())
                            .foregroundStyle(Color.volt)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var fallbackBanner: some View {
        Label("Apple Intelligence needs iOS 26+ on this device — answers come from the built-in technique library instead.", systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(12)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 44))
                .foregroundStyle(Color.volt)
            Text("Ask Coach TD anything about technique.")
                .font(.headline)
            Text("\"My bottom game keeps getting broken down — what do I drill?\"")
                .font(.caption.italic())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                Text(message.text)
                    .font(.subheadline)
                    .textSelection(.enabled)
                drillChips(message)
            }
            .padding(12)
            .background(message.isUser ? AnyShapeStyle(Color.volt.opacity(0.18)) : AnyShapeStyle(Color.matSurface), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.primary)
            if !message.isUser { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private func drillChips(_ message: ChatMessage) -> some View {
        let matches = TechniqueLibrary.search(message.text).prefix(2)
        if !message.isUser, !matches.isEmpty {
            ForEach(Array(matches)) { technique in
                NavigationLink {
                    TechniqueDetailView(technique: technique)
                } label: {
                    Label("Drill: \(technique.title)", systemImage: "arrow.uturn.forward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.volt)
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about technique...", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 14))
                .onSubmit(send)
            Button {
                send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .tint(.volt)
            .disabled(sending || input.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Send question to Coach TD")
        }
        .padding(14)
        .background(Color.matSurface.opacity(0.6))
    }

    private func send() {
        let question = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !sending else { return }
        guard QuotaEngine.shared.canChat(isPro: purchaseManager.isPro) else {
            showPaywall = true
            return
        }
        input = ""
        sending = true
        let userMessage = ChatMessage()
        userMessage.roleRaw = "user"
        userMessage.text = question
        modelContext.insert(userMessage)
        try? modelContext.save()

        Task {
            let profile = profiles.first ?? UserProfile()
            let recent = TechniqueLibrary.all.prefix(6).map(\.id)
            var answer = ""
            if AppleAICoach.available, let reply = try? await AppleAICoach.coachAnswer(question: question, profile: profile, recentDrillIDs: Array(recent)) {
                answer = reply
            } else {
                answer = fallbackAnswer(for: question)
            }
            if SafeCutEngine.containsBlacklisted(question) {
                answer = "Weights are handled in the Safe Cut tab, let's keep it safe."
            } else {
                answer = SafeCutEngine.sanitize(answer)
            }
            let replyMessage = ChatMessage()
            replyMessage.roleRaw = "coach"
            replyMessage.text = answer
            modelContext.insert(replyMessage)
            QuotaEngine.shared.recordChat()
            if let streak = streaks.first {
                StreakEngine.touch(streak)
            }
            try? modelContext.save()
            sending = false
        }
    }

    private func fallbackAnswer(for question: String) -> String {
        let matches = TechniqueLibrary.search(question)
        if matches.isEmpty {
            return "I can't reach Apple Intelligence on this device, and nothing in the technique library matches that. Try asking about takedowns, escapes, rides, or turns — like \"how do I defend a half nelson?\""
        }
        let top = matches.prefix(2)
        let lines = top.map { tech in
            "\(tech.title): \(tech.summary) Key point — \(tech.keyPoints.first ?? "rep it clean")."
        }
        return lines.joined(separator: "\n") + "\n\nToday, drill: \(top.first?.title ?? "Stance & Motion") for 5 minutes."
    }
}
