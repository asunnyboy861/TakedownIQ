import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct DrillPlanDraft: Sendable {
    var drills: [DrillDraft]
    var hype: String
}

struct DrillDraft: Sendable {
    var title: String
    var minutes: Int
    var focus: String
    var cue: String
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct FMPlan {
    @Guide(description: "3 to 5 drills, 15 to 20 minutes total")
    var drills: [FMDrill]
    @Guide(description: "one hype sentence <=12 words")
    var hype: String
}

@available(iOS 26.0, *)
@Generable
struct FMDrill {
    @Guide(description: "drill name, <=6 words")
    var title: String
    @Guide(description: "minutes, 3 to 8")
    var minutes: Int
    @Guide(description: "neutral, top, bottom, or conditioning")
    var focus: String
    @Guide(description: "single coaching cue, <=12 words")
    var cue: String
}
#endif

enum AppleAICoach {
    static var available: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return true }
        #endif
        return false
    }

    static func coachAnswer(question: String, profile: UserProfile, recentDrillIDs: [String]) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: """
            You are Coach TD inside the Takedown IQ app. Voice: direct, positive, USA wrestling coach. Answer in <=120 words, always end with ONE concrete drill the wrestler can do today (from library if possible: \(recentDrillIDs.prefix(6))). Never give weight-cutting, dehydration, sauna, or supplement advice — for weight topics reply exactly: "Weights are handled in the Safe Cut tab, let's keep it safe." Wrestler: \(profile.levelRaw), focus \(profile.positionRaw), event in \(profile.weeksToEvent) weeks.
            """)
            let reply = try await session.respond(to: question)
            return reply.content
        }
        #endif
        throw AIError.unavailable
    }

    static func todayPlan(profile: UserProfile) async throws -> DrillPlanDraft {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: """
            Build a folkstyle drill plan for a \(profile.levelRaw) wrestler, focus \(profile.positionRaw), \(profile.weeklyDays) days per week, event in \(profile.weeksToEvent) weeks. Never include weight-cutting content.
            """)
            let response = try await session.respond(to: "Today's plan", generating: FMPlan.self)
            let plan = response.content
            return DrillPlanDraft(
                drills: plan.drills.map { DrillDraft(title: $0.title, minutes: $0.minutes, focus: $0.focus, cue: $0.cue) },
                hype: plan.hype
            )
        }
        #endif
        throw AIError.unavailable
    }
}

extension AIError {
    static let unavailable = AIError.upstream
}
