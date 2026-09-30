import Foundation

enum SafeCutVerdict: Equatable {
    case start
    case maintain
    case pace
    case slowDown
    case stop
}

struct SafeCutAdvice {
    let verdict: SafeCutVerdict
    let headline: String
    let detail: String
    let weeklyRate: Double
}

struct SafeCutEngine {
    static let blacklist = [
        "dehydrate", "dehydration", "sauna", "spit", "spitting", "laxative",
        "diuretic", "water pill", "skip meals", "starve", "starving", "fasting",
        "vomit", "throw up", "purge", "sweat suit", "rubber suit", "no water"
    ]

    static func evaluate(history: [WeighIn], targetLB: Double) -> SafeCutAdvice {
        let sorted = history.sorted { $0.date < $1.date }
        guard let latest = sorted.last else {
            return SafeCutAdvice(verdict: .start,
                                 headline: "Let's set your baseline",
                                 detail: "Log your first weigh-in to start the safe curve.",
                                 weeklyRate: 0)
        }
        guard targetLB > 0, latest.weightLB > 0 else {
            return SafeCutAdvice(verdict: .maintain,
                                 headline: "Weigh-in logged ✅",
                                 detail: "Set a target weight class to unlock the safe curve.",
                                 weeklyRate: 0)
        }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: latest.date)!
        guard let base = sorted.last(where: { $0.date <= weekAgo }) ?? sorted.first, base.id != latest.id else {
            return SafeCutAdvice(verdict: .maintain,
                                 headline: "Baseline week",
                                 detail: "Keep logging daily — your safe curve builds after 7 days.",
                                 weeklyRate: 0)
        }
        let lost = base.weightLB - latest.weightLB
        let rate = lost / max(base.weightLB, 1) * 100
        switch rate {
        case ..<0:
            return SafeCutAdvice(verdict: .maintain,
                                 headline: "Weight holding steady",
                                 detail: "Great spot to build strength. Keep eating and training.",
                                 weeklyRate: rate)
        case ..<1.0:
            return SafeCutAdvice(verdict: .pace,
                                 headline: "Pace is perfect ✅",
                                 detail: String(format: "You're cutting %.1f%% this week — right on the safe curve. Keep protein high and salt normal.", rate),
                                 weeklyRate: rate)
        case ..<1.5:
            return SafeCutAdvice(verdict: .slowDown,
                                 headline: "A little fast ⚠️",
                                 detail: String(format: "%.1f%% this week is ahead of the safe curve. Add ~200 kcal per day from carbs and keep drinking water.", rate),
                                 weeklyRate: rate)
        default:
            return SafeCutAdvice(verdict: .stop,
                                 headline: "STOP the cut 🚨",
                                 detail: String(format: "%.1f%% per week crosses the safety line. Move up a weight class or push your weigh-in date. Complete the hydration check and talk to your coach or parent.", rate),
                                 weeklyRate: rate)
        }
    }

    static func sanitize(_ text: String) -> String {
        var output = text
        for term in blacklist {
            output = output.replacingOccurrences(of: term, with: "[removed]", options: .caseInsensitive)
        }
        return output
    }

    static func containsBlacklisted(_ text: String) -> Bool {
        blacklist.contains { text.lowercased().contains($0) }
    }
}
