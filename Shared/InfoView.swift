import AppKit
import SwiftUI

/// The file information panel: summary line, dates, then every MediaInfo section.
/// Used by the app window and the Quick Look preview.
struct InfoView: View {
    let url: URL
    var showsButtons = true
    var close: () -> Void = {}

    @State private var report: MediaReport?
    @State private var failed = false
    @State private var collapsed: Set<String> = []
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            if let report {
                content(report)
            } else if failed {
                ContentUnavailableView("Can't Read This File", systemImage: "film",
                                       description: Text("MediaInfo couldn't open \(url.lastPathComponent)."))
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if showsButtons {
                Divider()
                HStack {
                    Spacer()
                    Button(copied ? "Copied" : "Copy to Clipboard", action: copy)
                        .disabled(report == nil)
                    Button("Close", action: close)
                        .keyboardShortcut(.defaultAction)
                }
                .padding(20)
            }
        }
        .task(id: url) {
            let url = url
            let result = await Task.detached { MediaReport(url: url) }.value
            report = result
            failed = result == nil
        }
    }

    private func content(_ report: MediaReport) -> some View {
        Form {
            Section {
                Text(report.summary)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            let dates = report.dates(fileURL: url)
            if !dates.isEmpty {
                section("Dates", fields: dates)
            }
            ForEach(report.sections) { s in
                let codec = MediaReport.codecLabel(s).map { MediaReport.Field(label: "Codec", value: $0) }
                section(s.title, fields: (s.title.hasPrefix("Video") || s.title.hasPrefix("Audio") ? [codec].compactMap { $0 } : []) + s.fields)
            }
        }
        .formStyle(.grouped)
        .textSelection(.enabled)
    }

    private func section(_ title: String, fields: [MediaReport.Field]) -> some View {
        Section(title, isExpanded: Binding(
            get: { !collapsed.contains(title) },
            set: { open in if open { collapsed.remove(title) } else { collapsed.insert(title) } }
        )) {
            ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                LabeledContent(field.label, value: field.value)
            }
        }
    }

    private func copy() {
        guard let report else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report.text, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            copied = false
        }
    }
}
