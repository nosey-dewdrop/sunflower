import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @Query(sort: \FocusTag.createdAt) private var tags: [FocusTag]

    @State private var showAddTag = false
    @State private var newTagName = ""
    @State private var newTagColor = Color.warmYellow

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
                        .pixelFont(size: 28, bold: true)
                        .foregroundColor(.cream)
                        .padding(.top, 60)

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

                    SettingsPicker(
                        title: "short break",
                        value: Binding(
                            get: { settings.shortBreakDuration / 60 },
                            set: { settings.shortBreakDuration = $0 * 60 }
                        ),
                        range: Array(1...15),
                        suffix: "min"
                    )

                    SettingsPicker(
                        title: "long break",
                        value: Binding(
                            get: { settings.longBreakDuration / 60 },
                            set: { settings.longBreakDuration = $0 * 60 }
                        ),
                        range: Array(stride(from: 5, through: 30, by: 5)),
                        suffix: "min"
                    )

                    SettingsPicker(
                        title: "pomos before long break",
                        value: Binding(
                            get: { settings.pomosBeforeLongBreak },
                            set: { settings.pomosBeforeLongBreak = $0 }
                        ),
                        range: Array(2...6),
                        suffix: ""
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
                                .pixelFont(size: 16)
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
                                .pixelFont(size: 16)
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
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .pixelFont(size: 14, bold: true)
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
                .pixelFont(size: 15)
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
                    .pixelFont(size: 16, bold: true)
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
                .pixelFont(size: 15)
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
