import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct VideoInfoApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        // No main window: each video opens its own info window (AppDelegate).
        Settings { SettingsView() }
            .commands {
                CommandGroup(replacing: .newItem) {
                    Button("Open…") { delegate.showOpenPanel() }
                        .keyboardShortcut("o")
                }
            }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var welcome: NSWindow?

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "videoinfo" {
                // From the Finder extension: videoinfo:///open?path=/a.mkv&path=/b.mp4
                URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
                    .filter { $0.name == "path" }.compactMap(\.value)
                    .forEach { showInfo(for: URL(fileURLWithPath: $0)) }
            } else {
                showInfo(for: url)
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = self
        // Opened without a video: offer Open and Settings. If a video arrives a moment
        // later (Finder, Services), showInfo closes this window again.
        DispatchQueue.main.async { if !NSApp.windows.contains(where: \.isVisible) { self.showWelcome() } }
    }

    /// Dock icon clicked while nothing is open.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows { showWelcome() }
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func showWelcome() {
        if welcome == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: acceptingVideos(WelcomeView { [weak self] in self?.showOpenPanel() })))
            window.styleMask = [.titled, .closable]
            window.title = "Video Info"
            window.isReleasedWhenClosed = false
            window.center()
            welcome = window
        }
        welcome?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.allowsMultipleSelection = true
        NSApp.activate()
        // Not modal, so Settings… stays reachable while the panel is open.
        panel.begin { response in
            guard response == .OK else { return }
            panel.urls.forEach(self.showInfo)
        }
    }

    func showInfo(for url: URL) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 720),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.contentViewController = NSHostingController(rootView: acceptingVideos(InfoView(url: url) { [weak window] in window?.close() }))
        window.setContentSize(NSSize(width: 560, height: 720))
        window.contentMinSize = NSSize(width: 420, height: 320)
        window.title = url.lastPathComponent
        window.representedURL = url
        window.isReleasedWhenClosed = false
        if let key = NSApp.keyWindow, key !== welcome { window.cascadeTopLeft(from: NSPoint(x: key.frame.minX, y: key.frame.maxY)) } else { window.center() }
        window.makeKeyAndOrderFront(nil)
        welcome?.close()
        NSApp.activate()
    }

    /// Videos dropped on a window each open in their own info window.
    private func acceptingVideos(_ view: some View) -> some View {
        view.dropDestination(for: URL.self) { [weak self] urls, _ in
            let videos = urls.filter { (try? $0.resourceValues(forKeys: [.contentTypeKey]))?.contentType?.conforms(to: .movie) == true }
            videos.forEach { self?.showInfo(for: $0) }
            return !videos.isEmpty
        }
    }

    /// Services menu → "Video Info" (backup for when the Finder extension is off).
    @objc func showVideoInfo(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = pboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        urls.forEach(showInfo)
    }
}
