import Foundation
import FamilyControls
import ManagedSettings

// Pro: blocks the user's chosen distracting apps while a focus session runs.
// The shield is raised when a session starts and lowered on complete/abandon,
// plus defensively on launch so a crash can never leave apps locked forever.
@Observable
final class FocusShield {
    static let shared = FocusShield()

    private static let selectionKey = "focusShield.selection"
    private static let enabledKey = "focusShield.enabled"

    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("focus"))

    var isAuthorized: Bool
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }
    var selection: FamilyActivitySelection {
        didSet {
            if let data = try? PropertyListEncoder().encode(selection) {
                UserDefaults.standard.set(data, forKey: Self.selectionKey)
            }
        }
    }

    private init() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        if let data = UserDefaults.standard.data(forKey: Self.selectionKey),
           let saved = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        } else {
            selection = FamilyActivitySelection()
        }
    }

    var hasSelection: Bool {
        !(selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty)
    }

    @MainActor
    func authorize() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
        return isAuthorized
    }

    func activate() {
        guard isEnabled, isAuthorized, hasSelection else { return }
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
    }

    // safe to call anytime, even when no shield is up
    func deactivate() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
