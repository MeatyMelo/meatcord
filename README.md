# Meatcord

I make content on tiktok... The issue is that their special rewards program (where the big bucks are made) is really anal about their rules.

This is why I made this app.

It's essentially a replica of tiktoks native recorder on mobile devices but ran locally on your PC

It comes with a couple of QOL features that you don't get in tiktoks native recorder that make filming and editing that much quicker

I have no prior coding experienece so this entire project is vibe coded (I'm sure the code is a mess) but feel free to change up the code and or add more features.

---

## Running it

Grab `meatcord.html`, `start.bat` and `serve.py` from the [latest release](https://github.com/MeatyMelo/meatcord/releases/latest), put them in the same folder, and double-click **`start.bat`**. It starts a tiny local server and opens the app.

**Don't just double-click `meatcord.html`.** Browsers block camera access on `file://` URLs, so the app can't see your webcam. `start.bat` exists purely to serve it over `http://localhost`, which browsers do trust. Close the server window when you're done.

The app itself is one self-contained HTML file with no internet connection and no dependencies — nothing is uploaded anywhere, and it works offline.

## How it works

The unit of work is a **take**, not a video. Record one, judge it immediately, and either keep it or undo it — an undone take is gone completely, no file left behind. Swap the background, go again. By the time you stop recording the video is basically assembled.

### Recording

- **Normal** — just the camera. **Split** — a background image/video above, camera below. **PiP** — camera in a corner over the background.
- Drop an image or video **straight onto the preview** to use it as the background.
- **Fit + blur** framing fills the leftover space with a blurred copy of the background instead of black bars.
- Frame 9:16, 16:9, 1:1 or 4:3 · quality 720p to 4K · 30 or 60 fps.
- The imported video only plays while you're recording, and **undo rewinds it** to where that take began, so a retake starts from the same spot.
- Camera and microphone pickers, mirror, zoom, pan, and filters.

### Editing

- Trim against a **peak audio waveform**, so you can cut exactly where your voice starts and stops.
- Split a clip, set per-clip speed, reorder takes — each one carries its trim and background with it.

### Export

- Real **MP4** (H.264 + AAC) written by a proper muxer, so it drops straight into TikTok, Instagram or an editor without converting.
- Export the whole timeline stitched, or every clip as its own numbered file.

### Drafts

Sessions save automatically and reopen later. Link a **project folder** and each draft becomes a real directory you can open in Explorer:

```
Projects/My video/
    project.json      settings, trims, clip order
    take-01.mp4       the recordings themselves
    take-02.mp4
    background.png
```

Without a linked folder drafts still work, they just live inside the browser.

### OBS

Optional. Start OBS's **Virtual Camera** and pick it as the video source, and OBS's filters, colour and multi-source scenes arrive as an ordinary webcam. Connect over obs-websocket and you can switch OBS scenes from inside Meatcord. Recording, backgrounds and undo all stay in Meatcord.

## Requirements

- **Chrome, Edge or Brave.** Firefox and Safari are missing the encoder APIs this relies on.
- **Hardware acceleration must be on** — `brave://settings/system` or `chrome://settings/system`. With it off, video decoding, compositing and encoding all fall to the CPU, there's no GPU encoder at any resolution, and takes drop frames. This is the single biggest thing affecting recording quality.
- Recording quality depends on your camera. Asking for 4K from a 1080p webcam just upscales it — the app warns you when that happens.
- **Brave only:** project folders need `brave://flags/#file-system-access-api` enabled, since Brave hides the folder picker by default. Everything else works without it.

## Notes

Clips are an intermediate — they get re-encoded on export, so detail lost while recording can't be recovered. That's why the capture bitrate defaults high.

See [CHANGELOG.md](CHANGELOG.md) for what's changed between releases.

---

Here are my socials and my video showcasing it:

- https://linktr.ee/Meatymelo
- https://www.tiktok.com/@meatymelo/video/7657354279371541791
