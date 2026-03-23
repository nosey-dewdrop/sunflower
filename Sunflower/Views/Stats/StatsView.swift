import SwiftUI
import SwiftData

enum StatsPeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSessions: [FocusSession]
    @Query private var flowers: [FlowerDrop]

    @State private var selectedPeriod: StatsPeriod = .week

    private var totalFlowers: Int { flowers.count }

    private var totalFocusHours: Double {
        Double(allSessions.reduce(0) { $0 + $1.duration }) / 3600.0
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let hasCompleted = allSessions.contains { session in
                session.completed && session.startedAt >= checkDate && session.startedAt < nextDay
            }
            if hasCompleted {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else if checkDate == calendar.startOfDay(for: Date()) {
                // Today might not have a session yet, check yesterday
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }
        return streak
    }

    private var chartData: [(label: String, minutes: Int)] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .day:
            // 24 hours of today
            let start = calendar.startOfDay(for: now)
            var data: [(String, Int)] = []
            for hour in 0..<24 {
                let hourStart = calendar.date(byAdding: .hour, value: hour, to: start)!
                let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
                let minutes = allSessions
                    .filter { $0.startedAt >= hourStart && $0.startedAt < hourEnd }
                    .reduce(0) { $0 + $1.duration } / 60
                data.append(("\(hour)", minutes))
            }
            return data

        case .week:
            var data: [(String, Int)] = []
            for dayOffset in (0..<7).reversed() {
                let day = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let dayStart = calendar.startOfDay(for: day)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                let minutes = allSessions
                    .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                    .reduce(0) { $0 + $1.duration } / 60
                let label = day.formatted(.dateTime.weekday(.abbreviated))
                data.append((label, minutes))
            }
            return data

        case .month:
            var data: [(String, Int)] = []
            for dayOffset in (0..<30).reversed() {
                let day = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let dayStart = calendar.startOfDay(for: day)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                let minutes = allSessions
                    .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                    .reduce(0) { $0 + $1.duration } / 60
                let label = dayOffset % 5 == 0 ? day.formatted(.dateTime.day()) : ""
                data.append((label, minutes))
            }
            return data
        }
    }

    private var maxMinutes: Int {
        max(chartData.map(\.minutes).max() ?? 1, 1)
    }

    var body: some View {
        ZStack {
            Color.darkGreen.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("Stats")
                        .pixelFont(size: 28, bold: true)
                        .foregroundColor(.cream)
                        .padding(.top, 60)

                    // Period picker
                    HStack(spacing: 0) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Button {
                                withAnimation { selectedPeriod = period }
                            } label: {
                                Text(period.rawValue)
                                    .pixelFont(size: 14, bold: selectedPeriod == period)
                                    .foregroundColor(selectedPeriod == period ? .darkGreen : .cream)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selectedPeriod == period ? Color.warmYellow : Color.clear)
                            }
                        }
                    }
                    .background(Color.grassGreen.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Bar chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("focus minutes")
                            .pixelFont(size: 12)
                            .foregroundColor(.cream.opacity(0.6))

                        HStack(alignment: .bottom, spacing: selectedPeriod == .month ? 1 : 4) {
                            ForEach(Array(chartData.enumerated()), id: \.offset) { _, item in
                                VStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(item.minutes > 0 ? Color.warmYellow : Color.grassGreen.opacity(0.3))
                                        .frame(height: max(CGFloat(item.minutes) / CGFloat(maxMinutes) * 120, 2))

                                    if !item.label.isEmpty && selectedPeriod != .month {
                                        Text(item.label)
                                            .pixelFont(size: 8)
                                            .foregroundColor(.cream.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 140)
                    }
                    .padding()
                    .background(Color.grassGreen.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Stats cards
                    HStack(spacing: 12) {
                        StatsCard(icon: "flame.fill", value: "\(currentStreak)", label: "day streak", iconColor: .orange)
                        StatsCard(icon: "sun.max.fill", value: "\(totalFlowers)", label: "flowers", iconColor: .warmYellow)
                    }

                    HStack(spacing: 12) {
                        StatsCard(icon: "clock.fill", value: String(format: "%.1f", totalFocusHours), label: "total hours", iconColor: .lightGreen)
                        StatsCard(icon: "checkmark.circle.fill", value: "\(allSessions.filter { $0.completed }.count)", label: "completed", iconColor: .warmYellow)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct StatsCard: View {
    let icon: String
    let value: String
    let label: String
    var iconColor: Color = .warmYellow

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            Text(value)
                .pixelFont(size: 22, bold: true)
                .foregroundColor(.cream)
            Text(label)
                .pixelFont(size: 11)
                .foregroundColor(.cream.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.grassGreen.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self], inMemory: true)
}
