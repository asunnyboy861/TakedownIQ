import Foundation

struct PlanTemplates {
    static let library: [DrillDraft] = [
        DrillDraft(title: "Stance & Motion Shadow", minutes: 4, focus: "neutral", cue: "Feet never stop, hands stay high"),
        DrillDraft(title: "Level Change Ladder", minutes: 4, focus: "neutral", cue: "Hips down, chest tall, no waist bend"),
        DrillDraft(title: "Penetration Step Reps", minutes: 5, focus: "neutral", cue: "Long step past the foot, back knee drops"),
        DrillDraft(title: "Sprawl & Re-Shot", minutes: 5, focus: "neutral", cue: "Hips to the mat, circle, attack again"),
        DrillDraft(title: "Double-Leg Finishes", minutes: 6, focus: "neutral", cue: "Head tight to the side, run the corner"),
        DrillDraft(title: "Hand Fight Circles", minutes: 4, focus: "neutral", cue: "Win the inside wrist before you shoot"),
        DrillDraft(title: "Stand-Up Escapes", minutes: 5, focus: "bottom", cue: "Straight up the ladder, then hand fight"),
        DrillDraft(title: "Sit-Out Turns", minutes: 5, focus: "bottom", cue: "Sit into the hole they give you"),
        DrillDraft(title: "Hip Heist Timing", minutes: 6, focus: "bottom", cue: "Heist as their weight shifts, not before"),
        DrillDraft(title: "Switch Reversals", minutes: 5, focus: "bottom", cue: "Block the near leg as you switch hips"),
        DrillDraft(title: "Near Arm Far Leg", minutes: 5, focus: "top", cue: "Kill the near arm before anything else"),
        DrillDraft(title: "Tilt Series", minutes: 6, focus: "top", cue: "Near wrist locked to your chest"),
        DrillDraft(title: "Cradle Locks", minutes: 6, focus: "top", cue: "Head and knee must touch, squeeze"),
        DrillDraft(title: "Leg Riding Switches", minutes: 6, focus: "top", cue: "Stay on your hip, never go flat"),
        DrillDraft(title: "Front Headlock Spin", minutes: 5, focus: "top", cue: "Near wrist dead, then spin behind"),
        DrillDraft(title: "Conditioning Circuit", minutes: 8, focus: "conditioning", cue: "Sprawl, stand-up, re-shot — 6 rounds")
    ]

    static func todayPlan(profile: UserProfile) -> DrillPlanDraft {
        let focus: String
        switch profile.position {
        case .neutral: focus = "neutral"
        case .top: focus = "top"
        case .bottom: focus = "bottom"
        case .all: focus = ["neutral", "bottom", "top"][Int.random(in: 0...2)]
        }
        var pool = library.filter { $0.focus == focus }
        let conditioning = library.filter { $0.focus == "conditioning" }
        pool.shuffle()
        let count = profile.weeklyDays >= 5 ? 5 : 4
        var picked = Array(pool.prefix(count - 1))
        picked.append(conditioning.randomElement() ?? conditioning[0])
        let hype = ["Own the mat today.", "Little wins stack up.", "Stay heavy, stay sharp.", "Fix one thing today."].randomElement()!
        return DrillPlanDraft(drills: picked, hype: hype)
    }

    static func drillsFromPrescriptions(_ drillIDs: [String]) -> [DrillDraft] {
        drillIDs.compactMap { id in
            guard let tech = TechniqueLibrary.technique(forID: id) else { return nil }
            return DrillDraft(title: tech.title, minutes: 5, focus: tech.position, cue: tech.keyPoints.first ?? "Rep it clean")
        }
    }
}
