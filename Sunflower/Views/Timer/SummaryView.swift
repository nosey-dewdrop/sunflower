import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query private var allSessions: [FocusSession]
    @Query private var flowers: [FlowerDrop]

    // Cached computed values to avoid recalculating on every render
    @State private var cachedTodaySessions: [FocusSession] = []
    @State private var cachedTotalFlowers: Int = 0
    @State private var cachedTotalFocusHours: Int = 0
    @State private var cachedTotalFocusMinutes: Int = 0
    @State private var cachedAllTimeFlowers: Int = 0
    @State private var cachedAllTimeFocusHours: Int = 0
    @State private var cachedAllTimeFocusMinutes: Int = 0
    @State private var cachedTodayCompletedCount: Int = 0
    @State private var cachedTodayAbandonedCount: Int = 0
    @State private var cachedTodayFocusHours: Int = 0
    @State private var cachedThisWeekFocusHours: Int = 0
    @State private var cachedWeekDays: [(letter: String, hasData: Bool)] = []
    @State private var cachedDateLabel: String = ""

    private static let summaryDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private func recomputeAll() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let todaySessions = allSessions.filter { $0.startedAt >= startOfDay }
        cachedTodaySessions = todaySessions

        let todayCompleted = todaySessions.filter { $0.completed }
        cachedTotalFlowers = todayCompleted.count
        cachedTodayCompletedCount = todayCompleted.count

        let todayTotalDuration = todaySessions.reduce(0) { $0 + $1.duration }
        cachedTotalFocusHours = todayTotalDuration / 3600
        cachedTotalFocusMinutes = (todayTotalDuration % 3600) / 60

        let allCompleted = allSessions.filter { $0.completed }
        cachedAllTimeFlowers = allCompleted.count

        let allTimeTotalDuration = allSessions.reduce(0) { $0 + $1.duration }
        cachedAllTimeFocusHours = allTimeTotalDuration / 3600
        cachedAllTimeFocusMinutes = (allTimeTotalDuration % 3600) / 60

        cachedTodayAbandonedCount = todaySessions.filter { $0.abandoned }.count

        let todayCompletedDuration = todayCompleted.reduce(0) { $0 + $1.duration }
        cachedTodayFocusHours = todayCompletedDuration / 3600

        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekCompletedDuration = allSessions
            .filter { $0.startedAt >= startOfWeek && $0.completed }
            .reduce(0) { $0 + $1.duration }
        cachedThisWeekFocusHours = weekCompletedDuration / 3600

        // Weekly dots
        let today = startOfDay
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else {
            cachedWeekDays = []
            return
        }

        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        // Build a set of day-start dates that have completed sessions for O(n) instead of O(7*n)
        let completedDayStarts = Set(
            allSessions
                .filter { $0.completed }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )

        cachedWeekDays = (0..<7).compactMap { i in
            guard let day = calendar.date(byAdding: .day, value: i, to: monday) else { return nil }
            let hasSession = completedDayStarts.contains(day)
            return (letter: letters[i], hasData: hasSession)
        }

        cachedDateLabel = Self.summaryDateFormatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            Color.grassGreen.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    HStack {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .padding(10)
                            .background(Color.white.opacity(0.3))
                            .clipShape(Circle())

                        Spacer()

                        HStack(spacing: 12) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text("Today")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.3))
                        .clipShape(Capsule())

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .padding(10)
                            .background(Color.white.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.top, 16)

                    // Summary title
                    Text("Summary")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    Text(cachedDateLabel + " ,Today")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)

                    // Total Flowers | Total Focus card
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total Flowers")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.textSecondary)
                            HStack(spacing: 6) {
                                Text("🌻")
                                    .font(.system(size: 20))
                                Text("\(cachedAllTimeFlowers)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Rectangle()
                            .fill(Color.darkGreen.opacity(0.2))
                            .frame(width: 1)
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total Focus")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.textSecondary)
                            HStack(spacing: 2) {
                                Text("\(cachedAllTimeFocusHours)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Text("h")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                                Text("\(cachedAllTimeFocusMinutes)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Text("m")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Focus Trend
                    Text("Focus Trend")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    VStack(spacing: 20) {
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Focus")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                                HStack(spacing: 2) {
                                    Text("\(cachedTodayFocusHours)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.textPrimary)
                                    Text("h")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Rectangle()
                                .fill(Color.darkGreen.opacity(0.2))
                                .frame(width: 1)
                                .padding(.vertical, 8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("This Week")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                                HStack(spacing: 2) {
                                    Text("\(cachedThisWeekFocusHours)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.textPrimary)
                                    Text("h")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                        }

                        // Weekly dots
                        HStack(spacing: 16) {
                            ForEach(Array(cachedWeekDays.enumerated()), id: \.offset) { _, day in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(day.hasData ? Color.darkGreen : Color.white.opacity(0.3))
                                        .frame(width: 20, height: 20)
                                    Text(day.letter)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Show All button
                    Button {} label: {
                        Text("Show All")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    // Flower Details
                    Text("Flower Details")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Today's Flowers")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.textSecondary)
                            HStack(spacing: 6) {
                                Text("🌻")
                                    .font(.system(size: 20))
                                Text("\(cachedTodayCompletedCount)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Rectangle()
                            .fill(Color.darkGreen.opacity(0.2))
                            .frame(width: 1)
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Abandoned")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.textSecondary)
                            HStack(spacing: 6) {
                                Text("🥀")
                                    .font(.system(size: 20))
                                Text("\(cachedTodayAbandonedCount)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            recomputeAll()
        }
        .onChange(of: allSessions.count) {
            recomputeAll()
        }
    }
}

#Preview {
    SummaryView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self], inMemory: true)
}
