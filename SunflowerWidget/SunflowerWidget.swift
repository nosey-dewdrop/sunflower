import WidgetKit
import SwiftUI

struct GardenEntry: TimelineEntry {
    let date: Date
    let snapshot: GardenSnapshot
}

struct GardenProvider: TimelineProvider {
    func placeholder(in context: Context) -> GardenEntry {
        GardenEntry(date: .now, snapshot: GardenSnapshot(
            flowers: [
                SnapshotFlower(type: "sunflower", x: 0.3, y: 0.6, size: 28),
                SnapshotFlower(type: "tulip", x: 0.7, y: 0.4, size: 24),
                SnapshotFlower(type: "daisy", x: 0.5, y: 0.8, size: 32)
            ],
            streak: 3,
            todayMinutes: 60
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (GardenEntry) -> Void) {
        completion(GardenEntry(date: .now, snapshot: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GardenEntry>) -> Void) {
        let entry = GardenEntry(date: .now, snapshot: .load())
        // the app reloads timelines on every change; midnight refresh clears yesterday's garden
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

struct SunflowerWidgetEntryView: View {
    var entry: GardenEntry
    @Environment(\.widgetFamily) private var family

    private func asset(for type: String) -> String {
        switch type {
        case "sunflower": return "flower_yellow"
        case "daisy": return "flower_blue"
        case "tulip": return "flower_red"
        case "rose": return "flower_purple"
        case "lavender": return "flower_purple"
        default: return "flower_yellow"
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if entry.snapshot.flowers.isEmpty {
                    // empty garden: a lone sprout waits for the first focus
                    VStack(spacing: 6) {
                        Image("sprout")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                        Text("no flowers yet today")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    ForEach(Array(entry.snapshot.flowers.enumerated()), id: \.offset) { _, flower in
                        Image(asset(for: flower.type))
                            .resizable()
                            .scaledToFit()
                            .frame(width: flower.size, height: flower.size)
                            .position(x: flower.x * geo.size.width, y: flower.y * geo.size.height)
                    }
                }

                // streak badge: damla's shooting star carries the number
                HStack(spacing: 5) {
                    Image("decor_star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                    Text("\(entry.snapshot.streak)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(entry.snapshot.streak == 1 ? "day" : "days")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.22))
                .clipShape(Capsule())
                .padding(8)
            }
        }
        .containerBackground(for: .widget) {
            Image("ground_texture")
                .resizable()
                .scaledToFill()
        }
    }
}

struct SunflowerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SunflowerGarden", provider: GardenProvider()) { entry in
            SunflowerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Garden")
        .description("Today's flowers and your streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SunflowerWidgetBundle: WidgetBundle {
    var body: some Widget {
        SunflowerWidget()
        FocusLiveActivity()
    }
}
