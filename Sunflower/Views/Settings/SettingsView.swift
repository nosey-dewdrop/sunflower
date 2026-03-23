import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @Query(sort: \FocusTag.createdAt) private var tags: [FocusTag]

    @State private var showAddTag = false
    @State private var newTagName = ""

    private var settings: UserSettings {
        if let first = settingsList.first { return first }
        let s = UserSettings()
        modelContext.insert(s)
        try? modelContext.save()
        return s
    }

    var body: some View {
        ZStack {
            Color.grassGreen.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome header
                    Text("Welcome ^ ^")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .padding(.top, 60)

                    Text("What I do today is important because I am exchanging a day of my life for it.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)

                    // Premium banner
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sunflower Plus")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Grow your garden, unlock more")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Timer section
                    SettingsSectionHeader(title: "Timer")

                    SettingsCard {
                        SettingsRow(title: "Focus Duration", trailing: "\(settings.pomoDuration / 60) min") {}
                    }

                    // Tags section
                    SettingsSectionHeader(title: "Tags")

                    SettingsCard {
                        ForEach(tags) { tag in
                            HStack {
                                Circle()
                                    .fill(Color(hex: tag.colorHex))
                                    .frame(width: 12, height: 12)
                                Text(tag.name)
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Button {
                                    modelContext.delete(tag)
                                    try? modelContext.save()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(.textSecondary.opacity(0.5))
                                }
                            }
                            .padding(.vertical, 4)

                            if tag.id != tags.last?.id {
                                Divider().background(Color.textSecondary.opacity(0.15))
                            }
                        }

                        Button {
                            showAddTag = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 14))
                                Text("Add Tag")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                            }
                            .foregroundColor(.darkGreen)
                            .padding(.top, 4)
                        }
                    }

                    // Notifications section
                    SettingsSectionHeader(title: "Notifications")

                    SettingsCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Focus Reminder")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Text("You will receive notification after you finish focus.")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { settings.notificationsEnabled },
                                set: { settings.notificationsEnabled = $0 }
                            ))
                            .tint(.darkGreen)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
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
            Button("Cancel", role: .cancel) { newTagName = "" }
        } message: {
            Text("Enter a name for the new tag")
        }
    }
}

// MARK: - Settings Components

struct SettingsSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.textSecondary)
            .textCase(.uppercase)
    }
}

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct SettingsRow: View {
    let title: String
    let trailing: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(trailing)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self, GardenItem.self], inMemory: true)
}
