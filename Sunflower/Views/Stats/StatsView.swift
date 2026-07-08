import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    // See StatsModel.swift for the aggregation. Kept as a plain @Query (no dynamic
    // predicate) — SwiftData can't take runtime predicates easily. We compute
    // aggregates ONCE per period/date/data change into @State, never in the render loop.
    // Presentation is animated on top of the already-computed @State; aggregates never
    // recompute inside an animation.
    @Query private var allSessions: [FocusSession]
    @Query private var allFlowers: [FlowerDrop]
    @Environment(StoreManager.self) private var store

    @State private var period: StatsPeriod = .day
    @State private var anchor: Date = Date()
    @State private var stats = PeriodStats()
    @State private var showPaywall = false

    // Motion state ------------------------------------------------------------
    // Bumped whenever the presented data changes → re-arms every entrance animation.
    @State private var entranceToken = 0
    // Directional slide for period/tab changes: -1 = new content comes from the left,
    // +1 = from the right. Drives the asymmetric slide transition (never a fade).
    @State private var slideDirection: CGFloat = 1
    // Live finger tracking for the interactive period swipe.
    @State private var dragOffset: CGFloat = 0
    // A drilled-in selection (heatmap day / week bar) shown in the detail line.
    @State private var selectedDetail: DaySelection? = nil

    @Namespace private var pickerNS

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
                        .transition(.move(edge: .trailing).combined(with: .scale(scale: 0.96, anchor: .top)))
                } else {
                    periodNav
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            HeadlineGrid(stats: stats, period: period, token: entranceToken)
                            content
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                        // Interactive left/right swipe between periods.
                        .offset(x: dragOffset)
                        .gesture(periodSwipe)
                    }
                    // Re-key on the presented window so content genuinely slides in/out
                    // (directional, spring) rather than cross-fading.
                    .id(periodKey)
                    .transition(slideTransition)
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

    // A stable key for the current presented window; changing it triggers the slide.
    private var periodKey: String {
        "\(period.rawValue)-\(Int(anchor.timeIntervalSince1970 / 60))"
    }

    private var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: slideDirection >= 0 ? .trailing : .leading)
                .combined(with: .scale(scale: 0.97, anchor: .center)),
            removal: .move(edge: slideDirection >= 0 ? .leading : .trailing)
                .combined(with: .scale(scale: 0.97, anchor: .center))
        )
    }

    private func recompute() {
        stats = StatsAggregator.compute(period: period, date: anchor,
                                        sessions: allSessions, flowers: allFlowers)
        selectedDetail = nil
        // Re-arm entrance animations for the freshly presented data.
        entranceToken &+= 1
    }

    // MARK: interactive period swipe
    private var periodSwipe: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .onChanged { g in
                var dx = g.translation.width
                // Rubber-band when dragging into the future (can't go forward past cap).
                let goingForward = dx < 0 // content moves left → next (later) period
                if goingForward && !StatsAggregator.canGoForward(period: period, date: anchor) {
                    dx = -rubberBand(-dx)
                }
                dragOffset = dx
            }
            .onEnded { g in
                let dx = g.translation.width
                let threshold: CGFloat = 70
                let goForward = dx < -threshold
                let goBack = dx > threshold
                let canForward = StatsAggregator.canGoForward(period: period, date: anchor)

                if goForward && canForward {
                    commitShift(by: 1, fromLeft: false)
                } else if goBack {
                    commitShift(by: -1, fromLeft: true)
                } else {
                    if goForward && !canForward { StatsHaptics.edge() }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { dragOffset = 0 }
                }
            }
    }

    private func rubberBand(_ x: CGFloat) -> CGFloat {
        // Diminishing pull past the cap.
        let limit: CGFloat = 90
        return limit * (1 - 1 / (x / limit + 1))
    }

    private func commitShift(by steps: Int, fromLeft: Bool) {
        StatsHaptics.period()
        slideDirection = fromLeft ? -1 : 1
        // Snap the finger offset out the rest of the way, then swap content.
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            anchor = StatsAggregator.shift(period, anchor, by: steps)
            dragOffset = 0
        }
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

    // MARK: segmented control (matchedGeometry capsule slides between segments)
    private var periodPicker: some View {
        HStack(spacing: 6) {
            ForEach(StatsPeriod.allCases) { p in
                Button {
                    guard p != period else { return }
                    StatsHaptics.tab()
                    // Slide direction follows tab order (Day→Week→Month).
                    let forward = tabIndex(p) > tabIndex(period)
                    slideDirection = forward ? 1 : -1
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                        period = p
                        dragOffset = 0
                    }
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
                    .background {
                        if period == p {
                            Capsule()
                                .fill(Color.cream)
                                .matchedGeometryEffect(id: "pickerCapsule", in: pickerNS)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.2))
        .clipShape(Capsule())
    }

    private func tabIndex(_ p: StatsPeriod) -> Int {
        StatsPeriod.allCases.firstIndex(of: p) ?? 0
    }

    // MARK: back / forward through periods (chevrons animated to match the swipe)
    private var periodNav: some View {
        HStack {
            Button { commitShift(by: -1, fromLeft: true) } label: {
                navChevron("chevron.left", enabled: true)
            }
            .buttonStyle(PressScaleStyle())
            Spacer()
            Text(StatsAggregator.title(for: period, date: anchor))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .id("title-\(periodKey)")
                .transition(.asymmetric(
                    insertion: .move(edge: slideDirection >= 0 ? .trailing : .leading),
                    removal: .move(edge: slideDirection >= 0 ? .leading : .trailing)
                ))
            Spacer()
            let canForward = StatsAggregator.canGoForward(period: period, date: anchor)
            Button {
                if canForward { commitShift(by: 1, fromLeft: false) } else { StatsHaptics.edge() }
            } label: {
                navChevron("chevron.right", enabled: canForward)
            }
            .buttonStyle(PressScaleStyle())
            .disabled(!canForward)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: periodKey)
    }

    private func navChevron(_ name: String, enabled: Bool) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(enabled ? .textPrimary : .textPrimary.opacity(0.25))
            .frame(width: 36, height: 36)
            .background(StatsStyle.card)
            .clipShape(Circle())
    }

    // MARK: period content
    @ViewBuilder private var content: some View {
        if stats.sessionCount == 0 {
            EmptyPeriodView(period: period)
        } else {
            switch period {
            case .day:   DayContent(stats: stats, token: entranceToken)
            case .week:  WeekContent(stats: stats, token: entranceToken, selection: $selectedDetail)
            case .month: MonthContent(stats: stats, token: entranceToken, selection: $selectedDetail)
            }
            if !stats.tagSlices.isEmpty {
                TagBreakdownCard(slices: stats.tagSlices, token: entranceToken)
            }
        }
    }
}

// MARK: - A selected day drilled into from a bar / heatmap cell
struct DaySelection: Equatable {
    let label: String   // "Jul 3"
    let minutes: Int
    let flowers: Int?   // nil when unknown (week bars don't carry flower counts)
}

// MARK: - Press-to-scale button style (soft tactile feedback)
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Headline numbers (count up on appear / period change)
private struct HeadlineGrid: View {
    let stats: PeriodStats
    let period: StatsPeriod
    let token: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                CountUpTile(target: Double(stats.totalMinutes),
                            format: { StatsAggregator.formatMinutes(Int($0.rounded())) },
                            label: "focused",
                            trend: period == .day ? nil : stats.trendPercent,
                            token: token)
                CountUpTile(target: Double(stats.sessionCount),
                            format: { "\(Int($0.rounded()))" },
                            label: stats.sessionCount == 1 ? "session" : "sessions",
                            token: token)
            }
            HStack(spacing: 10) {
                CountUpTile(target: Double(stats.flowers),
                            format: { "\(Int($0.rounded()))" },
                            label: stats.flowers == 1 ? "flower" : "flowers",
                            token: token)
                CountUpTile(target: Double(stats.streak),
                            format: { "\(Int($0.rounded()))" },
                            label: "day streak",
                            token: token)
            }
        }
    }
}

private struct CountUpTile: View {
    let target: Double
    let format: (Double) -> String
    let label: String
    var trend: Double? = nil
    let token: Int

    @State private var animated: Double = 0
    @State private var showTrend = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                CountingNumber(value: animated, format: format,
                               font: .system(size: 26, weight: .bold, design: .rounded),
                               color: .textPrimary)
                if let trend, showTrend {
                    TrendBadge(percent: trend)
                        .transition(.scale(scale: 0.4, anchor: .leading))
                }
            }
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(StatsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: StatsStyle.corner))
        .onAppear { runCountUp() }
        .onChange(of: token) { runCountUp() }
    }

    private func runCountUp() {
        showTrend = false
        // Empty periods: snap, no janky sweep from a phantom value.
        if target <= 0 {
            animated = 0
            if trend != nil { withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15)) { showTrend = true } }
            return
        }
        animated = 0
        withAnimation(.easeOut(duration: 0.55)) { animated = target }
        if trend != nil {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.4)) { showTrend = true }
        }
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
    let token: Int
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

// MARK: - WEEK content (Pro): bar chart, bars grow up with a staggered spring
private struct WeekContent: View {
    let stats: PeriodStats
    let token: Int
    @Binding var selection: DaySelection?

    // 0...1 growth per bar, so we can stagger without touching the aggregate.
    @State private var grow: [UUID: CGFloat] = [:]
    @State private var tappedID: UUID? = nil

    private var maxMinutes: Int { max(stats.dayBars.map(\.minutes).max() ?? 0, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                summaryPill(title: "avg / day", value: StatsAggregator.formatMinutes(stats.averageMinutes))
                Spacer()
                summaryPill(title: "best day", value: stats.bestDayMinutes > 0 ? "\(stats.bestDayLabel.prefix(3))" : "–",
                            sub: stats.bestDayMinutes > 0 ? StatsAggregator.formatMinutes(stats.bestDayMinutes) : nil)
            }

            HStack {
                Text("Minutes per day")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Spacer()
                if let sel = selection {
                    DetailLine(text: "\(sel.label) — \(StatsAggregator.formatMinutes(sel.minutes))")
                }
            }

            // Custom bar chart (not Charts) so we can grow each bar from zero and highlight.
            GeometryReader { geo in
                let barW: CGFloat = 24
                let spacing = (geo.size.width - barW * 7) / 6
                HStack(alignment: .bottom, spacing: max(spacing, 4)) {
                    ForEach(stats.dayBars) { bar in
                        let g = grow[bar.id] ?? 0
                        let h = CGFloat(bar.minutes) / CGFloat(maxMinutes) * (geo.size.height - 22)
                        VStack(spacing: 6) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 7)
                                .fill(barFill(bar))
                                .frame(width: barW, height: max(h * g, bar.minutes > 0 ? 3 : 0))
                            Text(bar.label.prefix(1))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(bar.isToday ? .cream : .textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .scaleEffect(tappedID == bar.id ? 0.94 : 1, anchor: .bottom)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard bar.minutes >= 0 else { return }
                            StatsHaptics.cell()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { tappedID = bar.id }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { tappedID = nil }
                            }
                            selection = DaySelection(label: StatsAggregator.monthDayName(bar.date),
                                                     minutes: bar.minutes, flowers: nil)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(StatsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: StatsStyle.corner))
        .onAppear { runGrow() }
        .onChange(of: token) { runGrow() }
    }

    private func barFill(_ bar: DayBar) -> Color {
        if tappedID == bar.id { return StatsStyle.barTop }
        return bar.isToday ? StatsStyle.barBest : StatsStyle.barFill
    }

    private func runGrow() {
        // reset to zero then grow up, staggered
        for bar in stats.dayBars { grow[bar.id] = 0 }
        for (i, bar) in stats.dayBars.enumerated() {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62).delay(Double(i) * 0.05)) {
                grow[bar.id] = 1
            }
        }
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

private struct DetailLine: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.darkGreen)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.cream.opacity(0.9))
            .clipShape(Capsule())
            .transition(.scale(scale: 0.6, anchor: .trailing))
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: text)
    }
}

// MARK: - MONTH content (Pro): calendar heatmap, cells pop in with scale stagger
private struct MonthContent: View {
    let stats: PeriodStats
    let token: Int
    @Binding var selection: DaySelection?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    @State private var pop: [UUID: CGFloat] = [:]
    @State private var tappedID: UUID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                summaryPill(title: "avg / active day", value: StatsAggregator.formatMinutes(stats.averageMinutes))
                Spacer()
                summaryPill(title: "best day", value: stats.bestDayMinutes > 0 ? stats.bestDayLabel : "–",
                            sub: stats.bestDayMinutes > 0 ? StatsAggregator.formatMinutes(stats.bestDayMinutes) : nil)
            }

            HStack {
                Text("Focus calendar")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Spacer()
                if let sel = selection {
                    DetailLine(text: detailText(sel))
                }
            }

            HStack(spacing: 6) {
                ForEach(Array(weekdayLetters.enumerated()), id: \.offset) { _, l in
                    Text(l).font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(stats.heatCells) { cell in
                    let s = pop[cell.id] ?? (cell.inMonth ? 0.6 : 1)
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
                            .stroke(selection?.label == StatsAggregator.monthDayName(cell.date) && cell.inMonth ? Color.cream : Color.warmYellow,
                                    lineWidth: cell.isToday || (selection?.label == StatsAggregator.monthDayName(cell.date) && cell.inMonth) ? 2 : 0)
                    )
                    .scaleEffect(tappedID == cell.id ? 0.88 : s, anchor: .center)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard cell.inMonth else { return }
                        StatsHaptics.cell()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) { tappedID = cell.id }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { tappedID = nil }
                        }
                        selection = DaySelection(label: StatsAggregator.monthDayName(cell.date),
                                                 minutes: cell.minutes, flowers: nil)
                    }
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
        .onAppear { runPop() }
        .onChange(of: token) { runPop() }
    }

    private func detailText(_ sel: DaySelection) -> String {
        sel.minutes > 0 ? "\(sel.label) — \(StatsAggregator.formatMinutes(sel.minutes))" : "\(sel.label) — no focus"
    }

    private func runPop() {
        let inMonth = stats.heatCells.filter { $0.inMonth }
        for cell in stats.heatCells { pop[cell.id] = cell.inMonth ? 0.6 : 1 }
        for (i, cell) in inMonth.enumerated() {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.012)) {
                pop[cell.id] = 1
            }
        }
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

// MARK: - Tag breakdown (Pro periods): donut sweeps in + list grows in
private struct TagBreakdownCard: View {
    let slices: [TagSlice]
    let token: Int
    private var total: Int { max(slices.reduce(0) { $0 + $1.minutes }, 1) }

    @State private var sweep: CGFloat = 0        // 0...1 draws the donut around
    @State private var rowsIn = false

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
                // Sweep the donut in by revealing it around the circle (scale + rotational mask).
                .scaleEffect(0.5 + sweep * 0.5)
                .rotationEffect(.degrees(Double((1 - sweep)) * -120))
                .mask(
                    DonutSweepShape(fraction: sweep)
                        .frame(width: 130, height: 130)
                )

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(slices.prefix(5).enumerated()), id: \.element.id) { i, slice in
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
                        .offset(x: rowsIn ? 0 : 24)
                        .scaleEffect(rowsIn ? 1 : 0.95, anchor: .leading)
                        .animation(.spring(response: 0.42, dampingFraction: 0.75).delay(0.12 + Double(i) * 0.05), value: rowsIn)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(StatsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: StatsStyle.corner))
        .onAppear { runSweep() }
        .onChange(of: token) { runSweep() }
    }

    private func runSweep() {
        sweep = 0
        rowsIn = false
        withAnimation(.easeOut(duration: 0.6)) { sweep = 1 }
        rowsIn = true
    }
}

// Reveals a ring progressively from the top, clockwise (used as a mask, no fade).
private struct DonutSweepShape: Shape {
    var fraction: CGFloat
    var animatableData: CGFloat {
        get { fraction }
        set { fraction = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height)
        p.move(to: center)
        p.addArc(center: center, radius: radius,
                 startAngle: .degrees(-90),
                 endAngle: .degrees(-90 + 360 * Double(min(max(fraction, 0), 1))),
                 clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Empty state (on-brand, encouraging) — sprout grows in, no fade
private struct EmptyPeriodView: View {
    let period: StatsPeriod
    @State private var grown = false
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
                .scaleEffect(grown ? 1 : 0.7, anchor: .bottom)
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
        .onAppear {
            grown = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { grown = true }
        }
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
            .buttonStyle(PressScaleStyle())
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
