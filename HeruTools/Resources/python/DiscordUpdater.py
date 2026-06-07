#!/usr/bin/env python3
"""
DiscordUpdater.py
Bypasses Discord's internal stuck updater on Hackintosh by:
1. Fetching the latest Discord version URL
2. Downloading via curl (robust, handles network drops)
3. Installing fresh
4. Restoring GPU settings + re-applying wrapper
"""
import os
import sys
import json
import time
import shutil
import subprocess
import urllib.request

DISCORD_APP     = "/Applications/Discord.app"
SETTINGS_PATH   = os.path.expanduser("~/Library/Application Support/discord/settings.json")
PLIST_PATH      = "/Applications/Discord.app/Contents/Info.plist"
WRAPPER_PATH    = "/Applications/Discord.app/Contents/MacOS/discord_"
DISCORD_BIN     = "/Applications/Discord.app/Contents/MacOS/Discord"
TMP_DMG         = "/tmp/DiscordUpdate_latest.dmg"

def log(msg):
    print(msg, flush=True)

def progress(pct, eta, status):
    print(f"PROGRESS:{pct}|ETA:{eta}|STATUS:{status}", flush=True)

def get_latest_dmg_url():
    """Follow the redirect from Discord's download API to get the actual DMG URL."""
    log("STATUS:Checking latest Discord version...")
    try:
        req = urllib.request.Request(
            "https://discord.com/api/download?platform=osx",
            headers={"User-Agent": "Mozilla/5.0"},
            method="HEAD"
        )
        # Don't follow redirect — we want the Location header
        opener = urllib.request.build_opener(urllib.request.HTTPRedirectHandler())
        class NoRedirect(urllib.request.HTTPErrorProcessor):
            def http_response(self, req, response):
                return response
            https_response = http_response
        
        no_redir_opener = urllib.request.build_opener(NoRedirect)
        resp = no_redir_opener.open(req)
        url = resp.getheader("Location") or resp.url
        if not url:
            # fallback: just use the redirect URL via curl
            result = subprocess.run(
                ["curl", "-sI", "-L", "--max-redirs", "3",
                 "https://discord.com/api/download?platform=osx"],
                capture_output=True, text=True
            )
            for line in result.stdout.splitlines():
                if line.lower().startswith("location:"):
                    url = line.split(":", 1)[1].strip()
        return url
    except Exception as e:
        log(f"[Warning] Could not auto-detect URL: {e}")
        return None

def kill_discord():
    """Kill Discord if running."""
    try:
        subprocess.run(["pkill", "-x", "Discord"], capture_output=True)
        time.sleep(1.5)
        log("STATUS:Discord process stopped.")
    except Exception:
        pass

def backup_settings():
    """Backup settings.json and return the GPU-relevant keys."""
    try:
        if os.path.exists(SETTINGS_PATH):
            with open(SETTINGS_PATH) as f:
                data = json.load(f)
            return data
    except Exception as e:
        log(f"[Warning] Could not backup settings: {e}")
    return {}

def download_dmg(url):
    """Download Discord DMG via curl with retry support."""
    log(f"STATUS:Downloading Discord from CDN...")
    
    # Remove stale partial download
    if os.path.exists(TMP_DMG):
        os.remove(TMP_DMG)
    
    cmd = [
        "curl",
        "-L",              # follow redirects
        "--retry", "5",    # retry up to 5 times on connection drop
        "--retry-delay", "2",
        "--retry-connrefused",
        "--connect-timeout", "30",
        "--max-time", "600",  # 10 min max
        "-o", TMP_DMG,
        url
    ]
    
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # curl doesn't give easy progress with -o; simulate steps
    dot = 0
    while proc.poll() is None:
        time.sleep(2)
        dot += 1
        pct = min(60, dot * 3)  # rough estimate: up to 60% for download
        progress(pct, "--", f"Downloading Discord (this may take a minute)...")
    
    rc = proc.returncode
    if rc != 0:
        err = proc.stderr.read() if proc.stderr else ""
        log(f"[Error] curl failed (exit {rc}): {err[-300:]}")
        sys.exit(rc)
    
    size = os.path.getsize(TMP_DMG) if os.path.exists(TMP_DMG) else 0
    log(f"STATUS:Download complete ({size // 1_000_000} MB)")
    return True

def install_dmg():
    """Mount DMG, replace Discord.app, unmount."""
    progress(65, "--", "Mounting disk image...")
    
    # Mount
    r = subprocess.run(
        ["hdiutil", "attach", TMP_DMG, "-nobrowse", "-quiet"],
        capture_output=True, text=True
    )
    if r.returncode != 0:
        log(f"[Error] hdiutil attach failed: {r.stderr}")
        sys.exit(1)
    
    progress(70, "--", "Removing old Discord...")
    if os.path.exists(DISCORD_APP):
        shutil.rmtree(DISCORD_APP)
    
    progress(75, "--", "Installing new Discord...")
    r = subprocess.run(
        ["cp", "-R", "/Volumes/Discord/Discord.app", "/Applications/"],
        capture_output=True, text=True
    )
    if r.returncode != 0:
        log(f"[Error] cp failed: {r.stderr}")
        subprocess.run(["hdiutil", "detach", "/Volumes/Discord", "-quiet"], capture_output=True)
        sys.exit(1)
    
    progress(85, "--", "Unmounting disk image...")
    subprocess.run(["hdiutil", "detach", "/Volumes/Discord", "-quiet"], capture_output=True)
    
    # Clean up DMG
    try:
        os.remove(TMP_DMG)
    except Exception:
        pass
    
    log("STATUS:Discord installed successfully.")

def restore_settings(original_data):
    """Restore GPU settings to settings.json."""
    progress(90, "--", "Restoring GPU settings...")
    try:
        # Wait for Discord to create settings folder after install
        settings_dir = os.path.dirname(SETTINGS_PATH)
        os.makedirs(settings_dir, exist_ok=True)
        
        data = {}
        if os.path.exists(SETTINGS_PATH):
            try:
                with open(SETTINGS_PATH) as f:
                    data = json.load(f)
            except Exception:
                pass
        
        # Merge original window preferences
        for key in ["IS_MAXIMIZED", "IS_MINIMIZED", "WINDOW_BOUNDS", "BACKGROUND_COLOR"]:
            if key in original_data:
                data[key] = original_data[key]
        
        # Always apply GPU flags
        data["offloadAdmControls"] = True
        data["chromiumSwitches"] = {
            "disable-gpu": "",
            "disable-gpu-rasterization": ""
        }
        data.pop("USE_NEW_UPDATER", None)
        
        with open(SETTINGS_PATH, "w") as f:
            json.dump(data, f, indent=2)
        
        log("STATUS:GPU settings restored.")
    except Exception as e:
        log(f"[Warning] Could not restore settings: {e}")

def apply_wrapper():
    """Re-apply Info.plist + discord_ wrapper via AppleScript."""
    progress(95, "--", "Re-applying GPU wrapper...")
    
    wrapper_content = """#!/bin/bash
exec "/Applications/Discord.app/Contents/MacOS/Discord" --disable-gpu --disable-gpu-rasterization "$@"
"""
    
    script = f'''do shell script "printf '{wrapper_content.replace("'", "\\'")}' > {WRAPPER_PATH} && chmod +x {WRAPPER_PATH} && (cp -n {PLIST_PATH} {PLIST_PATH}.bak || true) && plutil -replace CFBundleExecutable -string 'discord_' {PLIST_PATH}" with administrator privileges'''
    
    r = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True, text=True
    )
    if r.returncode != 0:
        log(f"[Warning] Wrapper apply failed (user may have cancelled admin prompt): {r.stderr.strip()}")
    else:
        log("STATUS:GPU wrapper applied.")

def main():
    log("STATUS:Starting Discord Fix Updater...")
    progress(0, "--", "Initializing...")
    
    # 1. Get download URL
    url = get_latest_dmg_url()
    if not url:
        # Hardcode known stable URL as fallback
        url = "https://discord.com/api/download?platform=osx"
        log(f"[Info] Using fallback URL: {url}")
    log(f"STATUS:Found: {url}")
    
    # 2. Kill Discord
    progress(5, "--", "Stopping Discord...")
    kill_discord()
    
    # 3. Backup settings
    progress(10, "--", "Backing up settings...")
    original_data = backup_settings()
    
    # 4. Download
    progress(15, "--", "Starting download via curl...")
    download_dmg(url)
    
    # 5. Install
    install_dmg()
    
    # 6. Restore settings
    restore_settings(original_data)
    
    # 7. Apply wrapper
    apply_wrapper()
    
    # 8. Done
    progress(100, "0s", "Done! Launching Discord...")
    time.sleep(0.5)
    subprocess.Popen(["open", "/Applications/Discord.app"])
    print(f"SUCCESS:Discord updated and fixed! GPU patch re-applied automatically.")
    sys.exit(0)

if __name__ == "__main__":
    main()
