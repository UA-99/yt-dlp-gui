# A Simple YouTube Downloader GUI

![UI screenshot](https://raw.githubusercontent.com/UA-99/yt-dlp-gui/main/UI.png)

A lightweight cross-platform GUI for [yt-dlp](https://github.com/yt-dlp/yt-dlp), built with Flutter.  
Paste a YouTube URL, choose a format and folder, then download with a single click.

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

I reccomend running from source as I cannot afford a CA signature, so using my premade binaries will trigger Windows Defender warnings. If you don't care, just bypass them.

Requirements:
- Flutter 3.9 or newer
- Windows 10/11 or Linux with GTK support

### yt-dlp
Binaries are included for convenience and are licensed separately by their authors.  
See `assets/yt-dlp/LICENSE.yt-dlp.txt` and https://github.com/yt-dlp/yt-dlp

