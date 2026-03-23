import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var allSessions: [FocusSession]
    @State private var selectedDay: Date = Date()

    private var calendar: Calendar { Calendar.current }

    private var weekDays: [(date: Date, dayLetter: String, dayNumber: String, isToday: Bool)] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today)!

        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).map { i in
            let day = calendar.date(byAdding: .day, value: i, to: monday)!
            let num = calendar.component(.day, from: day)
            let isToday = calendar.isDateInToday(day)
            return (date: day, dayLetter: letters[i], dayNumber: "\(num)", isToday: isToday)
        }
    }

    private var hours: [Int] {
        Array(0..<24)
    }

    private var currentHour: Int {
        calendar.component(.hour, from: Date())
    }

    private var currentMinute: Int {
        calendar.component(.minute, from: Date())
    }

    private func sessionsForHour(_ hour: Int) -> [FocusSession] {
        let dayStart = calendar.startOfDay(for: selectedDay)
        let hourStart = calendar.date(byAdding: .hour, value: hour, to: dayStart)!
        let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
        return allSessions.filter { $0.startedAt >= hourStart && $0.startedAt < hourEnd }
    }

    var body: some View {
        ZStack {
            Color(hex: "1A2E1A").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text(selectedDay.formatted(.dateTime.month().day()) + ", Today")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Day picker
                    HStack(spacing: 4) {
                        Text("Day")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())

                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
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
                                    .foregroundColor(day.isToday ? .white : .white.opacity(0.4))
                                Text(day.dayNumber)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(day.isToday ? .white : .white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(day.isToday ? Color(hex: "4A7C59") : Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                        Text(String(format: "%02d:00", hour))
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(.white.opacity(0.3))
                                            .frame(width: 40, alignment: .leading)

                                        Rectangle()
                                            .fill(Color.white.opacity(0.08))
                                            .frame(height: 1)
                                    }

                                    // Sessions in this hour
                                    let sessions = sessionsForHour(hour)
                                    if !sessions.isEmpty {
                                        ForEach(sessions) { session in
                                            let minutes = session.duration / 60
                                            let height = max(CGFloat(minutes), 20)
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(hex: session.tag?.colorHex ?? "4A7C59").opacity(0.6))
                                                .frame(height: height)
                                                .overlay(
                                                    Text(session.tag?.name ?? "Focus")
                                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                                        .foregroundColor(.white)
                                                        .padding(.leading, 8),
                                                    alignment: .leading
                                                )
                                                .padding(.leading, 52)
                                                .padding(.top, 4)
                                        }
                                    }

                                    // Current time indicator
                                    if hour == currentHour && calendar.isDateInToday(selectedDay) {
                                        HStack(spacing: 0) {
                                            Text(String(format: "%02d:%02d", currentHour, currentMinute))
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color(hex: "6B9B7A"))
                                                .clipShape(Capsule())

                                            Rectangle()
                                                .fill(Color(hex: "6B9B7A"))
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
