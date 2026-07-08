import SwiftUI
import Foundation

// MARK: - Design tokens (centralized so Damla can tweak colors/doodles later)
// Everything the stats screens paint uses these — no scattered hex, no default gray.
enum StatsStyle {
    static let background = Color.grassGreen
    static let card = Color.white.opacity(0.25)
    static let cardStrong = Color.white.opacity(0.35)

    // bar / heatmap scale: light pastel -> deep green (never gray)
    static let heatEmpty = Color.white.opacity(0.14)
    static let heatLow = Color.lightGreen
    static let heatMid = Color.grassGreen
    static let heatHigh = Color.darkGreen

    static let barTop = Color.warmYellow
    static let barFill = Color.lightGreen
    static let barBest = Color.darkGreen

    static let corner: CGFloat = 18

    // shade a cell/bar between empty and deep by 0...1 intensity, staying on-palette
    static func heat(_ intensity: Double) -> Color {
        let t = min(max(intensity, 0), 1)
        if t <= 0 { return heatEmpty }
        if t < 0.34 { return heatLow.opacity(0.55 + t) }
        if t < 0.67 { return heatMid.opacity(0.85) }
        return heatHigh.opacity(0.85 + (t - 0.67) * 0.45)
    }
}

// MARK: - Period selector
enum StatsPeriod: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    var id: String { rawValue }
    var isPro: Bool { self != .day }
}

// MARK: - Aggregated results (value types, computed once per period change)
struct TagSlice: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let minutes: Int
}

struct DayBar: Identifiable {
    let id = UUID()
    let date: Date
    let label: String        // Mon..Sun
    let minutes: Int
    let isToday: Bool
}

struct HeatCell: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let minutes: Int
    let intensity: Double     // 0...1 vs the busiest day in the month
    let inMonth: Bool         // false for leading/trailing padding cells
    let isToday: Bool
}

struct PeriodStats {
    var totalMinutes: Int = 0
    var sessionCount: Int = 0
    var flowers: Int = 0
    var streak: Int = 0

    var tagSlices: [TagSlice] = []

    // week
    var dayBars: [DayBar] = []
    var bestDayLabel: String = ""
    var bestDayMinutes: Int = 0
    var averageMinutes: Int = 0

    // month
    var heatCells: [HeatCell] = []

    // trend vs previous period (nil = no comparable previous data)
    var previousMinutes: Int = 0
    var trendPercent: Double? = nil   // +/- fraction, e.g. 0.25 = up 25%
}

// MARK: - Aggregator
// Pure functions over a session snapshot. Callers compute ONCE on period/date/data change
// (never inside the render loop) and hold the result in @State.
enum StatsAggregator {
    static var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2 // Monday, matches the app's weekStartMonday default + garden week
        return c
    }

    // completed sessions only — an abandoned/incomplete session grew no flower and shouldn't inflate stats
    private static func completed(_ sessions: [FocusSession]) -> [FocusSession] {
        sessions.filter { $0.completed }
    }

    static func bounds(for period: StatsPeriod, containing date: Date) -> (start: Date, end: Date) {
        let c = cal
        switch period {
        case .day:
            let start = c.startOfDay(for: date)
            let end = c.date(byAdding: .day, value: 1, to: start) ?? start
            return (start, end)
        case .week:
            let start = c.dateInterval(of: .weekOfYear, for: date)?.start ?? c.startOfDay(for: date)
            let end = c.date(byAdding: .day, value: 7, to: start) ?? start
            return (start, end)
        case .month:
            let start = c.dateInterval(of: .month, for: date)?.start ?? c.startOfDay(for: date)
            let end = c.date(byAdding: .month, value: 1, to: start) ?? start
            return (start, end)
        }
    }

    static func shift(_ period: StatsPeriod, _ date: Date, by steps: Int) -> Date {
        let c = cal
        switch period {
        case .day:   return c.date(byAdding: .day, value: steps, to: date) ?? date
        case .week:  return c.date(byAdding: .weekOfYear, value: steps, to: date) ?? date
        case .month: return c.date(byAdding: .month, value: steps, to: date) ?? date
        }
    }

    // MARK: streak (mirrors GardenSnapshotWriter: survives until today's first session lands)
    static func currentStreak(_ sessions: [FocusSession]) -> Int {
        let c = cal
        let done = completed(sessions)
        let days = Set(done.map { c.startOfDay(for: $0.startedAt) })
        var streak = 0
        var day = c.startOfDay(for: Date())
        if !days.contains(day) {
            day = c.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while days.contains(day) {
            streak += 1
            day = c.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    static func compute(period: StatsPeriod,
                        date: Date,
                        sessions: [FocusSession],
                        flowers: [FlowerDrop]) -> PeriodStats {
        let c = cal
        let done = completed(sessions)
        let (start, end) = bounds(for: period, containing: date)

        let inRange = done.filter { $0.startedAt >= start && $0.startedAt < end }
        var s = PeriodStats()
        s.totalMinutes = inRange.reduce(0) { $0 + $1.duration / 60 }
        s.sessionCount = inRange.count
        s.flowers = flowers.filter { $0.earnedAt >= start && $0.earnedAt < end }.count
        s.streak = currentStreak(sessions)

        // tag breakdown
        var byTag: [UUID: (name: String, hex: String, minutes: Int)] = [:]
        for session in inRange {
            let minutes = session.duration / 60
            if let tag = session.tag {
                let existing = byTag[tag.id]
                byTag[tag.id] = (tag.name, tag.colorHex, (existing?.minutes ?? 0) + minutes)
            } else {
                let untaggedID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                let existing = byTag[untaggedID]
                byTag[untaggedID] = ("Focus", "7AAD2E", (existing?.minutes ?? 0) + minutes)
            }
        }
        s.tagSlices = byTag.map { TagSlice(id: $0.key, name: $0.value.name, colorHex: $0.value.hex, minutes: $0.value.minutes) }
            .filter { $0.minutes > 0 }
            .sorted { $0.minutes > $1.minutes }

        // trend vs previous same-length period
        let prevDate = shift(period, date, by: -1)
        let (pStart, pEnd) = bounds(for: period, containing: prevDate)
        s.previousMinutes = done.filter { $0.startedAt >= pStart && $0.startedAt < pEnd }
            .reduce(0) { $0 + $1.duration / 60 }
        if s.previousMinutes > 0 {
            s.trendPercent = (Double(s.totalMinutes) - Double(s.previousMinutes)) / Double(s.previousMinutes)
        } else if s.totalMinutes > 0 {
            s.trendPercent = 1.0 // brand new activity, all-up
        } else {
            s.trendPercent = nil
        }

        switch period {
        case .week:
            let letters = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            var bars: [DayBar] = []
            for i in 0..<7 {
                guard let d = c.date(byAdding: .day, value: i, to: start) else { continue }
                let dEnd = c.date(byAdding: .day, value: 1, to: d) ?? d
                let m = inRange.filter { $0.startedAt >= d && $0.startedAt < dEnd }
                    .reduce(0) { $0 + $1.duration / 60 }
                bars.append(DayBar(date: d, label: letters[i], minutes: m, isToday: c.isDateInToday(d)))
            }
            s.dayBars = bars
            let activeDays = bars.filter { $0.minutes > 0 }.count
            s.averageMinutes = activeDays > 0 ? s.totalMinutes / activeDays : 0
            if let best = bars.max(by: { $0.minutes < $1.minutes }), best.minutes > 0 {
                s.bestDayLabel = fullDayName(best.date)
                s.bestDayMinutes = best.minutes
            }

        case .month:
            // minutes per day in the month
            var perDay: [Int: Int] = [:]
            for session in inRange {
                let d = c.component(.day, from: session.startedAt)
                perDay[d, default: 0] += session.duration / 60
            }
            let maxDay = perDay.values.max() ?? 0
            let daysInMonth = c.range(of: .day, in: .month, for: start)?.count ?? 30
            // leading padding so the 1st lands under the right weekday column (Mon-first)
            let firstWeekday = c.component(.weekday, from: start) // 1=Sun..7=Sat
            let leadingPad = (firstWeekday + 5) % 7
            var cells: [HeatCell] = []
            for _ in 0..<leadingPad {
                cells.append(HeatCell(date: start, dayNumber: 0, minutes: 0, intensity: 0, inMonth: false, isToday: false))
            }
            for dayNum in 1...daysInMonth {
                let cellDate = c.date(byAdding: .day, value: dayNum - 1, to: start) ?? start
                let m = perDay[dayNum] ?? 0
                let intensity = maxDay > 0 ? Double(m) / Double(maxDay) : 0
                cells.append(HeatCell(date: cellDate, dayNumber: dayNum, minutes: m,
                                      intensity: intensity, inMonth: true, isToday: c.isDateInToday(cellDate)))
            }
            s.heatCells = cells
            let activeDays = perDay.values.filter { $0 > 0 }.count
            s.averageMinutes = activeDays > 0 ? s.totalMinutes / activeDays : 0
            if let best = perDay.max(by: { $0.value < $1.value }), best.value > 0 {
                let bestDate = c.date(byAdding: .day, value: best.key - 1, to: start) ?? start
                s.bestDayLabel = monthDayName(bestDate)
                s.bestDayMinutes = best.value
            }

        case .day:
            break
        }

        return s
    }

    // MARK: formatting helpers
    static func formatMinutes(_ minutes: Int) -> String {
        if minutes <= 0 { return "0m" }
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    private static let fullDay: DateFormatter = { let f = DateFormatter(); f.dateFormat = "EEEE"; return f }()
    private static let monthDay: DateFormatter = { let f = DateFormatter(); f.dateFormat = "MMM d"; return f }()
    static func fullDayName(_ d: Date) -> String { fullDay.string(from: d) }
    static func monthDayName(_ d: Date) -> String { monthDay.string(from: d) }

    // header title for the selected period
    static func title(for period: StatsPeriod, date: Date) -> String {
        let c = cal
        let f = DateFormatter()
        switch period {
        case .day:
            if c.isDateInToday(date) { f.dateFormat = "MMM d"; return f.string(from: date) + ", Today" }
            if c.isDateInYesterday(date) { f.dateFormat = "MMM d"; return f.string(from: date) + ", Yesterday" }
            f.dateFormat = "EEE, MMM d"; return f.string(from: date)
        case .week:
            let (start, end) = bounds(for: .week, containing: date)
            let last = c.date(byAdding: .day, value: -1, to: end) ?? end
            f.dateFormat = "MMM d"
            let a = f.string(from: start)
            f.dateFormat = c.isDate(start, equalTo: last, toGranularity: .month) ? "d" : "MMM d"
            return "\(a) – \(f.string(from: last))"
        case .month:
            f.dateFormat = "MMMM yyyy"; return f.string(from: date)
        }
    }

    // can the user move forward? (never past the current period)
    static func canGoForward(period: StatsPeriod, date: Date) -> Bool {
        let (start, _) = bounds(for: period, containing: Date())
        let (curStart, _) = bounds(for: period, containing: date)
        return curStart < start
    }
}
