import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    // See StatsModel.swift for the aggregation. Kept as a plain @Query (no dynamic
    // predicate) — SwiftData can't take runtime predicates easily. We compute
    // aggregates ONCE per period/date/data change into @State, never in the render loop.
    @Query private var allSessions: [FocusSession]
    @Query private var allFlowers: [FlowerDrop]
    @Environment(StoreManager.self) private var store

    @State private var period: StatsPeriod = .day
    @State private var anchor: Date = Date()
    @State private var stats = PeriodStats()
    @State private var showPaywall = false

    private var locked: Bool { period.isPro && !store.isPro }

    var body: some View {
        ZStack {
            StatsStyle.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                periodPicker
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                if locked {
                    LockedStatsView { showPaywall = true }
                } else {
                    periodNav
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            HeadlineGrid(stats: stats, period: period)
                            content
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear(perform: recompute)
        .onChange(of: period) { recompute() }
        .onChange(of: anchor) { recompute() }
        .onChange(of: allSessions.count) { recompute() }
        .onChange(of: allFlowers.count) { recompute() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: DispatchQueue.main)) { _ in
            anchor = Date()
            recompute()
        }
    }

    private func recompute() {
        stats = StatsAggregator.compute(period: period, date: anchor,
                                        sessions: allSessions, flowers: allFlowers)
    }

    // MARK: header
    private var header: some View {
        HStack {
            Text("Your focus")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Spacer()
            if store.isPro {
                Text("PRO")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.cream)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.darkGreen)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    // MARK: segmented control
    private var periodPicker: some View {
        HStack(spacing: 6) {
            ForEach(StatsPeriod.allCases) { p in
                Button {
                    period = p
                } label: {
                    HStack(spacing: 4) {
                        Text(p.rawValue)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        if p.isPro && !store.isPro {
                            Image(systemName: "lock.fill").font(.system(size: 9))
                        }
                    }
                    .foregroundColor(period == p ? .darkGreen : .textPrimary.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(period == p ? Color.cream : Color.clear)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.2))
        .clipShape(Capsule())
    }

    // MARK: back / forward through periods
    private var periodNav: some View {
        HStack {
            Button { anchor = StatsAggregator.shift(period, anchor, by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(StatsStyle.card)
                    .clipShape(Circle())
            }
            Spacer()
            Text(StatsAggregator.title(for: period, date: anchor))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Spacer()
            Button { anchor = StatsAggregator.shift(period, anchor, by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(StatsAggregator.canGoForward(period: period, date: anchor) ? .textPrimary : .textPrimary.opacity(0.25))
                    .frame(width: 36, height: 36)
                    .background(StatsStyle.card)
                    .clipShape(Circle())
            }
            .disabled(!StatsAggregator.canGoForward(period: period, date: anchor))
        }
    }

    // MARK: period content
    @ViewBuilder private var content: some View {
        if stats.sessionCount == 0 {
            EmptyPeriodView(period: period)
        } else {
            switch period {
            case .day:   DayContent(stats: stats)
            case .week:  WeekContent(stats: stats)
            case .month: MonthContent(stats: stats)
            }
            if !stats.tagSlices.isEmpty {
                TagBreakdownCard(slices: stats.tagSlices)
            }
        }
    }
}

// MARK: - Headline numbers
private struct HeadlineGrid: View {
    let stats: PeriodStats
    let period: StatsPeriod

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatTile(value: StatsAggregator.formatMinutes(stats.totalMinutes), label: "focused", trend: period == .day ? nil : stats.trendPercent)
                StatTile(value: "\(stats.sessionCount)", label: stats.sessionCount == 1 ? "session" : "sessions")
            }
            HStack(spacing: 10) {
                StatTile(value: "\(stats.flowers)", label: stats.flowers == 1 ? "flower" : "flowers")
                StatTile(value: "\(stats.streak)", label: "day streak")
            }
        }
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    var trend: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                if let trend { TrendBadge(percent: trend) }
            }
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(StatsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: StatsStyle.corner))
    }
}

private struct TrendBadge: View {
    let percent: Double
    private var up: Bool { percent >= 0 }
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .bold))
            Text("\(abs(Int((percent * 100).rounded())))%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(up ? .darkGreen : .brown)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background((up ? Color.warmYellow : Color.cream).opacity(0.85))
        .clipShape(Capsule())
    }
}

// MARK: - DAY content (free)
private struct DayContent: View {
    let stats: PeriodStats
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This day")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            HStack {
                InlineStat(title: "sessions", value: "\(stats.sessionCount)")
                Spacer()
                InlineStat(title: "focus time", value: StatsAggregator.formatMinutes(stats.totalMinutes))
                Spacer()
                InlineStat(title: "flowers", value: "\(stats.flowers)")
            }
            Text("Unlock Week and Month for trends, best days and per-tag insights.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.textSecondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(StatsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: StatsStyle.corner))
    }
}

private struct InlineStat: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.textPrimary)
            Text(title).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.textSecondary)
        }
    }
}

// MARK: - WEEK content (Pro): bar chart
private struct WeekContent: View {
    let stats: PeriodStats

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                summaryPill(title: "avg / day", value: StatsAggregator.formatMinutes(stats.averageMinutes))
                Spacer()
                summaryPill(title: "best day", value: stats.bestDayMinutes > 0 ? "\(stats.bestDayLabel.prefix(3))" : "–",
                            sub: stats.bestDayMinutes > 0 ? StatsAggregator.formatMinutes(stats.bestDayMinutes) : nil)
            }

            Text("Minutes per day")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            Chart(stats.dayBars) { bar in
                BarMark(
                    x: .value("Day", bar.label),
                    y: .value("Minutes", bar.minutes),
                    width: .fixed(22)
                )
                .cornerRadius(7)
                .foregroundStyle(bar.isToday ? StatsStyle.barBest : StatsStyle.barFill)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel {
                        if let m = value.as(Int.self) {
                            Text("\(m)").font(.system(size: 10, design: .rounded)).foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self) {
                            Text(s).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.textPrimary)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(StatsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: StatsStyle.corner))
    }

    private func summaryPill(title: String, value: String, sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(.textPrimary)
                if let sub { Text(sub).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(.textSecondary) }
            }
        }
    }
}

// MARK: - MONTH content (Pro): calendar heatmap
private struct MonthContent: View {
    let stats: PeriodStats
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                summaryPill(title: "avg / active day", value: StatsAggregator.formatMinutes(stats.averageMinutes))
                Spacer()
                summaryPill(title: "best day", value: stats.bestDayMinutes > 0 ? stats.bestDayLabel : "–",
                            sub: stats.bestDayMinutes > 0 ? StatsAggregator.formatMinutes(stats.bestDayMinutes) : nil)
            }

            Text("Focus calendar")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            HStack(spacing: 6) {
                ForEach(Array(weekdayLetters.enumerated()), id: \.offset) { _, l in
                    Text(l).font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(stats.heatCells) { cell in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(cell.inMonth ? StatsStyle.heat(cell.intensity) : Color.clear)
                        if cell.inMonth {
                            Text("\(cell.dayNumber)")
                                .font(.system(size: 11, weight: cell.isToday ? .bold : .medium, design: .rounded))
                                .foregroundColor(cell.intensity > 0.6 ? .cream : .textPrimary.opacity(0.85))
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.warmYellow, lineWidth: cell.isToday ? 2 : 0)
                    )
                }
            }

            // legend
            HStack(spacing: 8) {
                Text("less").font(.system(size: 10, design: .rounded)).foregroundColor(.textSecondary)
                ForEach([0.0, 0.3, 0.6, 1.0], id: \.self) { t in
                    RoundedRectangle(cornerRadius: 3).fill(StatsStyle.heat(t)).frame(width: 16, height: 16)
                }
                Text("more").font(.system(size: 10, design: .rounded)).foregroundColor(.textSecondary)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(StatsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: StatsStyle.corner))
    }

    private func summaryPill(title: String, value: String, sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.textPrimary).lineLimit(1)
                if let sub { Text(sub).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(.textSecondary) }
            }
        }
    }
}

// MARK: - Tag breakdown (Pro periods): donut + list
private struct TagBreakdownCard: View {
    let slices: [TagSlice]
    private var total: Int { max(slices.reduce(0) { $0 + $1.minutes }, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("By tag")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            HStack(alignment: .center, spacing: 18) {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Minutes", slice.minutes),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .cornerRadius(3)
                    .foregroundStyle(Color(hex: slice.colorHex))
                }
                .chartLegend(.hidden)
                .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(slices.prefix(5)) { slice in
                        HStack(spacing: 8) {
                            Circle().fill(Color(hex: slice.colorHex)).frame(width: 10, height: 10)
                            Text(slice.name)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.textPrimary).lineLimit(1)
                            Spacer()
                            Text(StatsAggregator.formatMinutes(slice.minutes))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(StatsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: StatsStyle.corner))
    }
}

// MARK: - Empty state (on-brand, encouraging)
private struct EmptyPeriodView: View {
    let period: StatsPeriod
    private var message: String {
        switch period {
        case .day:   return "No focus here yet. Plant your first flower today."
        case .week:  return "A quiet week so far. One session and it starts to bloom."
        case .month: return "This month is a blank garden. Start where you are."
        }
    }
    var body: some View {
        VStack(spacing: 14) {
            Image("sprout")
                .resizable().scaledToFit()
                .frame(width: 64, height: 64)
                .opacity(0.9)
            Text(message)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(StatsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: StatsStyle.corner))
    }
}

// MARK: - Locked (Pro upsell) state for Week / Month
private struct LockedStatsView: View {
    let onUnlock: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image("flower_purple")
                .resizable().scaledToFit()
                .frame(width: 80, height: 80)
            Text("Deep focus stats")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Text("See your week and month at a glance — trends, best days, calendar heatmap and time by tag.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 10) {
                lockedFeature("Weekly focus bar chart")
                lockedFeature("Monthly calendar heatmap")
                lockedFeature("Time by tag, trends vs last period")
            }
            .padding(.top, 4)

            Button(action: onUnlock) {
                Text("Unlock Pro")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.cream)
                    .padding(.horizontal, 40).padding(.vertical, 14)
                    .background(Color.darkGreen)
                    .clipShape(Capsule())
            }
            .padding(.top, 6)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private func lockedFeature(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image("sprout").resizable().scaledToFit().frame(width: 20, height: 20)
            Text(text).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(.textPrimary)
        }
    }
}

#Preview {
    StatsView()
        .environment(StoreManager())
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self, GardenItem.self], inMemory: true)
}
