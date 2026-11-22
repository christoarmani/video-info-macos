import Testing

@Suite struct MediaReportTests {
    let sample = """
    General
    Complete name                            : /Users/someone/Movies/Trip/clip.mkv
    Format                                   : Matroska
    File size                                : 2.00 GiB
    Duration                                 : 20 min 47 s
    Encoded date                             : 2023-05-04 12:00:00 UTC

    Video
    Format                                   : HEVC
    Width                                    : 1 920 pixels
    Height                                   : 1 080 pixels
    Frame rate                               : 29.970 (30000/1001) FPS

    Audio #1
    Format                                   : AAC LC
    Channel(s)                               : 2 channels
    Channel layout                           : L R

    Audio #2
    Format                                   : AC-3
    Channel(s)                               : 6 channels
    Channel layout                           : L R C LFE Ls Rs
    """

    @Test func parsesAndSummarises() {
        let r = MediaReport(text: sample)
        #expect(r.sections.map(\.title) == ["General", "Video", "Audio #1", "Audio #2"])
        #expect(r.summary == "H.265 · 1920×1080 · 29.97 fps · AAC 2.0 · 20 min 47 s · 2.00 GiB")
        #expect(MediaReport.codecLabel(r.sections[1]) == "H.265 (HEVC)")
        #expect(MediaReport.channels(r.sections[3]) == "5.1")
        #expect(MediaReport.plainCodec(r.sections[3]) == "Dolby Digital")
    }

    @Test func leavesOutFolderPath() {
        let r = MediaReport(text: sample)
        #expect(!r.text.contains("/Users/"))
        #expect(r.text.contains(": clip.mkv"))
        #expect(r.sections[0]["Complete name"] == "clip.mkv")
    }

    @Test func labelsDates() {
        let r = MediaReport(text: sample)
        let dates = r.dates(fileURL: nil)
        #expect(dates.map(\.label) == ["Encoded"])
        #expect(dates[0].value != "2023-05-04 12:00:00 UTC") // parsed into a readable local date
    }

    @Test func hidesBlankDates() {
        let r = MediaReport(text: "General\nEncoded date : 1970-01-01 00:00:00 UTC\nTagged date : 1904-01-01 00:00:00 UTC\nRecorded date : 2020-02-03 04:05:06 UTC")
        #expect(r.dates(fileURL: nil).map(\.label) == ["Recorded"])
    }
}
