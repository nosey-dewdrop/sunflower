import SwiftUI
import SwiftData

enum TimerPhase: String {
    case focus = "Focus"
    case idle = "Ready"
}

@Observable
class TimerManager {
    var timeRemaining: Int = 1500
    var totalTime: Int = 1500
    var isRunning: Bool = false
    var phase: TimerPhase = .idle
    var timer: Timer?
    var onComplete: (() -> Void)?

    func start(duration: Int) {
        totalTime = duration
        timeRemaining = duration
        phase = .focus
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
                self.onComplete?()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
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
    @Query private var gardenItems: [GardenItem]

    @State private var timerManager = TimerManager()
    @State private var selectedTag: FocusTag?
    @State private var showTagPicker = false
    @State private var sessionStartTime: Date?
    @State private var showFlowerEarned = false
    @State private var showFlowerDied = false
    @State private var tappedTree: FocusTag?
    @State private var showDurationPicker = false
    @State private var showSummary = false
    @State private var pickerMinutes: Int = 25

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
                // Scrollable: Market (top) → Timer (center) → Summary (bottom)
                ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // === MARKET SECTION (scroll up to see) ===
                        MarketView()
                            .frame(height: screen.size.height)
                            .id("market")

                        // === TIMER SECTION ===
                        ZStack {
                            // Grass background
                            GeometryReader { geo in
                                Image("GrassTile")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            }
                            .ignoresSafeArea()

                            // Garden items
                            ForEach(gardenItems) { item in
                                DraggableGardenItem(item: item, geoSize: screen.size)
                            }

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

                                // Start Focus button
                                Button {
                                    handleMainButton()
                                } label: {
                                    Text(timerManager.isRunning ? "Stop" : "Start Focus")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
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
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        scrollProxy.scrollTo("timer", anchor: .top)
                    }
                }
                }

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

                if showFlowerDied {
                    VStack {
                        Spacer()
                        Text("your flower died...")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.85))
                            .clipShape(Capsule())
                        Spacer().frame(height: 100)
                    }
                    .animation(.spring(duration: 0.5), value: showFlowerDied)
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
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(to: newPhase)
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
            size: FlowerDrop.sizeForDuration(currentSettings.pomoDuration),
            positionX: Double.random(in: 0.1...0.9),
            positionY: Double.random(in: 0.5...0.85)
        )
        modelContext.insert(flower)
        try? modelContext.save()

        NotificationManager.shared.cancelAll()

        // Earn coins: 1 per minute
        let earnedCoins = currentSettings.pomoDuration / 60
        currentSettings.coins += earnedCoins
        try? modelContext.save()

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

    // MARK: - Forest Mode

    private func handleScenePhaseChange(to phase: ScenePhase) {
        switch phase {
        case .background:
            guard timerManager.isRunning else { return }

            // Leaving during focus = flower dies
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

            timerManager.reset(duration: currentSettings.pomoDuration)
            UserDefaults.standard.set(true, forKey: "flowerDied")

        case .active:
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

        default:
            break
        }
    }
}

// MARK: - Flower Sprite

struct FlowerSprite: View {
    let flowerType: String
    var size: CGFloat = 20

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
            .font(.system(size: size))
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

// MARK: - Draggable Garden Item

struct DraggableGardenItem: View {
    let item: GardenItem
    let geoSize: CGSize
    @State private var dragOffset: CGSize = .zero

    private var itemIcon: String {
        switch item.itemType {
        case "oak": return "tree.fill"
        case "pine": return "tree.fill"
        case "cherry": return "tree.fill"
        case "birch": return "tree.fill"
        case "sunflower": return "sun.max.fill"
        case "daisy": return "sparkle"
        case "tulip": return "leaf.fill"
        case "rose": return "heart.fill"
        case "lavender": return "star.fill"
        case "fence": return "rectangle.split.3x1"
        case "rock": return "mountain.2.fill"
        case "pond": return "drop.fill"
        default: return "circle.fill"
        }
    }

    private var itemColor: Color {
        switch item.itemType {
        case "oak": return .green
        case "pine": return Color(hex: "2D5A3D")
        case "cherry": return .pink
        case "birch": return Color(hex: "96CEB4")
        case "sunflower": return .warmYellow
        case "daisy": return .white
        case "tulip": return .red
        case "rose": return .pink
        case "lavender": return .purple
        case "fence": return .brown
        case "rock": return .gray
        case "pond": return .blue
        default: return .warmYellow
        }
    }

    var body: some View {
        Image(systemName: itemIcon)
            .font(.system(size: item.displaySize))
            .foregroundColor(itemColor)
            .position(
                x: item.positionX * geoSize.width + dragOffset.width,
                y: item.positionY * geoSize.height + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let newX = (item.positionX * geoSize.width + value.translation.width) / geoSize.width
                        let newY = (item.positionY * geoSize.height + value.translation.height) / geoSize.height
                        item.positionX = max(0.05, min(0.95, newX))
                        item.positionY = max(0.3, min(0.9, newY))
                        dragOffset = .zero
                    }
            )
    }
}

#Preview {
    TimerView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, GardenItem.self, UserSettings.self], inMemory: true)
}
