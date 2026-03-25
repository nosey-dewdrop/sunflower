import SwiftUI
import SwiftData

struct StatsView: View {
    // NOTE: For scale (1000+ sessions), this query should use a date predicate
    // to limit to the current week/month. SwiftData does not support dynamic
    // predicates easily, so for now we filter in code. If performance degrades
    // with large data sets, migrate to a filtered fetch with #Predicate.
    @Query private var allSessions: [FocusSession]
    @State private var selectedDay: Date = Date()

    private static let calendar = Calendar.current

    // Precomputed hour labels to avoid String(format:) in render loop
    private static let hourLabels: [String] = (0..<24).map { String(format: "%02d:00", $0) }
    private static let hourMinuteLabels: [[String]] = (0..<24).map { hour in
        (0..<60).map { minute in String(format: "%02d:%02d", hour, minute) }
    }

    private var weekDays: [(date: Date, dayLetter: String, dayNumber: String, isToday: Bool)] {
        let calendar = Self.calendar
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else { return [] }

        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).compactMap { i in
            guard let day = calendar.date(byAdding: .day, value: i, to: monday) else { return nil }
            let num = calendar.component(.day, from: day)
            let isToday = calendar.isDateInToday(day)
            return (date: day, dayLetter: letters[i], dayNumber: "\(num)", isToday: isToday)
        }
    }

    private var hours: [Int] {
        Array(0..<24)
    }

    private var currentHour: Int {
        Self.calendar.component(.hour, from: Date())
    }

    private var currentMinute: Int {
        Self.calendar.component(.minute, from: Date())
    }

    private func sessionsForHour(_ hour: Int) -> [FocusSession] {
        let calendar = Self.calendar
        let dayStart = calendar.startOfDay(for: selectedDay)
        guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: dayStart),
              let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) else { return [] }
        return allSessions.filter { $0.startedAt >= hourStart && $0.startedAt < hourEnd }
    }

    var body: some View {
        ZStack {
            Color.grassGreen.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text(selectedDay.formatted(.dateTime.month().day()) + ", Today")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    Spacer()

                    // Day picker
                    HStack(spacing: 4) {
                        Text("Day")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.3))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // Week days row
                HStack(spacing: 8) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { _, day in
                        Button {
                            selectedDay = day.date
                        } label: {
                            VStack(spacing: 2) {
                                Text(day.dayLetter)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(day.isToday ? .white : .textSecondary)
                                Text(day.dayNumber)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(day.isToday ? .white : .textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(day.isToday ? Color.darkGreen : Color.white.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Hourly timeline
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { hour in
                                ZStack(alignment: .topLeading) {
                                    // Hour label + dashed line
                                    HStack(spacing: 8) {
                                        Text(Self.hourLabels[hour])
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(.textSecondary.opacity(0.6))
                                            .frame(width: 40, alignment: .leading)

                                        Rectangle()
                                            .fill(Color.darkGreen.opacity(0.15))
                                            .frame(height: 1)
                                    }

                                    // Sessions in this hour
                                    let sessions = sessionsForHour(hour)
                                    if !sessions.isEmpty {
                                        ForEach(sessions) { session in
                                            let minutes = session.duration / 60
                                            let height = max(CGFloat(minutes), 20)
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(hex: session.tag?.colorHex ?? "7AAD2E").opacity(0.5))
                                                .frame(height: height)
                                                .overlay(
                                                    Text(session.tag?.name ?? "Focus")
                                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                                        .foregroundColor(.textPrimary)
                                                        .padding(.leading, 8),
                                                    alignment: .leading
                                                )
                                                .padding(.leading, 52)
                                                .padding(.top, 4)
                                        }
                                    }

                                    // Current time indicator
                                    if hour == currentHour && Self.calendar.isDateInToday(selectedDay) {
                                        let timeLabel = Self.hourMinuteLabels[currentHour][currentMinute]
                                        HStack(spacing: 0) {
                                            Text(timeLabel)
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.darkGreen)
                                                .clipShape(Capsule())

                                            Rectangle()
                                                .fill(Color.darkGreen)
                                                .frame(height: 1.5)
                                        }
                                        .offset(y: CGFloat(currentMinute) / 60.0 * 80)
                                    }
                                }
                                .frame(height: 80)
                                .id(hour)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .onAppear {
                        let scrollHour = max(0, currentHour - 2)
                        proxy.scrollTo(scrollHour, anchor: .top)
                    }
                }
            }
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self, GardenItem.self], inMemory: true)
}
