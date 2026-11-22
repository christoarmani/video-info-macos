import SwiftUI

/// Shown when Video Info is opened from the Dock or Finder without a video.
struct WelcomeView: View {
    let openVideo: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Video Info", systemImage: "film")
        } description: {
            Text("Right-click a video in Finder and choose Video Info, or open one here.")
        } actions: {
            Button("Open Video…", action: openVideo)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            SettingsLink { Text("Settings…") }
        }
        // ContentUnavailableView scrolls, so it has no natural height of its own: size the window.
        .frame(width: 380, height: 260)
    }
}
