import SwiftUI
import SwiftData

struct MarketView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [UserSettings]

    @State private var selectedCategory = "tree"
    @State private var boughtItem: String?

    private var settings: UserSettings {
        if let first = settingsList.first { return first }
        let s = UserSettings()
        modelContext.insert(s)
        try? modelContext.save()
        return s
    }

    let categories = ["tree", "flower", "decoration"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkGreen.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Coin balance
                    HStack {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundColor(.warmYellow)
                        Text("\(settings.coins) coins")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.warmYellow)
                    }
                    .padding(.top, 8)

                    // Category tabs
                    HStack(spacing: 0) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                withAnimation { selectedCategory = cat }
                            } label: {
                                Text(cat)
                                    .font(.system(size: 14, weight: selectedCategory == cat ? .bold : .regular, design: .rounded))
                                    .foregroundColor(selectedCategory == cat ? .darkGreen : .cream)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? Color.warmYellow : Color.clear)
                            }
                        }
                    }
                    .background(Color.grassGreen.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)

                    // Items grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(ShopItem.forCategory(selectedCategory)) { item in
                                MarketItemCard(item: item, coins: settings.coins) {
                                    buyItem(item)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Bought feedback
                    if let name = boughtItem {
                        Text("\(name) bought!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.warmYellow)
                            .transition(.opacity)
                    }
                }
            }
            .navigationTitle("Market")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.warmYellow)
                }
            }
        }
    }

    private func buyItem(_ item: ShopItem) {
        guard settings.coins >= item.price else { return }
        settings.coins -= item.price

        let gardenItem = GardenItem(
            itemType: item.itemType,
            category: item.category,
            positionX: Double.random(in: 0.15...0.85),
            positionY: Double.random(in: 0.45...0.8)
        )
        modelContext.insert(gardenItem)
        try? modelContext.save()

        withAnimation {
            boughtItem = item.name
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { boughtItem = nil }
        }
    }
}

struct MarketItemCard: View {
    let item: ShopItem
    let coins: Int
    let onBuy: () -> Void

    private var canAfford: Bool { coins >= item.price }

    var body: some View {
        Button(action: onBuy) {
            VStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.system(size: 28))
                    .foregroundColor(itemColor)

                Text(item.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.cream)

                HStack(spacing: 2) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 10))
                    Text("\(item.price)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(canAfford ? .warmYellow : .cream.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.grassGreen.opacity(canAfford ? 0.5 : 0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!canAfford)
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
}

#Preview {
    MarketView()
        .modelContainer(for: [UserSettings.self, GardenItem.self], inMemory: true)
}
