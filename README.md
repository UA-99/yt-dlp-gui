# YT Downloader GUI

A lightweight cross-platform GUI for [yt-dlp](https://github.com/yt-dlp/yt-dlp), built with Flutter.  
Paste a YouTube URL, choose a format and folder, then download with a single click.

---

## Features

- Supports Windows and Linux
- Audio presets: MP3 and AAC
- Video presets: MP4 and MKV
- Output folder selection
- Terminal-style log with auto-scroll
- Progress reporting when yt-dlp provides percentage updates
- Bundled yt-dlp automatically checks for updates
- Portable and does not require installation

---

## Usage

1. Launch the application
2. Paste a YouTube link into the input field
3. Select an output folder
4. Choose an audio or video preset
5. Click "Download"

A detailed log including progress details will appear throughout the download process.

---

## Running From Source

Requirements:
- Flutter 3.9 or newer
- Windows 10/11 or Linux with GTK support

### yt-dlp
Binaries are included for convenience and are licensed separately by their authors.  
See `assets/yt-dlp/LICENSE.yt-dlp.txt` and https://github.com/yt-dlp/yt-dlp

