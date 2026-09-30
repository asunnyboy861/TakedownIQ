import Foundation

struct QuotaEngine {
    static let shared = QuotaEngine()
    private let freeDailyBreakdowns = 1
    private let proDailyBreakdowns = 30
    private let freeDailyChats = 5

    private func count(forKey key: String) -> Int {
        let day = Self.dayKey(Date())
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] else { return 0 }
        return dict[day] ?? 0
    }

    private func bump(forKey key: String) {
        let day = Self.dayKey(Date())
        var dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] ?? [:]
        dict = dict.filter { $0.key == day }
        dict[day, default: 0] += 1
        UserDefaults.standard.set(dict, forKey: key)
    }

    func breakdownsUsedToday(isPro: Bool) -> Int {
        _ = isPro
        return count(forKey: "quota.breakdown")
    }

    func canRunBreakdown(isPro: Bool) -> Bool {
        let limit = isPro ? proDailyBreakdowns : freeDailyBreakdowns
        return count(forKey: "quota.breakdown") < limit
    }

    func recordBreakdownRun() {
        bump(forKey: "quota.breakdown")
    }

    func chatsUsedToday() -> Int {
        count(forKey: "quota.chat")
    }

    func canChat(isPro: Bool) -> Bool {
        isPro || count(forKey: "quota.chat") < freeDailyChats
    }

    func recordChat() {
        bump(forKey: "quota.chat")
    }

    static func dayKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}

struct StreakEngine {
    static func touch(_ store: StreakState, on date: Date = .now) {
        let cal = Calendar.current
        if cal.isDate(store.lastDay, inSameDayAs: date) { return }
        let gap = cal.dateComponents([.day], from: cal.startOfDay(for: store.lastDay), to: cal.startOfDay(for: date)).day ?? 99
        if gap == 1 {
            store.current += 1
        } else if gap == 2, store.reviveMonth == cal.component(.month, from: date), !store.reviveUsed {
            store.reviveUsed = true
            store.current += 1
        } else {
            store.current = 1
        }
        store.best = max(store.best, store.current)
        store.lastDay = date
        let month = cal.component(.month, from: date)
        if store.reviveMonth != month {
            store.reviveMonth = month
            store.reviveUsed = false
        }
    }
}
