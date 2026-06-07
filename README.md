# HeruTools 🛠️

A lightweight macOS menu-bar utility written in SwiftUI that packages several essential system tweaks, cleaning tools, and media processing wrappers. Built as a native AppKit popover, it runs background processes via python wrappers to automate tasks that usually require tedious terminal commands.

Developed specifically for power users and Hackintosh (particularly AMD-based macOS) systems.

---

## Features

### 1. System Cleaner & RAM Optimizer
*   **Disk Cleanup**: Scans and removes User Caches, User Logs, system logs, Xcode simulator leftovers (unavailable devices), and empties the Trash.
*   **Memory Purge**: Elevated memory reclaim using the macOS native `purge` command, supported by a real-time monitor displaying memory categories (Wired, Active, Compressed, Inactive) and Swap usage.
*   **Large Files Scanner**: Quickly hunts down files larger than 200MB in your home folder and `/Applications` to free up space.
*   **DNS Flusher**: Clears and flushes the system DNS cache (`dscacheutil -flushcache; killall -HUP mDNSResponder`) in one click.

### 2. Video Utilities (FFmpeg & RIFE AI)
*   **AI Frame Interpolation (RIFE)**: Native integration of RIFE AI models (`rife-v2.4`, `rife-v3.1`, `rife-v4.6`, `rife-v4.15-lite`, and `rife-anime`) to boost video frame rates (2x, 4x).
    *   *Smart Pipeline*: High-resolution inputs (>1080p) are auto-routed to a memory-safe scale filter.
    *   *Pro Res & Lossless Support*: Professional codecs (QTRLE, ProRes, FFV1, etc.) are processed using a two-pass decode pipeline over stdout/stdin pipes to bypass massive temporary disk writes.
*   **FFmpeg Video Compressor**: Standard compression presets (Small, Medium, High) with options to remove audio, output to H.264/HEVC, or target a specific file limit in Megabytes (e.g., matching the 25MB Discord limit by dynamically calculating bitrate relative to video duration).

### 3. System Fixes & Integration
*   **Discord Hackintosh Fix**: Fixes hardware acceleration rendering issues on AMD Hackintoshes. It writes a custom launcher script wrapping the main binary with GPU disable switches and updates `Info.plist` dynamically.
*   **Discord Stuck-Update Bypass**: Bypasses the infamous infinite update loop on Hackintoshes by downloading the latest official DMG via `curl` and running a silent background mount and installation.
*   **Spicetify CLI Toolkit**: Dashboard to install, update, backup, and restore Spotify modifications using Spicetify.

---

## Tech Stack
*   **Frontend**: SwiftUI & AppKit (macOS native popover layout, login items management via `ServiceManagement`).
*   **Backend & Process Management**: Swift `Process` executing asynchronous Python 3 utility wrappers in the background.
*   **Helper Scripts**: Python scripts communicating progress, ETA, and processing status back to Swift via standard output.
*   **Core Libraries**: FFmpeg, FFprobe, RIFE, AppleScript (for privilege elevation).

---

## Installation & Setup

### Prerequisites
1.  macOS 13.0 or later.
2.  Python 3 installed.
3.  FFmpeg installed (used for compression and video filtering):
    ```bash
    brew install ffmpeg
    ```

### Installation
1.  Download the latest `HeruTools.dmg` from the GitHub releases page.
2.  Open the DMG and drag **HeruTools** into your `/Applications` folder.
3.  Launch the app. It will run in your status menu bar.
*(Note: As the app is ad-hoc signed, you might need to right-click and select **Open** in Finder the first time, or clear Gatekeeper flags via `xattr -d com.apple.quarantine /Applications/HeruTools.app` in Terminal).*

---

## Building from Source

To compile the project and build the DMG installer manually from Terminal:
```bash
# Clone the repository
git clone https://github.com/your-username/HeruTools.git
cd HeruTools

# Create app directory layout
mkdir -p build/HeruTools.app/Contents/MacOS build/HeruTools.app/Contents/Resources

# Compile Swift sources
SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
find HeruTools -name "*.swift" | xargs swiftc -sdk "$SDK_PATH" -parse-as-library -target x86_64-apple-macosx13.0 -O -module-name HeruTools -o build/HeruTools.app/Contents/MacOS/HeruTools

# Copy Info.plist and resources
cp HeruTools/Info.plist build/HeruTools.app/Contents/Info.plist
cp -R HeruTools/Resources/python build/HeruTools.app/Contents/Resources/
cp -R HeruTools/Resources/bin build/HeruTools.app/Contents/Resources/

# Clean extended attributes and sign
xattr -cr build/HeruTools.app
codesign --force --deep --sign - build/HeruTools.app

# Package into DMG
hdiutil create -volname "HeruTools" -srcfolder build/HeruTools.app -ov -format UDZO build/HeruTools.dmg
```
Alternatively, you can open `HeruTools.xcodeproj` in Xcode to inspect the structure.

---

## License

This project is licensed under the **projectheru** license.
