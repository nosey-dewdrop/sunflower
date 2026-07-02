import SwiftUI
import SwiftData

enum TimerPhase: String {
    case focus = "Focus"
    case idle = "Ready"
}

// the sprout marks where the session's flower will bloom; it never fades, only moves like a drawing
enum SproutPhase {
    case none
    case growing    // session running, sprout upright
    case drooping   // brief droop shown right before recovery
    case wilted     // session lost, goodbye moment
    case sinking    // wilted sprout returns to the soil
}

@Observable
class TimerManager {
    var timeRemaining: Int = 1500
    var totalTime: Int = 1500
    var isRunning: Bool = false
    var phase: TimerPhase = .idle
    var endDate: Date?
    var timer: Timer?
    var onComplete: (() -> Void)?

    // wall-clock based: short trips to background never desync the countdown
    func start(duration: Int) {
        totalTime = duration
        timeRemaining = duration
        endDate = Date().addingTimeInterval(TimeInterval(duration))
        phase = .focus
        isRunning = true
        startTicking()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard isRunning, let endDate else { return }
        let remaining = Int(ceil(endDate.timeIntervalSinceNow))
        if remaining > 0 {
            timeRemaining = remaining
        } else {
            timeRemaining = 0
            stop()
            onComplete?()
        }
    }

    // call when returning to foreground so the countdown catches up instantly
    func resync() {
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endDate = nil
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    func reset(duration: Int) {
        stop()
        phase = .idle
        totalTime = duration
        timeRemaining = duration
    }

    var timeString: String {
        let hours = timeRemaining / 3600
        let minutes = (timeRemaining % 3600) / 60
        let seconds = timeRemaining % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var elapsedSeconds: Int {
        totalTime - timeRemaining
    }
}

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settings: [UserSettings]
    @Query private var tags: [FocusTag]
    @Query private var flowers: [FlowerDrop]

    @State private var timerManager = TimerManager()
    @State private var selectedTag: FocusTag?
    @State private var showTagPicker = false
    @State private var sessionStartTime: Date?
    @State private var showFlowerEarned = false
    @State private var showFlowerMissed = false
    @State private var tappedTree: FocusTag?
    @State private var showDurationPicker = false
    @State private var showSummary = false
    @State private var pickerMinutes: Int = 20

    // wilt mechanic state
    @State private var sproutPhase: SproutPhase = .none
    @State private var pendingFlowerX: Double = 0.5
    @State private var pendingFlowerY: Double = 0.7
    @State private var pendingFlowerType: String = "sunflower"
    @State private var backgroundedAt: Date?
    @State private var lastLockSignal: Date?

    private let graceSeconds: TimeInterval = 30

    // persisted so a killed app can still settle the session honestly on next launch
    private enum PendingSessionKey {
        static let endDate = "pending.endDate"
        static let startedAt = "pending.startedAt"
        static let total = "pending.total"
        static let flowerType = "pending.flowerType"
        static let posX = "pending.posX"
        static let posY = "pending.posY"
        static let tagId = "pending.tagId"
        static let backgroundedAt = "pending.backgroundedAt"
        static let all = [endDate, startedAt, total, flowerType, posX, posY, tagId, backgroundedAt]
    }

    private var currentSettings: UserSettings {
        if let first = settings.first {
            return first
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        try? modelContext.save()
        return newSettings
    }

    var body: some View {
        GeometryReader { screen in
            ZStack {
                // Scrollable: Timer (top) → Summary (bottom)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // === TIMER SECTION ===
                        ZStack {
                            // Grass background
                            GeometryReader { geo in
                                Image("ground_texture")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            }
                            .ignoresSafeArea()

                            // Trees from tags
                            ForEach(tags) { tag in
                                if tag.appleCount > 0 {
                                    TreeSprite(tag: tag)
                                        .position(
                                            x: tag.treePositionX * screen.size.width,
                                            y: tag.treePositionY * screen.size.height
                                        )
                                        .onTapGesture {
                                            tappedTree = tag
                                        }
                                }
                            }

                            // Flower drops
                            ForEach(flowers) { flower in
                                FlowerSprite(flowerType: flower.flowerType, size: flower.displaySize)
                                    .position(
                                        x: flower.positionX * screen.size.width,
                                        y: flower.positionY * screen.size.height
                                    )
                            }

                            // Sprout: where the running session's flower will bloom
                            if sproutPhase != .none {
                                SproutSprite(phase: sproutPhase)
                                    .position(
                                        x: pendingFlowerX * screen.size.width,
                                        y: pendingFlowerY * screen.size.height
                                    )
                                    .transition(.scale(scale: 0.1, anchor: .bottom))
                            }

                            // Timer UI - exact FocusPomo layout
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: screen.size.height * 0.35)

                                // Countdown
                                Button {
                                    if !timerManager.isRunning {
                                        pickerMinutes = currentSettings.pomoDuration / 60
                                        showDurationPicker = true
                                    }
                                } label: {
                                    Text(timerManager.timeString)
                                        .font(.system(size: 80, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .contentTransition(.numericText())
                                        .animation(.default, value: timerManager.timeRemaining)
                                }

                                // Tag below countdown
                                Button {
                                    showTagPicker = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(selectedTag?.name ?? "Study")
                                            .font(.system(size: 17, weight: .regular, design: .rounded))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.top, 4)

                                // Start button
                                Button {
                                    handleMainButton()
                                } label: {
                                    Text(timerManager.isRunning ? "Stop" : "Start")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 36)
                                        .padding(.vertical, 16)
                                        .background(Color.white.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                .padding(.top, 12)

                                Spacer()
                            }
                        }
                        .frame(height: screen.size.height)
                        .id("timer")

                        // === SUMMARY SECTION (scroll down) ===
                        SummaryView()
                            .frame(height: screen.size.height)
                            .id("summary")
                    }
                }
                .scrollTargetBehavior(.paging)

                // Overlays on top of everything
                if showFlowerEarned {
                    VStack {
                        Spacer()
                        Text("flower earned!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.warmYellow)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.85))
                            .clipShape(Capsule())
                        Spacer().frame(height: 100)
                    }
                    .animation(.spring(duration: 0.5), value: showFlowerEarned)
                }

                if showFlowerMissed {
                    VStack {
                        Spacer()
                        Text("this flower couldn't bloom")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.brown)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.cream.opacity(0.9))
                            .clipShape(Capsule())
                        Spacer().frame(height: 100)
                    }
                    .animation(.spring(duration: 0.5), value: showFlowerMissed)
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showTagPicker) {
            TagPickerSheet(selectedTag: $selectedTag, tags: tags)
                .presentationDetents([.medium])
        }
        .sheet(item: $tappedTree) { tag in
            TreeDetailSheet(tag: tag)
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showDurationPicker) {
            DurationPickerView(
                pickerMinutes: $pickerMinutes,
                onDone: {
                    currentSettings.pomoDuration = pickerMinutes * 60
                    timerManager.reset(duration: pickerMinutes * 60)
                    try? modelContext.save()
                    showDurationPicker = false
                }
            )
        }
        .onAppear {
            setupTimer()
            reconcilePersistedSession()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(to: newPhase)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)) { _ in
            // device lock signal: locking the phone to focus is never punished
            lastLockSignal = Date()
        }
    }

    // MARK: - Setup

    private func setupTimer() {
        let s = currentSettings
        timerManager.totalTime = s.pomoDuration
        timerManager.timeRemaining = s.pomoDuration

        timerManager.onComplete = {
            handleFocusComplete()
        }

        NotificationManager.shared.requestPermission()
    }

    // MARK: - Button Actions

    private func handleMainButton() {
        if timerManager.isRunning {
            let elapsed = timerManager.elapsedSeconds
            timerManager.stop()
            NotificationManager.shared.cancelAll()
            clearPendingSession()

            if elapsed >= 60 {
                let session = FocusSession(
                    tag: selectedTag,
                    startedAt: sessionStartTime ?? Date(),
                    duration: elapsed,
                    completed: false,
                    abandoned: true
                )
                modelContext.insert(session)
                try? modelContext.save()
            }

            timerManager.reset(duration: currentSettings.pomoDuration)
            withAnimation(.easeIn(duration: 0.3)) {
                sproutPhase = .none
            }
        } else {
            sessionStartTime = Date()
            pendingFlowerType = FlowerDrop.randomType()
            pendingFlowerX = Double.random(in: 0.1...0.9)
            pendingFlowerY = Double.random(in: 0.5...0.85)
            timerManager.start(duration: currentSettings.pomoDuration)
            if currentSettings.notificationsEnabled {
                NotificationManager.shared.scheduleTimerComplete(in: currentSettings.pomoDuration, isFocus: true)
            }
            persistPendingSession()
            withAnimation(.spring(duration: 0.5)) {
                sproutPhase = .growing
            }
        }
    }

    private func handleFocusComplete() {
        let session = FocusSession(
            tag: selectedTag,
            startedAt: sessionStartTime ?? Date(),
            duration: currentSettings.pomoDuration,
            completed: true,
            abandoned: false
        )
        modelContext.insert(session)

        // the flower blooms exactly where the sprout stood
        let flower = FlowerDrop(
            flowerType: pendingFlowerType,
            size: FlowerDrop.sizeForDuration(currentSettings.pomoDuration),
            positionX: pendingFlowerX,
            positionY: pendingFlowerY
        )
        modelContext.insert(flower)
        try? modelContext.save()

        NotificationManager.shared.cancelWiltWarning()
        clearPendingSession()
        sproutPhase = .none

        withAnimation {
            showFlowerEarned = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showFlowerEarned = false
            }
        }

        timerManager.reset(duration: currentSettings.pomoDuration)
    }

    // MARK: - Gentle Wilt (leave the app mid-focus)

    private func handleScenePhaseChange(to phase: ScenePhase) {
        switch phase {
        case .background:
            guard timerManager.isRunning else { return }

            // locking the phone to focus is not leaving; calls interrupt, they don't punish
            if let lock = lastLockSignal, Date().timeIntervalSince(lock) < 2 {
                return
            }

            let now = Date()
            backgroundedAt = now
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: PendingSessionKey.backgroundedAt)

            if let end = timerManager.endDate, end.timeIntervalSince(now) > graceSeconds {
                // the flower can no longer finish within grace: bloom is not guaranteed anymore
                NotificationManager.shared.cancelTimerComplete()
                if currentSettings.notificationsEnabled && currentSettings.wiltRemindersEnabled {
                    NotificationManager.shared.scheduleWiltWarning()
                }
            }

        case .active:
            NotificationManager.shared.cancelWiltWarning()
            reconcileAfterReturn()

        default:
            break
        }
    }

    private func reconcileAfterReturn() {
        defer {
            backgroundedAt = nil
            UserDefaults.standard.removeObject(forKey: PendingSessionKey.backgroundedAt)
        }
        guard timerManager.isRunning else { return }

        guard let left = backgroundedAt else {
            // lock or brief interruption: countdown catches up silently
            timerManager.resync()
            return
        }

        let away = Date().timeIntervalSince(left)
        let end = timerManager.endDate ?? Date()

        if end.timeIntervalSince(left) <= graceSeconds {
            // the timer finished (or finishes) within the grace window: the bloom stands
            timerManager.resync()
            if timerManager.isRunning && currentSettings.notificationsEnabled {
                NotificationManager.shared.scheduleTimerComplete(in: timerManager.timeRemaining, isFocus: true)
            }
            return
        }

        if away <= graceSeconds {
            // came back in time: the sprout recovers before your eyes
            timerManager.resync()
            if currentSettings.notificationsEnabled {
                NotificationManager.shared.scheduleTimerComplete(in: timerManager.timeRemaining, isFocus: true)
            }
            playRecovery()
        } else {
            abandonSession(leftAt: left)
        }
    }

    private func playRecovery() {
        sproutPhase = .drooping
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                sproutPhase = .growing
            }
        }
    }

    private func abandonSession(leftAt left: Date) {
        let elapsed = Int(left.timeIntervalSince(sessionStartTime ?? left))
        timerManager.stop()
        NotificationManager.shared.cancelTimerComplete()

        if elapsed >= 60 {
            let session = FocusSession(
                tag: selectedTag,
                startedAt: sessionStartTime ?? Date(),
                duration: elapsed,
                completed: false,
                abandoned: true
            )
            modelContext.insert(session)
            try? modelContext.save()
        }

        clearPendingSession()
        timerManager.reset(duration: currentSettings.pomoDuration)
        playWiltGoodbye()
    }

    // wilted sprout is seen for a beat, then returns to the soil; drawn motion, no fade
    private func playWiltGoodbye() {
        sproutPhase = .wilted
        withAnimation {
            showFlowerMissed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeIn(duration: 0.5)) {
                sproutPhase = .sinking
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                sproutPhase = .none
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation {
                showFlowerMissed = false
            }
        }
    }

    // MARK: - Pending Session Persistence (survives app kill)

    private func persistPendingSession() {
        let d = UserDefaults.standard
        d.set(timerManager.endDate?.timeIntervalSince1970 ?? 0, forKey: PendingSessionKey.endDate)
        d.set((sessionStartTime ?? Date()).timeIntervalSince1970, forKey: PendingSessionKey.startedAt)
        d.set(currentSettings.pomoDuration, forKey: PendingSessionKey.total)
        d.set(pendingFlowerType, forKey: PendingSessionKey.flowerType)
        d.set(pendingFlowerX, forKey: PendingSessionKey.posX)
        d.set(pendingFlowerY, forKey: PendingSessionKey.posY)
        d.set(selectedTag?.id.uuidString, forKey: PendingSessionKey.tagId)
    }

    private func clearPendingSession() {
        let d = UserDefaults.standard
        PendingSessionKey.all.forEach { d.removeObject(forKey: $0) }
    }

    // app was killed mid-session: settle it honestly on next launch
    private func reconcilePersistedSession() {
        let d = UserDefaults.standard
        guard d.double(forKey: PendingSessionKey.endDate) > 0, !timerManager.isRunning else { return }

        let end = Date(timeIntervalSince1970: d.double(forKey: PendingSessionKey.endDate))
        let started = Date(timeIntervalSince1970: d.double(forKey: PendingSessionKey.startedAt))
        let bgEpoch = d.double(forKey: PendingSessionKey.backgroundedAt)
        let leftAt = bgEpoch > 0 ? Date(timeIntervalSince1970: bgEpoch) : nil
        let type = d.string(forKey: PendingSessionKey.flowerType) ?? FlowerDrop.randomType()
        let px = d.double(forKey: PendingSessionKey.posX)
        let py = d.double(forKey: PendingSessionKey.posY)
        let total = d.integer(forKey: PendingSessionKey.total)
        let tagId = d.string(forKey: PendingSessionKey.tagId).flatMap(UUID.init)
        let tag = tags.first { $0.id == tagId }
        clearPendingSession()

        if end <= Date(), leftAt == nil || end.timeIntervalSince(leftAt!) <= graceSeconds {
            // finished within grace (or without leaving): the flower still blooms
            let session = FocusSession(tag: tag, startedAt: started, duration: total, completed: true, abandoned: false)
            modelContext.insert(session)
            let flower = FlowerDrop(flowerType: type, size: FlowerDrop.sizeForDuration(total), positionX: px, positionY: py)
            modelContext.insert(flower)
            try? modelContext.save()
            return
        }

        // otherwise it was left behind: record honestly, no flower
        let cutoff = min(leftAt ?? Date(), end)
        let elapsed = Int(cutoff.timeIntervalSince(started))
        if elapsed >= 60 {
            let session = FocusSession(tag: tag, startedAt: started, duration: elapsed, completed: false, abandoned: true)
            modelContext.insert(session)
            try? modelContext.save()
        }
    }
}

// MARK: - Sprout Sprite

struct SproutSprite: View {
    let phase: SproutPhase

    private var angle: Double {
        switch phase {
        case .drooping: return -28
        case .wilted, .sinking: return -55
        default: return 0
        }
    }

    var body: some View {
        Image("sprout")
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
            .rotationEffect(.degrees(angle), anchor: .bottom)
            .scaleEffect(phase == .sinking ? 0.01 : 1, anchor: .bottom)
    }
}

// MARK: - Flower Sprite

struct FlowerSprite: View {
    let flowerType: String
    var size: CGFloat = 20

    // doodle placeholder assets; damla's final flowers replace these 1:1 by name
    private var assetName: String {
        switch flowerType {
        case "sunflower": return "flower_yellow"
        case "daisy": return "flower_blue"
        case "tulip": return "flower_red"
        case "rose": return "flower_purple"
        case "lavender": return "flower_purple"
        default: return "flower_yellow"
        }
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size * 2.2, height: size * 2.2)
    }
}

// MARK: - Tag Picker

struct TagPickerSheet: View {
    @Binding var selectedTag: FocusTag?
    let tags: [FocusTag]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.grassGreen.ignoresSafeArea()

                if tags.isEmpty {
                    VStack(spacing: 12) {
                        Text("no tags yet")
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("add tags in settings")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            Button {
                                selectedTag = nil
                                dismiss()
                            } label: {
                                HStack {
                                    Text("no tag")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    if selectedTag == nil {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.darkGreen)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            ForEach(tags) { tag in
                                Button {
                                    selectedTag = tag
                                    dismiss()
                                } label: {
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: tag.colorHex))
                                            .frame(width: 14, height: 14)
                                        Text(tag.name)
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundColor(.textPrimary)
                                        Spacer()
                                        if selectedTag?.id == tag.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.darkGreen)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Tag")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Tree Sprite

struct TreeSprite: View {
    let tag: FocusTag

    var body: some View {
        VStack(spacing: 0) {
            // Tree crown with apples
            ZStack {
                // Crown
                Image(systemName: "tree.fill")
                    .font(.system(size: tag.treeSizePoints))
                    .foregroundColor(Color(hex: tag.colorHex).opacity(0.8))

                // Apples (show up to 5 visually)
                let visibleApples = min(tag.appleCount, 5)
                ForEach(0..<visibleApples, id: \.self) { i in
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                        .offset(
                            x: CGFloat([-8, 10, -4, 12, 0][i]),
                            y: CGFloat([-6, -2, 4, 6, -10][i])
                        )
                }
            }

            // Label
            Text(tag.name)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.white.opacity(0.6))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Tree Detail Sheet

struct TreeDetailSheet: View {
    let tag: FocusTag
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.grassGreen.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Big tree
                    ZStack {
                        Image(systemName: "tree.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: tag.colorHex))

                        let visibleApples = min(tag.appleCount, 8)
                        ForEach(0..<visibleApples, id: \.self) { i in
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(
                                    x: CGFloat([-18, 22, -8, 28, 0, -24, 14, 6][i]),
                                    y: CGFloat([-14, -4, 10, 14, -22, 6, 20, -8][i])
                                )
                        }
                    }
                    .padding(.top, 20)

                    // Tag name
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: tag.colorHex))
                            .frame(width: 12, height: 12)
                        Text(tag.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                    }

                    // Stats
                    HStack(spacing: 20) {
                        TreeStat(icon: "apple.logo", value: "\(tag.appleCount)", label: "apples")
                        TreeStat(icon: "clock.fill", value: "\(tag.totalFocusMinutes)", label: "minutes")
                        TreeStat(icon: "tree.fill", value: tag.treeSize, label: "size")
                    }

                    // Planted date
                    Text("planted \(tag.createdAt.formatted(.dateTime.month().day().year()))")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)

                    Spacer()
                }
            }
            .navigationTitle("Tree Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TreeStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.darkGreen)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Duration Picker (fullscreen cover, like FocusPomo)

struct DurationPickerView: View {
    @Binding var pickerMinutes: Int
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.grassGreen.ignoresSafeArea()

            VStack {
                Spacer()

                // Big minutes display
                Text("\(pickerMinutes)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.default, value: pickerMinutes)

                Text("minutes")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Spacer().frame(height: 40)

                // Ruler
                HorizontalRulerPicker(selectedMinutes: $pickerMinutes)
                    .frame(height: 60)
                    .padding(.horizontal, 20)

                Spacer().frame(height: 40)

                // Done button
                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.5))
                        .clipShape(Capsule())
                }

                Spacer()
            }
        }
    }
}

// MARK: - Horizontal Ruler Picker (tap based, simple)

struct HorizontalRulerPicker: View {
    @Binding var selectedMinutes: Int
    let minValue = 5
    let maxValue = 120
    let step = 5

    private var values: [Int] {
        stride(from: minValue, through: maxValue, by: step).map { $0 }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(values, id: \.self) { value in
                        VStack(spacing: 6) {
                            Text("\(value)")
                                .font(.system(size: value == selectedMinutes ? 28 : 16, weight: value == selectedMinutes ? .bold : .regular, design: .rounded))
                                .foregroundColor(value == selectedMinutes ? .white : .white.opacity(0.3))

                            Rectangle()
                                .fill(value == selectedMinutes ? Color.white : Color.white.opacity(value % 10 == 0 ? 0.4 : 0.2))
                                .frame(width: 2, height: value % 10 == 0 ? 18 : 10)
                        }
                        .frame(width: 50)
                        .onTapGesture {
                            withAnimation {
                                selectedMinutes = value
                            }
                        }
                        .id(value)
                    }
                }
                .padding(.horizontal, 150)
            }
            .scrollTargetLayout()
            .onAppear {
                proxy.scrollTo(selectedMinutes, anchor: .center)
            }
            .onChange(of: selectedMinutes) { _, newVal in
                withAnimation {
                    proxy.scrollTo(newVal, anchor: .center)
                }
            }
        }
        .frame(height: 60)
    }
}

#Preview {
    TimerView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, GardenItem.self, UserSettings.self], inMemory: true)
}
