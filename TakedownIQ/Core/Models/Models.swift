import Foundation
import SwiftData

enum WrestlerLevel: String, CaseIterable, Codable, Identifiable {
    case beginner = "1-3 years"
    case intermediate = "4+ years"
    case veteran = "Veteran"
    var id: String { rawValue }
}

enum WrestlerPosition: String, CaseIterable, Codable, Identifiable {
    case neutral = "Neutral"
    case top = "Top"
    case bottom = "Bottom"
    case all = "All Positions"
    var id: String { rawValue }
}

enum EventKind: String, Codable {
    case mistake, good, chance
}

enum BreakdownStatus: String, Codable {
    case queued, running, done, failed
}

@Model
final class UserProfile {
    var id = UUID()
    var createdAt = Date.now
    var levelRaw: String = WrestlerLevel.beginner.rawValue
    var positionRaw: String = WrestlerPosition.all.rawValue
    var weeksToEvent: Int = 8
    var weeklyDays: Int = 4
    var weightClassLB: Double = 0
    var usesMetric: Bool = false
    var weighInWeekday: Int = 1
    var onboarded: Bool = false
    var healthKitEnabled: Bool = false

    init() {}

    var level: WrestlerLevel {
        get { WrestlerLevel(rawValue: levelRaw) ?? .beginner }
        set { levelRaw = newValue.rawValue }
    }
    var position: WrestlerPosition {
        get { WrestlerPosition(rawValue: positionRaw) ?? .all }
        set { positionRaw = newValue.rawValue }
    }
}

@Model
final class BreakdownResult {
    var id = UUID()
    var createdAt = Date.now
    var videoLocalPath: String?
    var duration: Double = 0
    var summary: String = ""
    var topDrillIDs: [String] = []
    var statusRaw: String = BreakdownStatus.queued.rawValue
    var identityContext: String = ""

    @Relationship(deleteRule: .cascade, inverse: \EventObservation.result)
    var events: [EventObservation]? = []

    init() {}

    init(videoLocalPath: String?, duration: Double) {
        self.videoLocalPath = videoLocalPath
        self.duration = duration
    }

    var status: BreakdownStatus {
        get { BreakdownStatus(rawValue: statusRaw) ?? .queued }
        set { statusRaw = newValue.rawValue }
    }
    var sortedEvents: [EventObservation] {
        (events ?? []).sorted { $0.t < $1.t }
    }
}

@Model
final class EventObservation {
    var id = UUID()
    var t: Double = 0
    var kindRaw: String = EventKind.chance.rawValue
    var title: String = ""
    var whereText: String = ""
    var whyText: String = ""
    var drillID: String = ""
    var confidence: Double = 0
    var unclear: Bool = false
    var thumbPath: String?
    var isFixed: Bool = false
    var result: BreakdownResult?

    init() {}

    var kind: EventKind {
        get { EventKind(rawValue: kindRaw) ?? .chance }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class DrillItem {
    var id = UUID()
    var createdAt = Date.now
    var day = Calendar.current.startOfDay(for: .now)
    var title: String = ""
    var minutes: Int = 5
    var focusRaw: String = "neutral"
    var cue: String = ""
    var done: Bool = false
    var order: Int = 0
    var sourceBreakdownID: String?

    init() {}
}

@Model
final class MatchRecord {
    var id = UUID()
    var date = Date.now
    var won: Bool = true
    var byPin: Bool = false
    var pointsFor: Int = 0
    var pointsAgainst: Int = 0
    var opponent: String = ""
    var notes: String = ""

    init() {}
}

@Model
final class WeighIn {
    var id = UUID()
    var date = Date.now
    var weightLB: Double = 0
    var hydrationOK: Bool = true

    init() {}
}

@Model
final class StreakState {
    var id = UUID()
    var current: Int = 0
    var best: Int = 0
    var lastDay = Date.distantPast
    var reviveMonth: Int = -1
    var reviveUsed: Bool = false

    init() {}
}

@Model
final class ChatMessage {
    var id = UUID()
    var createdAt = Date.now
    var roleRaw: String = "user"
    var text: String = ""

    init() {}

    var isUser: Bool { roleRaw == "user" }
}
