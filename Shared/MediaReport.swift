import Foundation

/// MediaInfo's text report for one file, split into sections (General, Video, Audio #1…),
/// plus the summary line, plain codec names and dates Video Info adds on top.
struct MediaReport: Sendable {
    struct Field: Hashable, Sendable {
        let label: String
        let value: String
    }

    struct Section: Identifiable, Sendable {
        let title: String
        var fields: [Field]
        var id: String { title }
        subscript(label: String) -> String? { fields.first { $0.label == label }?.value }
    }

    /// MediaInfo's own text (what PotPlayer copies), with the folder path left out.
    let text: String
    let sections: [Section]

    /// Reads the file with the bundled MediaInfo library. Nil if MediaInfo can't open it.
    init?(url: URL) {
        guard let text = Self.inform(path: url.path) else { return nil }
        self.init(text: text)
    }

    init(text raw: String) {
        var sections: [Section] = []
        var lines: [String] = []
        for line in raw.components(separatedBy: .newlines) {
            if let sep = line.range(of: " : ") {
                let label = line[..<sep.lowerBound].trimmingCharacters(in: .whitespaces)
                var value = line[sep.upperBound...].trimmingCharacters(in: .whitespaces)
                var line = line
                if label == "Complete name" {
                    // Privacy: keep the file name, drop the folders it sits in.
                    value = (value as NSString).lastPathComponent
                    line = String(line[..<sep.upperBound]) + value
                }
                sections.indices.last.map { sections[$0].fields.append(Field(label: label, value: value)) }
                lines.append(line)
            } else {
                let title = line.trimmingCharacters(in: .whitespaces)
                if !title.isEmpty { sections.append(Section(title: title, fields: [])) }
                lines.append(line)
            }
        }
        self.sections = sections
        self.text = lines.joined(separator: "\n").trimmingCharacters(in: .newlines) + "\n"
    }

    private func first(_ prefix: String) -> Section? { sections.first { $0.title.hasPrefix(prefix) } }

    // MARK: Summary line

    /// "H.264 · 1920×1080 · 29.97 fps · AAC 2.0 · 37 min 1 s · 2.18 GiB"
    var summary: String {
        var parts: [String] = []
        if let video = first("Video") {
            if let codec = Self.plainCodec(video) { parts.append(codec) }
            if let w = video["Width"].map(Self.digits), let h = video["Height"].map(Self.digits) { parts.append("\(w)×\(h)") }
            if let fps = video["Frame rate"].flatMap(Self.fps) { parts.append("\(fps) fps") }
        }
        if let audio = first("Audio") {
            parts.append([Self.plainCodec(audio), Self.channels(audio)].compactMap { $0 }.joined(separator: " "))
        }
        let general = first("General")
        if let duration = general?["Duration"] { parts.append(duration) }
        if let size = general?["File size"] { parts.append(size) }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// "H.265 (HEVC)" when the familiar name differs from MediaInfo's, else just the format.
    static func codecLabel(_ section: Section) -> String? {
        guard let format = section["Format"], let plain = plainCodec(section) else { return nil }
        return plain == format ? format : "\(plain) (\(format))"
    }

    static func plainCodec(_ s: Section) -> String? {
        guard let format = s["Format"] else { return nil }
        switch format.lowercased() {
        case "avc": return "H.264"
        case "hevc": return "H.265"
        case "vvc": return "H.266"
        case "mpeg-4 visual", "xvid", "divx", "dx50", "dx40": return "MPEG-4 Part 2"
        case "mpeg video": return (s["Format version"] ?? "").contains("1") ? "MPEG-1" : "MPEG-2"
        case "wmv1": return "WMV 7"
        case "wmv2": return "WMV 8"
        case "wmv3": return "WMV 9"
        case "ac-3": return "Dolby Digital"
        case "e-ac-3": return "Dolby Digital Plus"
        case "mlp fba": return "Dolby TrueHD"
        case "mpeg audio":
            let layer = s["Format profile"] ?? ""
            return layer.contains("3") ? "MP3" : layer.contains("2") ? "MP2" : "MPEG Audio"
        default:
            if format.hasPrefix("AAC") { return "AAC" }
            return format
        }
    }

    /// "2.0", "5.1", "7.1" from the channel count and whether the layout has an LFE.
    static func channels(_ s: Section) -> String? {
        guard let n = s["Channel(s)"].map(digits).flatMap(Int.init), n > 0 else { return nil }
        let hasLFE = (s["Channel layout"] ?? "").contains("LFE")
        return hasLFE ? "\(n - 1).1" : "\(n).0"
    }

    /// "29.970 (30000/1001) FPS" → "29.97", "25.000 FPS" → "25"
    static func fps(_ value: String) -> String? {
        guard let first = value.split(separator: " ").first, let n = Double(first) else { return nil }
        return n.formatted(.number.precision(.fractionLength(0...3)).locale(Locale(identifier: "en_US_POSIX")))
    }

    /// "1 920 pixels" → "1920"
    static func digits(_ value: String) -> String { value.filter(\.isNumber) }

    // MARK: Dates

    /// Every date the file has, most trustworthy first. Each keeps its own label.
    func dates(fileURL: URL?) -> [Field] {
        var out: [Field] = []
        let general = first("General")
        var recorded = general?["Recorded date"]
        // iPhone and other Apple-camera clips keep the capture time here instead.
        if recorded == nil { recorded = general?["com.apple.quicktime.creationdate"] }
        for (label, value) in [("Recorded", recorded), ("Encoded", general?["Encoded date"]), ("Tagged", general?["Tagged date"])] {
            if let value, !Self.isBlank(value) { out.append(Field(label: label, value: Self.readableDate(value))) }
        }
        // Any other dated tag (Mastered date, Written date…) keeps MediaInfo's label.
        for field in general?.fields ?? [] where field.label.hasSuffix(" date")
            && !["Recorded date", "Encoded date", "Tagged date"].contains(field.label) && !Self.isBlank(field.value) {
            out.append(Field(label: field.label, value: Self.readableDate(field.value)))
        }
        if let values = try? fileURL?.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]) {
            if let d = values.creationDate { out.append(Field(label: "File created", value: Self.format(d))) }
            if let d = values.contentModificationDate { out.append(Field(label: "File modified", value: Self.format(d))) }
        }
        return out
    }

    /// MediaInfo writes "2023-05-04 12:00:00 UTC" (or ISO 8601 for Apple tags); show it in local time.
    /// Anything it can't parse is shown exactly as MediaInfo wrote it.
    static func readableDate(_ value: String) -> String { parseDate(value).map(format) ?? value }

    /// A stored zero, not a real date: 1970-01-01 (Unix) or 1904-01-01 (QuickTime) at midnight UTC.
    static func isBlank(_ value: String) -> Bool {
        guard let d = parseDate(value) else { return false }
        return d.timeIntervalSince1970 == 0 || d.timeIntervalSince1970 == -2_082_844_800
    }

    static func parseDate(_ value: String) -> Date? {
        let posix = Locale(identifier: "en_US_POSIX")
        var trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("UTC ") { trimmed = String(trimmed.dropFirst(4)) + " UTC" }
        for pattern in ["yyyy-MM-dd HH:mm:ss.SSS 'UTC'", "yyyy-MM-dd HH:mm:ss 'UTC'", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ssXXXXX"] {
            let f = DateFormatter()
            f.locale = posix
            f.timeZone = TimeZone(identifier: "UTC")
            f.dateFormat = pattern
            if let d = f.date(from: trimmed) { return d }
        }
        return nil
    }

    static func format(_ date: Date) -> String { date.formatted(date: .abbreviated, time: .standard) }

    // MARK: MediaInfo

    private static let setup: Void = { _ = MediaInfoA_Option(nil, "CharSet", "UTF-8") }()

    private static func inform(path: String) -> String? {
        _ = setup
        guard let handle = MediaInfoA_New() else { return nil }
        defer { MediaInfoA_Delete(handle) }
        guard MediaInfoA_Open(handle, path) == 1, let text = MediaInfoA_Inform(handle, 0) else { return nil }
        return String(cString: text)
    }
}
