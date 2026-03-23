import SwiftUI
import SwiftData

struct SummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSessions: [FocusSession]
    @Query private var tags: [FocusTag]

    private var todaySessions: [FocusSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return allSessions
            .filter { $0.startedAt >= startOfDay }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private var completedCount: Int {
        todaySessions.filter { $0.completed }.count
    }

    private var abandonedCount: Int {
        todaySessions.filter { $0.abandoned }.count
    }

    private var totalFocusMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.duration } / 60
    }

    private var tagBreakdown: [(tag: String, color: String, minutes: Int)] {
        var dict: [String: (color: String, seconds: Int)] = [:]
        for session in todaySessions {
            let name = session.tag?.name ?? "untagged"
            let color = session.tag?.colorHex ?? "999999"
            dict[name, default: (color: color, seconds: 0)].seconds += session.duration
        }
        return dict.map { (tag: $0.key, color: $0.value.color, minutes: $0.value.seconds / 60) }
            .sorted { $0.minutes > $1.minutes }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkGreen.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Date
                        Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                            .pixelFont(size: 16, bold: true)
                            .foregroundColor(.warmYellow)

                        // Stats row
                        HStack(spacing: 16) {
                            StatBox(value: "\(todaySessions.count)", label: "started")
                            StatBox(value: "\(completedCount)", label: "completed")
                            StatBox(value: "\(abandonedCount)", label: "abandoned")
                        }

                        // Total focus time
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.warmYellow)
                            Text("\(totalFocusMinutes) min focused today")
                                .pixelFont(size: 16, bold: true)
                                .foregroundColor(.cream)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.grassGreen.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Tag breakdown
                        if !tagBreakdown.isEmpty {
                            Text("by tag")
                                .pixelFont(size: 14, bold: true)
                                .foregroundColor(.cream.opacity(0.7))

                            ForEach(tagBreakdown, id: \.tag) { item in
                                HStack {
                                    Circle()
                                        .fill(Color(hex: item.color))
                                        .frame(width: 10, height: 10)
                                    Text(item.tag)
                                        .pixelFont(size: 14)
                                        .foregroundColor(.cream)
                                    Spacer()
                                    Text("\(item.minutes) min")
                                        .pixelFont(size: 14, bold: true)
                                        .foregroundColor(.warmYellow)
                                }
                            }
                        }

                        // Timeline
                        if !todaySessions.isEmpty {
                            Text("timeline")
                                .pixelFont(size: 14, bold: true)
                                .foregroundColor(.cream.opacity(0.7))

                            ForEach(todaySessions) { session in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.startedAt, format: .dateTime.hour().minute())
                                            .pixelFont(size: 13)
                                            .foregroundColor(.cream.opacity(0.6))
                                        HStack(spacing: 4) {
                                            if let tag = session.tag {
                                                Circle()
                                                    .fill(Color(hex: tag.colorHex))
                                                    .frame(width: 8, height: 8)
                                                Text(tag.name)
                                                    .pixelFont(size: 13)
                                                    .foregroundColor(.cream)
                                            }
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(session.duration / 60) min")
                                            .pixelFont(size: 13, bold: true)
                                            .foregroundColor(.cream)
                                        if session.completed {
                                            Text("completed")
                                                .pixelFont(size: 10)
                                                .foregroundColor(.warmYellow)
                                        } else if session.abandoned {
                                            Text("abandoned")
                                                .pixelFont(size: 10)
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .pixelFont(size: 24, bold: true)
                .foregroundColor(.warmYellow)
            Text(label)
                .pixelFont(size: 11)
                .foregroundColor(.cream.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.grassGreen.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SummaryView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self], inMemory: true)
}
