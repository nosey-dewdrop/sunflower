import SwiftUI
import SwiftData

enum TimerPhase: String {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    case idle = "Ready"
}

@Observable
class TimerManager {
    var timeRemaining: Int = 1500
    var totalTime: Int = 1500
    var isRunning: Bool = false
    var phase: TimerPhase = .idle
    var timer: Timer?
    var onFocusComplete: (() -> Void)?
    var onBreakComplete: (() -> Void)?

    func start(duration: Int) {
        totalTime = duration
        timeRemaining = duration
        phase = .focus
        startTimer()
    }

    func startBreak(duration: Int, isLong: Bool) {
        totalTime = duration
        timeRemaining = duration
        phase = isLong ? .longBreak : .shortBreak
        startTimer()
    }

    func resume() {
        startTimer()
    }

    private func startTimer() {
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
                if self.phase == .focus {
                    self.onFocusComplete?()
                } else {
                    self.phase = .idle
                    self.onBreakComplete?()
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        stop()
        phase = .idle
        timeRemaining = totalTime
    }

    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
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
    @Query(filter: #Predicate<FocusSession> { session in
        session.completed == true
    }) private var allCompletedSessions: [FocusSession]

    @State private var timerManager = TimerManager()
    @State private var selectedTag: FocusTag?
    @State private var showTagPicker = false
    @State private var showSummary = false
    @State private var sessionStartTime: Date?
    @State private var currentPomoCount: Int = 1
    @State private var pomosBeforeLong: Int = 4
    @State private var showFlowerEarned = false
    @State private var showFlowerDied = false

    private var currentSettings: UserSettings {
        if let first = settings.first {
            return first
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        try? modelContext.save()
        return newSettings
    }

    private var todayCompletedCount: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return allCompletedSessions.filter { $0.startedAt >= startOfDay }.count
    }

    var body: some View {
        ZStack {
            // Background
            Color.grassGreen
                .ignoresSafeArea()

            // Flower drops scattered on background
            GeometryReader { geo in
                ForEach(flowers) { flower in
                    FlowerSprite(flowerType: flower.flowerType)
                        .position(
                            x: flower.positionX * geo.size.width,
                            y: flower.positionY * geo.size.height
                        )
                }
            }

            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 60)

                // Tag selector pill
                Button {
                    showTagPicker = true
                } label: {
                    HStack(spacing: 6) {
                        if let tag = selectedTag {
                            Circle()
                                .fill(Color(hex: tag.colorHex))
                                .frame(width: 10, height: 10)
                            Text(tag.name)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        } else {
                            Text("select tag")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.darkGreen.opacity(0.7))
                    .foregroundColor(.cream)
                    .clipShape(Capsule())
                }

                // Summary pull-down hint
                Button {
                    showSummary = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                        Text("today")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                    }
                    .foregroundColor(.cream.opacity(0.6))
                }

                Spacer()

                // Phase indicator
                Text(timerManager.phase.rawValue)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.warmYellow)

                // Big countdown
                Text(timerManager.timeString)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.cream)
                    .shadow(color: .darkGreen, radius: 0, x: 2, y: 2)
                    .contentTransition(.numericText())
                    .animation(.default, value: timerManager.timeRemaining)

                // Start/Stop button
                Button {
                    handleMainButton()
                } label: {
                    Text(buttonLabel)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(timerManager.isRunning ? .cream : .darkGreen)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(timerManager.isRunning ? Color.brown.opacity(0.8) : Color.warmYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .scaleEffect(timerManager.isRunning ? 0.98 : 1.0)
                }

                // Cycle indicator
                Text("pomodoro \(currentPomoCount)/\(pomosBeforeLong)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.cream.opacity(0.7))

                Spacer()

                // Today's count
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.warmYellow)
                    Text("\(todayCompletedCount) today")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.cream)
                }
                .padding(.bottom, 40)
            }

            // Flower earned overlay
            if showFlowerEarned {
                VStack {
                    Spacer()
                    Text("flower earned!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.warmYellow)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.darkGreen.opacity(0.9))
                        .clipShape(Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    Spacer().frame(height: 100)
                }
                .animation(.spring(duration: 0.5), value: showFlowerEarned)
            }

            // Flower died overlay
            if showFlowerDied {
                VStack {
                    Spacer()
                    Text("your flower died...")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.darkGreen.opacity(0.9))
                        .clipShape(Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    Spacer().frame(height: 100)
                }
                .animation(.spring(duration: 0.5), value: showFlowerDied)
            }
        }
        .sheet(isPresented: $showTagPicker) {
            TagPickerSheet(selectedTag: $selectedTag, tags: tags)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSummary) {
            SummaryView()
                .presentationDetents([.large])
        }
        .onAppear {
            setupTimer()
            restoreBreakState()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(to: newPhase)
        }
    }

    private var buttonLabel: String {
        if timerManager.isRunning {
            return "STOP"
        }
        if timerManager.phase == .idle {
            return "START"
        }
        return "SKIP"
    }

    // MARK: - Setup

    private func setupTimer() {
        let s = currentSettings
        timerManager.totalTime = s.pomoDuration
        timerManager.timeRemaining = s.pomoDuration
        pomosBeforeLong = s.pomosBeforeLongBreak

        timerManager.onFocusComplete = {
            handleFocusComplete()
        }

        timerManager.onBreakComplete = {
            timerManager.timeRemaining = currentSettings.pomoDuration
            timerManager.totalTime = currentSettings.pomoDuration
        }

        NotificationManager.shared.requestPermission()
    }

    // MARK: - Button Actions

    private func handleMainButton() {
        if timerManager.isRunning {
            let elapsed = timerManager.elapsedSeconds
            let wasInFocus = timerManager.phase == .focus
            timerManager.stop()
            NotificationManager.shared.cancelAll()

            if wasInFocus && elapsed >= 60 {
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

            timerManager.phase = .idle
            timerManager.timeRemaining = currentSettings.pomoDuration
            timerManager.totalTime = currentSettings.pomoDuration
        } else {
            sessionStartTime = Date()
            timerManager.start(duration: currentSettings.pomoDuration)
            NotificationManager.shared.scheduleTimerComplete(in: currentSettings.pomoDuration, isFocus: true)
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

        let flower = FlowerDrop(
            flowerType: FlowerDrop.randomType(),
            positionX: Double.random(in: 0.1...0.9),
            positionY: Double.random(in: 0.5...0.85)
        )
        modelContext.insert(flower)
        try? modelContext.save()

        NotificationManager.shared.cancelAll()

        // Show flower earned feedback
        withAnimation {
            showFlowerEarned = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showFlowerEarned = false
            }
        }

        // Advance cycle
        if currentPomoCount >= pomosBeforeLong {
            currentPomoCount = 1
            timerManager.startBreak(duration: currentSettings.longBreakDuration, isLong: true)
            NotificationManager.shared.scheduleTimerComplete(in: currentSettings.longBreakDuration, isFocus: false)
        } else {
            currentPomoCount += 1
            timerManager.startBreak(duration: currentSettings.shortBreakDuration, isLong: false)
            NotificationManager.shared.scheduleTimerComplete(in: currentSettings.shortBreakDuration, isFocus: false)
        }
    }

    // MARK: - Background State (Forest Mode)
    // If you leave the app during focus → your flower dies, session abandoned.
    // During breaks → timer continues in background normally.

    private func handleScenePhaseChange(to phase: ScenePhase) {
        switch phase {
        case .background:
            guard timerManager.isRunning else { return }

            if timerManager.phase == .focus {
                // FOREST MODE: leaving during focus = flower dies
                let elapsed = timerManager.elapsedSeconds
                timerManager.stop()
                NotificationManager.shared.cancelAll()

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

                timerManager.phase = .idle
                timerManager.timeRemaining = currentSettings.pomoDuration
                timerManager.totalTime = currentSettings.pomoDuration

                // Flag to show death message when returning
                UserDefaults.standard.set(true, forKey: "flowerDied")
            } else {
                // During break → save state, continue in background
                saveBreakState()
                timerManager.stop()
            }

        case .active:
            // Check if flower died
            if UserDefaults.standard.bool(forKey: "flowerDied") {
                UserDefaults.standard.set(false, forKey: "flowerDied")
                withAnimation {
                    showFlowerDied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showFlowerDied = false
                    }
                }
            }

            // Restore break state if needed
            restoreBreakState()

        default:
            break
        }
    }

    private func saveBreakState() {
        let endTime = Date().addingTimeInterval(TimeInterval(timerManager.timeRemaining))
        let defaults = UserDefaults.standard
        defaults.set(endTime.timeIntervalSince1970, forKey: "breakEndTime")
        defaults.set(timerManager.phase.rawValue, forKey: "breakPhase")
        defaults.set(true, forKey: "isBreakRunning")
    }

    private func restoreBreakState() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "isBreakRunning") else { return }

        let endTimeInterval = defaults.double(forKey: "breakEndTime")
        guard endTimeInterval > 0 else { return }

        let endTime = Date(timeIntervalSince1970: endTimeInterval)
        let remaining = Int(endTime.timeIntervalSinceNow)

        defaults.set(false, forKey: "isBreakRunning")
        defaults.removeObject(forKey: "breakEndTime")
        defaults.removeObject(forKey: "breakPhase")

        if remaining <= 0 {
            // Break completed in background
            timerManager.phase = .idle
            timerManager.timeRemaining = currentSettings.pomoDuration
            timerManager.totalTime = currentSettings.pomoDuration
        } else {
            // Break still running, resume
            let phaseStr = defaults.string(forKey: "breakPhase") ?? ""
            timerManager.phase = TimerPhase(rawValue: phaseStr) ?? .shortBreak
            timerManager.timeRemaining = remaining
            timerManager.resume()
        }
    }
}

// MARK: - Flower Sprite

struct FlowerSprite: View {
    let flowerType: String

    private var symbol: String {
        switch flowerType {
        case "sunflower": return "sun.max.fill"
        case "daisy": return "sparkle"
        case "tulip": return "leaf.fill"
        case "rose": return "heart.fill"
        case "lavender": return "star.fill"
        default: return "sun.max.fill"
        }
    }

    private var color: Color {
        switch flowerType {
        case "sunflower": return .warmYellow
        case "daisy": return .white
        case "tulip": return .red
        case "rose": return .pink
        case "lavender": return .purple
        default: return .warmYellow
        }
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 20))
            .foregroundColor(color)
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
                Color.darkGreen.ignoresSafeArea()

                if tags.isEmpty {
                    VStack(spacing: 12) {
                        Text("no tags yet")
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundColor(.cream)
                        Text("add tags in settings")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.cream.opacity(0.6))
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
                                        .foregroundColor(.cream)
                                    Spacer()
                                    if selectedTag == nil {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.warmYellow)
                                    }
                                }
                                .padding()
                                .background(Color.grassGreen.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                                            .foregroundColor(.cream)
                                        Spacer()
                                        if selectedTag?.id == tag.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.warmYellow)
                                        }
                                    }
                                    .padding()
                                    .background(Color.grassGreen.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    TimerView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self], inMemory: true)
}
