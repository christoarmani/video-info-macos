# Video Info — plan

A small native Mac app that shows PotPlayer-style file information for any video file.

## Goal
Right-click a video in Finder, choose **Video Info**, and get a window that shows everything PotPlayer's "File information" panel shows:
- **General:** container, file size, duration, overall bit rate, frame rate, encoded date, writing app, title and other tags
- **Video #n:** the real codec (H.264, H.265, AV1, VC-1…), profile, resolution, aspect ratio, frame rate, bit depth, color/HDR info, writing library, encoding settings
- **Audio #1, #2, #3…:** every audio track, each with codec, channels, layout, sample rate, bit rate, language, default flag
- **Text #n:** subtitle tracks
- **Menu:** chapters, if there are any
- **Copy to Clipboard:** copies the same plain text PotPlayer copies

## Must have / nice to have
| | Feature |
|---|---|
| Must | Right-click → Video Info in Finder |
| Must | All fields, every track, like PotPlayer |
| Must | Codec shown clearly, e.g. "H.265 (HEVC)", not just "MP4" |
| Must | Original encode date |
| Nice | Spacebar Quick Look view (see risk below) |

## How it's built (designer version)
1. **Info engine: MediaInfo.** PotPlayer's panel *is* MediaInfo, so the wording and fields will match. It's a free library we bundle inside the app, and its license allows that. It reads MKV, MP4, MOV, AVI, WMV, TS, WebM and more.
2. **Plain codec names.** A small lookup table turns MediaInfo's names into familiar ones: AVC → H.264, HEVC → H.265, MPEG-4 Visual → MPEG-4 Part 2 (DivX/Xvid), and so on.
3. **Encode date.** Show every date the file has, in this order of trust:
   - *Recorded date* (from cameras and phones)
   - *Encoded date* (from the container, as in your WMV/MP4 screenshots)
   - *Tagged date*
   - The file's own Created/Modified dates from Finder, as a fallback

   Each one keeps its label, so you always know which date is which.
4. **Window.** Native SwiftUI using stock components only:
   - Summary line at the top: `H.264 · 1920×1080 · 29.97 fps · AAC 2.0 · 20 min 47 s · 2.00 GiB`
   - Collapsible sections (General / Video #1 / Audio #1 / Audio #2 …) with labels on the left and values on the right, like Finder's Get Info
   - Text can be selected, and the window can be resized
   - Copy to Clipboard and Close buttons at the bottom
5. **Right-click menu.** A **Finder extension** adds "Video Info" to the main right-click menu, shown only for video files. Selecting several files opens one window each.
   - One-time step: turn it on in System Settings → General → Login Items & Extensions.
   - The Quick Actions version comes for free as a backup.
6. **Quick Look (optional).** Press Space on a video to see the info panel.
7. **Signing and install.** Sign with team 4Z4N8C379F and keep a single copy installed in /Applications.

## Privacy
Everything runs on your Mac. The app has no network access, so nothing can leak, including your IP. The full folder path is left out of the copied text by default.

## Risks
- **Quick Look on videos:** macOS already has its own video player in Quick Look, and it may not let a third-party preview replace it. We'd test this early. If macOS doesn't allow it, the fallback is right-click only.
- **Finder extension hiccups:** Finder sometimes needs a relaunch before a newly installed extension shows up. This is a known quirk, and a relaunch fixes it.

## Build order
1. A bare app that opens a file and prints the MediaInfo text, to prove the engine works on your MKV/MP4/AVI/WMV files
2. The info window: sections, summary line and Copy button
3. The right-click Finder extension
4. Codec name table and the encode-date rules
5. A Quick Look test, kept only if macOS allows it
6. Signing and install

**Effort:** small. Roughly 2–3 sessions, and most of the time goes into polishing the window.

## Decisions
- App name: **Video Info** (confirmed 2026-11-22).
- All sections start open (confirmed 2026-11-22).

