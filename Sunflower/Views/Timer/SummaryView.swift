import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query private var allSessions: [FocusSession]
    @Query private var flowers: [FlowerDrop]

    private var todaySessions: [FocusSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return allSessions.filter { $0.startedAt >= startOfDay }
    }

    private var totalFlowers: Int {
        todaySessions.filter { $0.completed }.count
    }

    private var totalFocusHours: Int {
        todaySessions.reduce(0) { $0 + $1.duration } / 3600
    }

    private var totalFocusMinutes: Int {
        (todaySessions.reduce(0) { $0 + $1.duration } % 3600) / 60
    }

    private var allTimeFlowers: Int {
        allSessions.filter { $0.completed }.count
    }

    private var allTimeFocusHours: Int {
        allSessions.reduce(0) { $0 + $1.duration } / 3600
    }

    private var allTimeFocusMinutes: Int {
        (allSessions.reduce(0) { $0 + $1.duration } % 3600) / 60
    }

    private var todayCompletedCount: Int {
        todaySessions.filter { $0.completed }.count
    }

    private var todayAbandonedCount: Int {
        todaySessions.filter { $0.abandoned }.count
    }

    private var todayFocusHours: Int {
        todaySessions.filter { $0.completed }.reduce(0) { $0 + $1.duration } / 3600
    }

    private var thisWeekFocusHours: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekSessions = allSessions.filter { $0.startedAt >= startOfWeek && $0.completed }
        return weekSessions.reduce(0) { $0 + $1.duration } / 3600
    }

    // Weekly dots data
    private var weekDays: [(letter: String, hasData: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today)!

        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).map { i in
            let day = calendar.date(byAdding: .day, value: i, to: monday)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let hasSession = allSessions.contains { $0.startedAt >= day && $0.startedAt < nextDay && $0.completed }
            return (letter: letters[i], hasData: hasSession)
        }
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

                    Text(Date().formatted(.dateTime.month().day()) + " ,Today")
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
                                Text("\(allTimeFlowers)")
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
                                Text("\(allTimeFocusHours)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Text("h")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                                Text("\(allTimeFocusMinutes)")
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
                                    Text("\(todayFocusHours)")
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
                                    Text("\(thisWeekFocusHours)")
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
                            ForEach(Array(weekDays.enumerated()), id: \.offset) { _, day in
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
                                Text("\(todayCompletedCount)")
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
                                Text("\(todayAbandonedCount)")
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
    }
}

#Preview {
    SummaryView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self], inMemory: true)
}
