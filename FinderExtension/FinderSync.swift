import AppKit
import FinderSync
import UniformTypeIdentifiers
import os

private let log = Logger(subsystem: "com.christoarmani.videoinfo", category: "finder")

/// Adds "Video Info" to Finder's right-click menu, only when every selected item is a video.
final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Watch the whole disk plus every mounted volume, so the item shows up everywhere.
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) ?? []
        FIFinderSyncController.default().directoryURLs = Set([URL(fileURLWithPath: "/")] + volumes)
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didMountNotification, object: nil, queue: .main) { note in
            guard let url = note.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
            FIFinderSyncController.default().directoryURLs.insert(url)
        }
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems,
              let urls = FIFinderSyncController.default().selectedItemURLs(), !urls.isEmpty,
              urls.allSatisfy(Self.isVideo) else { return nil }
        let menu = NSMenu()
        let item = menu.addItem(withTitle: "Video Info", action: #selector(showInfo(_:)), keyEquivalent: "")
        // Finder draws extension icons black (it drops the template flag), so no visible icon.
        // A blank one keeps the text lined up with the other items' text (Chris, 2026-11-22).
        item.image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { _ in true }
        return menu
    }

    @objc func showInfo(_ sender: Any?) {
        guard let urls = FIFinderSyncController.default().selectedItemURLs(), !urls.isEmpty else { return }
        var link = URLComponents()
        link.scheme = "videoinfo"
        link.path = "/open"
        link.queryItems = urls.map { URLQueryItem(name: "path", value: $0.path) }
        guard let url = link.url else { return }
        NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error { log.error("open failed: \(error.localizedDescription, privacy: .public)") }
        }
    }

    static func isVideo(_ url: URL) -> Bool {
        // .ts/.mts are also TypeScript files; a real transport stream has the 0x47 sync byte at 0 (TS) or 4 (M2TS/AVCHD).
        if ["ts", "mts", "m2ts"].contains(url.pathExtension.lowercased()) {
            guard let handle = try? FileHandle(forReadingFrom: url), let head = try? handle.read(upToCount: 5) else { return true }
            return head.first == 0x47 || (head.count == 5 && head[4] == 0x47)
        }
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType, type.conforms(to: .movie) { return true }
        // Formats macOS doesn't always type as movies.
        return ["mkv", "webm", "avi", "wmv", "flv", "ts", "m2ts", "mts", "vob", "ogv", "rmvb", "rm", "3gp", "divx", "asf"]
            .contains(url.pathExtension.lowercased())
    }
}
