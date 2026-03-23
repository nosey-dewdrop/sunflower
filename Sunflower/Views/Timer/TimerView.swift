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
        isRunning = true
        phase = .focus
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
                self.onFocusComplete?()
            }
        }
    }

    func startBreak(duration: Int, isLong: Bool) {
        totalTime = duration
        timeRemaining = duration
        isRunning = true
        phase = isLong ? .longBreak : .shortBreak
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
                self.phase = .idle
                self.onBreakComplete?()
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
            ForEach(flowers) { flower in
                FlowerSprite(flowerType: flower.flowerType)
                    .position(
                        x: flower.positionX * UIScreen.main.bounds.width,
                        y: flower.positionY * UIScreen.main.bounds.height
                    )
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
                                .pixelFont(size: 14, bold: true)
                        } else {
                            Text("select tag")
                                .pixelFont(size: 14)
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
                            .pixelFont(size: 10)
                    }
                    .foregroundColor(.cream.opacity(0.6))
                }

                Spacer()

                // Phase indicator
                Text(timerManager.phase.rawValue)
                    .pixelFont(size: 18, bold: true)
                    .foregroundColor(.warmYellow)

                // Big countdown
                Text(timerManager.timeString)
                    .pixelFont(size: 72, bold: true)
                    .foregroundColor(.cream)
                    .shadow(color: .darkGreen, radius: 0, x: 2, y: 2)

                // Start/Stop button
                Button {
                    handleMainButton()
                } label: {
                    Text(buttonLabel)
                        .pixelFont(size: 24, bold: true)
                        .foregroundColor(timerManager.isRunning ? .cream : .darkGreen)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(timerManager.isRunning ? Color.brown.opacity(0.8) : Color.warmYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Cycle indicator
                Text("pomodoro \(currentPomoCount)/\(pomosBeforeLong)")
                    .pixelFont(size: 14)
                    .foregroundColor(.cream.opacity(0.7))

                Spacer()

                // Today's count
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.warmYellow)
                    Text("\(todayCompletedCount) today")
                        .pixelFont(size: 16, bold: true)
                        .foregroundColor(.cream)
                }
                .padding(.bottom, 40)
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
    }

    private func handleMainButton() {
        if timerManager.isRunning {
            // Stop pressed
            let elapsed = timerManager.elapsedSeconds
            let wasInFocus = timerManager.phase == .focus
            timerManager.stop()

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
            // Start new focus session
            sessionStartTime = Date()
            timerManager.start(duration: currentSettings.pomoDuration)
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

        // Spawn flower
        let flower = FlowerDrop(
            flowerType: FlowerDrop.randomType(),
            positionX: Double.random(in: 0.1...0.9),
            positionY: Double.random(in: 0.5...0.85)
        )
        modelContext.insert(flower)
        try? modelContext.save()

        // Advance cycle
        if currentPomoCount >= pomosBeforeLong {
            currentPomoCount = 1
            timerManager.startBreak(duration: currentSettings.longBreakDuration, isLong: true)
        } else {
            currentPomoCount += 1
            timerManager.startBreak(duration: currentSettings.shortBreakDuration, isLong: false)
        }
    }
}

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
                            .pixelFont(size: 18)
                            .foregroundColor(.cream)
                        Text("add tags in settings")
                            .pixelFont(size: 14)
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
                                        .pixelFont(size: 16)
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
                                            .pixelFont(size: 16)
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
