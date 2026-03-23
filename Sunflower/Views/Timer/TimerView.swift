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
    @Query private var gardenItems: [GardenItem]
    @Query(filter: #Predicate<FocusSession> { session in
        session.completed == true
    }) private var allCompletedSessions: [FocusSession]

    @State private var timerManager = TimerManager()
    @State private var selectedTag: FocusTag?
    @State private var showTagPicker = false
    @State private var showSummary = false
    @State private var showMarket = false
    @State private var sessionStartTime: Date?
    @State private var showFlowerEarned = false
    @State private var showFlowerDied = false
    @State private var tappedTree: FocusTag?

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
            Color.grassGreen
                .ignoresSafeArea()

            // Garden: draggable items, trees, flowers
            GeometryReader { geo in
                // Garden items (from market)
                ForEach(gardenItems) { item in
                    DraggableGardenItem(item: item, geoSize: geo.size)
                }

                // Trees from tags
                ForEach(tags) { tag in
                    if tag.appleCount > 0 {
                        TreeSprite(tag: tag)
                            .position(
                                x: tag.treePositionX * geo.size.width,
                                y: tag.treePositionY * geo.size.height
                            )
                            .onTapGesture {
                                tappedTree = tag
                            }
                    }
                }

                // Flower drops (earned from sessions)
                ForEach(flowers) { flower in
                    FlowerSprite(flowerType: flower.flowerType, size: flower.displaySize)
                        .position(
                            x: flower.positionX * geo.size.width,
                            y: flower.positionY * geo.size.height
                        )
                }
            }

            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 60)

                // Top bar: coins + market
                HStack {
                    // Coin balance
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundColor(.warmYellow)
                        Text("\(currentSettings.coins)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.warmYellow)
                    }

                    Spacer()

                    // Market button
                    Button {
                        showMarket = true
                    } label: {
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.cream)
                            .padding(8)
                            .background(Color.darkGreen.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)

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
                    Text(timerManager.isRunning ? "STOP" : "START")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(timerManager.isRunning ? .cream : .darkGreen)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(timerManager.isRunning ? Color.brown.opacity(0.8) : Color.warmYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

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
        .sheet(item: $tappedTree) { tag in
            TreeDetailSheet(tag: tag)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showMarket) {
            MarketView()
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
                .foregroundColor(.cream)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.darkGreen.opacity(0.6))
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
                Color.darkGreen.ignoresSafeArea()

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
                            .foregroundColor(.cream)
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
                        .foregroundColor(.cream.opacity(0.5))

                    Spacer()
                }
            }
            .navigationTitle("Tree Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                .foregroundColor(.warmYellow)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.cream)
            Text(label)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(.cream.opacity(0.6))
        }
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
