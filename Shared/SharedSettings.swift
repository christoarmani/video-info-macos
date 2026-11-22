import Foundation

/// Settings the app and its extensions both read (app group, team-prefixed).
enum SharedSettings {
    private static var defaults: UserDefaults { UserDefaults(suiteName: "4Z4N8C379F.com.christoarmani.videoinfo")! }

    static var quickLookEnabled: Bool {
        get { defaults.object(forKey: "quickLookEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "quickLookEnabled") }
    }
}
