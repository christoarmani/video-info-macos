import AppKit
import QuickLookUI
import SwiftUI

/// Spacebar preview: the same info panel, without the window buttons.
final class PreviewViewController: NSViewController, QLPreviewingController {
    override func loadView() { view = NSView() }

    func preparePreviewOfFile(at url: URL) async throws {
        // Turned off in Settings: decline, so Quick Look shows its standard preview instead.
        guard SharedSettings.quickLookEnabled else { throw CocoaError(.featureUnsupported) }
        let host = NSHostingView(rootView: InfoView(url: url, showsButtons: false))
        host.frame = view.bounds
        host.autoresizingMask = [.width, .height]
        view.addSubview(host)
        preferredContentSize = NSSize(width: 560, height: 720)
    }
}
