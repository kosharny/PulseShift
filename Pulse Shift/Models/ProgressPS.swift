import Foundation

struct ChapterPS: Identifiable {
    var id: Int
    var name: String
    var subtitle: String
    var symbol: String
    static let all: [Self] = [
        .init(id: 1, name: "FIRST PULSE", subtitle: "Every signal starts somewhere.", symbol: "arrow.up.right"),
        .init(id: 2, name: "VECTOR", subtitle: "Find a new direction.", symbol: "arrow.triangle.branch"),
        .init(id: 3, name: "CIRCUIT", subtitle: "One touch. Everything connects.", symbol: "point.3.connected.trianglepath.dotted"),
        .init(id: 4, name: "PHASE", subtitle: "Distance is an illusion.", symbol: "circle.hexagongrid"),
        .init(id: 5, name: "POLARITY", subtitle: "Opposites change everything.", symbol: "plus.forwardslash.minus"),
        .init(id: 6, name: "OVERLOAD", subtitle: "Bring the whole system to life.", symbol: "bolt.shield")
    ]
}

struct DailyChallengePS {
    var key: String
    var date: Date
    var level: LevelPS
}

struct DailyChallengeServicePS {
    var calendar: Calendar = .current
    func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
    func weekKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(c.yearForWeekOfYear ?? 0)-W\(c.weekOfYear ?? 0)"
    }
    func daily(date: Date, levels: [LevelPS]) -> DailyChallengePS? {
        let templates = levels.filter { $0.chapter >= 3 }
        guard !templates.isEmpty else { return nil }
        let seed = dayKey(date).utf8.reduce(0) { ($0 * 31 + Int($1)) % 1_000_003 }
        return .init(key: dayKey(date), date: date, level: templates[seed % templates.count])
    }
    func streak(completedDays: Set<String>, today: Date) -> Int {
        var cursor = calendar.startOfDay(for: today)
        if !completedDays.contains(dayKey(cursor)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while completedDays.contains(dayKey(cursor)), count < completedDays.count {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }
}

struct AchievementPS: Identifiable {
    var id: String
    var title: String
    var description: String
    var symbol: String
    var value: Int
    var target: Int
    var unlocked: Bool { value >= target }
}
