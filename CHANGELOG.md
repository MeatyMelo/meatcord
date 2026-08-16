# Changelog

## v1.3.0 — Compact UI, drafts on disk, microphone picker

Builds on 1.2. Everything below is new since that release; membership was
checked against the 1.2 download rather than assumed.

### Changed

- **Compact shell: icon rail instead of a fixed sidebar.** The 300px panel column
  is now a 52px icon rail; clicking an icon floats that panel over the preview and
  clicking it again closes it, so the stage keeps the full width whenever no panel
  is open. Escape closes it too. The PiP icon only appears in PiP mode. Transport
  and timeline share one footer row rather than stacking. Panels themselves are
  unchanged — same markup, same ids, same handlers — only where they live moved.

### Added

- **Drafts.** A session — takes, trims, order, background and settings — is saved
  automatically and can be reopened later from the Drafts panel. Stored in
  IndexedDB rather than localStorage, because a single 4K take is tens of
  megabytes and localStorage tops out around 5MB of strings.
  Recordings are written **once**, when the take is made, and never rewritten;
  only metadata (trims, speed, order, settings) is re-saved as you work, so
  autosave stays a few KB regardless of how much footage the draft holds. A split
  produces two clips sharing one recording, and they share one stored blob rather
  than duplicating it. Undo deletes the take's recording from storage too, so a
  killed take leaves no trace there either. `navigator.storage.persist()` is
  requested so drafts aren't silently evicted under storage pressure.
  Opening the app does **not** auto-load the last draft — silently restoring
  twenty old takes into a session you opened to shoot something new is worse than
  one explicit click — but it does tell you the draft is there.
  **Project folder (File System Access API).** Link a folder once and each draft
  becomes a real directory you can open in Explorer:
  ```
  <projects>/Ramen- Episode 3/
      project.json      settings, trims, clip order
      take-01.mp4       the recordings themselves
      take-02.mp4
      background.png
  ```
  Take files are named after the *recording*, not its timeline position, so
  reordering clips rewrites a few KB of JSON instead of renaming gigabytes of
  video. Folder names are sanitised for the filesystem (a title like
  `Ramen: Episode 3` becomes `Ramen- Episode 3`) while `project.json` keeps the
  real title. The name is fixed when the folder is created — the API has no
  rename, and copying gigabytes to follow a title change is worse than a folder
  named the way it was born.
  Browser permission for a folder usually lapses when the browser restarts, and
  re-requesting it needs a click, so the panel offers **Reconnect folder** rather
  than failing quietly at the next save. Drafts stored in the browser and on disk
  are listed together and labelled. A recording deleted outside the app loads the
  rest of the draft and reports how many are missing, instead of failing whole.

- **Drop media straight onto the preview** in Split and PiP. The rail puts the
  Import panel a click away, and swapping backgrounds is the step the take loop
  repeats most, so the drop target is the thing already on screen. Dropping while
  in Normal mode switches to Split, since a background has nowhere to go otherwise.
  Non-media files are rejected with a message instead of being silently ignored,
  and a file dropped outside the preview no longer navigates the page away.

- **Fit / Fill framing for imported media** (Split and PiP). *Fill* is the previous
  behaviour: cover-crop the background to the region, trimming whatever overflows.
  *Fit + blur* shows the whole frame uncropped and fills the leftover space with a
  blurred, dimmed copy of the same media, so a background whose aspect doesn't
  match the output reads as one continuous shot instead of black bars. Panning
  still works in Fit mode — it slides the picture through the letterbox slack.
  The blur is produced by downscaling to a ~96px canvas and letting the upscale do
  the smoothing; a `ctx.filter` blur works in destination space and would cost real
  milliseconds per frame at full resolution. Measured overhead: **0.034 ms/frame**
  of a 33.3 ms budget.

- **Microphone picker.** Choose the audio input device, in the Audio panel. Both
  pickers fall back to the system default if a saved device is gone (unplugged, or
  an OBS Virtual Camera that isn't running) rather than silently selecting some
  other device. Selections persist. Changing either re-opens *both* tracks in one
  `getUserMedia` call, which is what keeps Normal mode's audio and video on a
  single capture clock.

### Fixed

- **The project folder could only ever be chosen once.** "Change folder" routed to
  the reconnect path, which re-requests permission for the *stored* handle and
  never opens the picker. Reconnect now fires only for a handle whose permission
  lapsed; choosing and changing both open the picker. Switching folders with a
  project open closes that project where it already is rather than carrying its
  metadata into a root where its take files don't exist — and re-picking the same
  folder is detected via `isSameEntry()`, so it doesn't close anything.

- **"Use Chrome/Edge/Brave" shown to people already using Brave.** Brave ships the
  File System Access API with the pickers removed while keeping
  `FileSystemHandle` and friends, so interface-based feature detection reports
  support and then fails at the picker. Detection now tests `showDirectoryPicker`
  specifically, and Brave users are pointed at
  `brave://flags/#file-system-access-api` instead of a browser they're already on.

- **Split/PiP takes recorded silent mic audio after any settings change.**
  `reconnectMic()` bailed out early if a source node already existed, but
  `startCamera()` replaces the whole stream whenever quality, frame rate or a
  device changes. The WebAudio graph therefore stayed bolted to the *stopped*
  stream, feeding silence into the recording mix from then on. Normal mode was
  unaffected (it takes the camera's audio track directly). The graph now rebuilds
  whenever the stream identity changes, and only then.

## v1.2.0 — GPU recording, OBS camera bridge, export frame integrity

All performance figures below were measured on a real machine (RTX 3060, Logitech
BRIO, Brave) rather than estimated.

### Added

- **GPU-encoded recording (NVENC / QuickSync / AMF).** Recording now hands frames
  to the hardware H.264 encoder via WebCodecs and writes MP4 directly, instead of
  MediaRecorder's software VP8. Applies to all three modes. Falls back to the old
  MediaRecorder path automatically when no hardware encoder is offered, so it can
  never cost a take.

- **OBS camera bridge.** Connect to OBS over obs-websocket v5 (spoken directly —
  no vendored client library) and switch OBS scenes from the sidebar. OBS supplies
  the *camera image* through its Virtual Camera; recording, backgrounds, Split/PiP
  and undo all stay in Meatcord. Server URL and scene mapping persist; the password
  is deliberately never stored.

- **Video source picker.** Choose which camera to use, including "OBS Virtual
  Camera". The list tracks devices appearing and disappearing.

- **Per-stage frame profiler.** Each frame is timed by stage (background draw,
  camera draw, encoder submit). The dropped-frames warning now names the stage
  that is over budget instead of offering generic advice.

- **Capture health per take.** Canvas-mode clips record the frame rate they
  actually composited at. A take that lands below 85% of target says so
  immediately — while it can still be re-shot — and the timeline tooltip shows it.

- **`start.bat`** — one-click launcher: finds Python, starts the server, opens the
  browser, reuses an already-running server instead of starting a second.

- **`serve.py`** — static server with caching disabled. Plain
  `python -m http.server` lets the browser keep running an older `meatcord.html`
  after an edit, with no visible sign it is doing so.

### Fixed

- **Normal mode dropped a third of every 4K take.** It never got the GPU path and
  was still software-encoding the raw camera track. Now pulls frames off the
  camera track via `MediaStreamTrackProcessor` straight into the hardware encoder,
  which preserves the reason Normal mode exists — video and audio still share one
  capture clock. Measured: **20.3 fps → 29.6 fps at 4K**, zero frames skipped.

- **Choppy exports at 1440p+.** Export played clips at 2x speed for any sub-60fps
  output, reasoning only about monitor refresh rate and ignoring whether frames
  could be *decoded* that fast. A 1440p/4K source can't be, so the decoder fell
  behind, frames were never presented, and the encoder was fed duplicates of the
  last drawn frame. Playback rate is now resolution-aware and backs off further
  using the pipeline's own dropped-frame counter. Simulated across decoder speeds:
  1440p went from 67% duplicated frames to 0%; 4K from 67% to 4%.

- **Exports froze on the last frame of a clip.** When a take's video track ends
  before its audio track (a stalled canvas capture), the exporter padded the
  remainder by repeating the final frame, silently. Padding is still correct —
  truncating would cut the audio — but it is now measured and reported, naming the
  clip and the cause.

- **Top-bar Quality and capture frame rate had no effect on exports.** Export
  resolution/fps came from a separate setting that stayed where it was last left,
  so raising Quality to 4K while Export sat at 1080p produced a 1080p file. Export
  now follows capture until an Export chip is deliberately chosen.

- **H.264 level chosen from resolution alone.** Levels cap *bitrate* too — High@4.0
  tops out near 25 Mbps while auto capture at 1080p asks for 32 — so the encoder
  was entitled to refuse the config and silently demote the take to software.
  Now picks by whichever constraint binds, with higher levels as fallbacks.

- **Switching modes silently disabled GPU encoding.** Mode is part of the encoder's
  cache key — Normal encodes camera frames, Split/PiP encode the canvas, which are
  different encoder configs — but `setMode()` never re-probed. Switching Normal →
  Split invalidated the key, the app read that as "no hardware available", and the
  take really did fall back to software VP8. Changing resolution afterwards masked
  it, because that path did re-probe. A stale key is now treated as *"not answered
  yet"* rather than *"unavailable"*: a probe starts automatically and the UI stays
  quiet until it lands, so any future input to that key self-heals without needing
  a new call site.

- **False "software encoder" warning.** The hardware probe is async and cleared its
  result before awaiting, so every settings change briefly reported no hardware.
  The warning pill also kept its previous text while hidden, which read as a live
  warning; it is now cleared whenever it is hidden.

- **PiP letterboxed the camera** instead of cover-cropping it: a leftover duplicate
  function definition was shadowing the real one and dropping `fit:'cover'`.

- **Filmstrip thumbnails interleaved** frames from two files when a second video
  was imported while the first strip was still building.

- **Recorded blobs were hardcoded `video/webm`** regardless of what was actually
  recorded, mislabelling every MP4 the new path produces.

### Performance

- **Live preview canvas is sized to what's on screen** (CSS box × devicePixelRatio,
  capped) rather than a fixed 720px backing store — roughly 5–8x fewer composited
  pixels per frame on a typical window, with no loss of sharpness.

- **Redundant frames are no longer redrawn.** `requestVideoFrameCallback` reports
  when the camera actually delivers something new, instead of redrawing the same
  frame at display refresh rate.

- **The PiP drop shadow is cached.** It was a gaussian blur recomputed 30x/second
  despite only changing when the box is resized.

- **Waveforms are cached by recording, not by clip**, so splitting a clip no longer
  decodes the same take's audio twice.
- Per-frame `getElementById` calls removed from the render and editor loops; trim
  handles no longer keep a window-level `pointermove` listener alive for the whole
  session; recording buffers are released as soon as a take is packaged.

### Quality

- `imageSmoothingQuality: 'high'` on every canvas, reapplied after each resize
  (resizing a canvas silently resets it). Measured at 0.007ms per full-resolution
  draw on a GPU-accelerated canvas — free.

- Export encoder explicitly requests `latencyMode: 'quality'` and
  `bitrateMode: 'variable'` so a hardware path can't quietly pick faster defaults.

### Notes

- Requires a **secure context** — serve over `http://localhost` (use `start.bat`).
  Browsers block camera access on `file://` URLs.
- Recording performance depends on browser **hardware acceleration being enabled**.
  With it off, everything (video decode, compositing, encoding) runs on the CPU and
  no GPU encoder is offered at any resolution.
- 60 fps capture above 1080p depends on the camera. A Logitech BRIO delivers
  720p60 and 1080p60 but refuses 1440p60 and 4K60.
