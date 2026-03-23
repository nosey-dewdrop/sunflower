import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @Query(sort: \FocusTag.createdAt) private var tags: [FocusTag]

    @State private var showAddTag = false
    @State private var showMarket = false
    @State private var newTagName = ""

    private var settings: UserSettings {
        if let first = settingsList.first {
            return first
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        try? modelContext.save()
        return newSettings
    }

    var body: some View {
        ZStack {
            Color.darkGreen.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.cream)
                        .padding(.top, 60)

                    // Market
                    Button {
                        showMarket = true
                    } label: {
                        HStack {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 18))
                            Text("Market")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .font(.system(size: 12))
                                Text("\(settings.coins)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.warmYellow)
                        }
                        .foregroundColor(.cream)
                        .padding()
                        .background(Color.grassGreen.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Timer settings
                    SectionHeader(title: "timer")

                    SettingsPicker(
                        title: "focus duration",
                        value: Binding(
                            get: { settings.pomoDuration / 60 },
                            set: { settings.pomoDuration = $0 * 60 }
                        ),
                        range: Array(stride(from: 5, through: 60, by: 5)),
                        suffix: "min"
                    )

                    // Preferences
                    SectionHeader(title: "preferences")

                    SettingsToggle(
                        title: "notifications",
                        isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { settings.notificationsEnabled = $0 }
                        )
                    )

                    SettingsToggle(
                        title: "week starts monday",
                        isOn: Binding(
                            get: { settings.weekStartMonday },
                            set: { settings.weekStartMonday = $0 }
                        )
                    )

                    // Tags
                    SectionHeader(title: "tags")

                    ForEach(tags) { tag in
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.colorHex))
                                .frame(width: 14, height: 14)
                            Text(tag.name)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.cream)
                            Spacer()
                            Button {
                                modelContext.delete(tag)
                                try? modelContext.save()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.cream.opacity(0.4))
                            }
                        }
                        .padding()
                        .background(Color.grassGreen.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button {
                        showAddTag = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("add tag")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                        }
                        .foregroundColor(.warmYellow)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.grassGreen.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
        }
        .alert("New Tag", isPresented: $showAddTag) {
            TextField("tag name", text: $newTagName)
            Button("Add") {
                guard !newTagName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                let hexColors = ["F4D35E", "FF6B6B", "4ECDC4", "45B7D1", "96CEB4", "FFEAA7", "DDA0DD", "FF8C69"]
                let hex = hexColors.randomElement() ?? "F4D35E"
                let tag = FocusTag(name: newTagName.trimmingCharacters(in: .whitespaces), colorHex: hex)
                modelContext.insert(tag)
                try? modelContext.save()
                newTagName = ""
            }
            Button("Cancel", role: .cancel) {
                newTagName = ""
            }
        } message: {
            Text("Enter a name for the new tag")
        }
        .sheet(isPresented: $showMarket) {
            MarketView()
        }
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.warmYellow)
            .textCase(.uppercase)
    }
}

struct SettingsPicker: View {
    let title: String
    @Binding var value: Int
    let range: [Int]
    let suffix: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.cream)
            Spacer()
            HStack(spacing: 12) {
                Button {
                    if let idx = range.firstIndex(of: value), idx > 0 {
                        value = range[idx - 1]
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.cream.opacity(0.6))
                }

                Text("\(value)\(suffix.isEmpty ? "" : " \(suffix)")")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.warmYellow)
                    .frame(minWidth: 60)

                Button {
                    if let idx = range.firstIndex(of: value), idx < range.count - 1 {
                        value = range[idx + 1]
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.cream.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.grassGreen.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.cream)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(.warmYellow)
        }
        .padding()
        .background(Color.grassGreen.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self], inMemory: true)
}
