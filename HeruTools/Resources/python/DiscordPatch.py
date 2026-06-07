#!/usr/bin/env python3
import os
import json
import shutil
import sys
import plistlib

SETTINGS_DIR = os.path.expanduser('~/Library/Application Support/discord')
SETTINGS_FILE = os.path.join(SETTINGS_DIR, 'settings.json')
SETTINGS_BACKUP = os.path.join(SETTINGS_DIR, 'settings.json.bak')

INFO_PLIST_PATH = '/Applications/Discord.app/Contents/Info.plist'
INFO_PLIST_BACKUP = '/Applications/Discord.app/Contents/Info.plist.bak'

def check_settings_patched():
    if not os.path.exists(SETTINGS_FILE):
        return "not_found"
    
    try:
        with open(SETTINGS_FILE, 'r') as f:
            data = json.load(f)
        
        switches = data.get("chromiumSwitches", {})
        if (switches.get("disable-gpu") == "" and 
            switches.get("disable-gpu-rasterization") == "" and 
            data.get("offloadAdmControls") is True):
            return "patched"
        return "unpatched"
    except Exception as e:
        print(f"Error checking settings: {e}", file=sys.stderr)
        return "corrupted"

def patch_settings():
    os.makedirs(SETTINGS_DIR, exist_ok=True)
    
    # Backup original settings if it exists and backup doesn't already exist
    if os.path.exists(SETTINGS_FILE):
        if not os.path.exists(SETTINGS_BACKUP):
            try:
                shutil.copy2(SETTINGS_FILE, SETTINGS_BACKUP)
                print("Created backup of settings.json")
            except Exception as e:
                print(f"Failed to create settings backup: {e}", file=sys.stderr)
    
    # Target patched configuration
    patched_data = {
        "IS_MAXIMIZED": False,
        "IS_MINIMIZED": False,
        "BACKGROUND_COLOR": "#000000",
        "offloadAdmControls": True,
        "USE_NEW_UPDATER": False,
        "chromiumSwitches": {
            "disable-gpu": "",
            "disable-gpu-rasterization": ""
        },
        "WINDOW_BOUNDS": {
            "x": 0,
            "y": 63,
            "width": 940,
            "height": 919
        }
    }
    
    try:
        # Merge if existing settings exist to preserve custom bounds
        if os.path.exists(SETTINGS_FILE):
            try:
                with open(SETTINGS_FILE, 'r') as f:
                    curr = json.load(f)
                if isinstance(curr, dict):
                    # Preserve window bounds and maximized states if available
                    for k in ["WINDOW_BOUNDS", "IS_MAXIMIZED", "IS_MINIMIZED"]:
                        if k in curr:
                            patched_data[k] = curr[k]
            except Exception:
                pass
                
        with open(SETTINGS_FILE, 'w') as f:
            json.dump(patched_data, f, indent=2)
        print("Successfully patched settings.json")
        return True
    except Exception as e:
        print(f"Error patching settings.json: {e}", file=sys.stderr)
        return False

def restore_settings():
    if not os.path.exists(SETTINGS_BACKUP):
        print("No backup settings.json.bak found.", file=sys.stderr)
        return False
    try:
        shutil.copy2(SETTINGS_BACKUP, SETTINGS_FILE)
        print("Restored settings.json from backup")
        return True
    except Exception as e:
        print(f"Error restoring settings.json: {e}", file=sys.stderr)
        return False

def check_plist_patched():
    if not os.path.exists(INFO_PLIST_PATH):
        return "not_found"
    try:
        with open(INFO_PLIST_PATH, 'rb') as f:
            plist = plistlib.load(f)
        
        exec_name = plist.get('CFBundleExecutable')
        if exec_name == 'discord_':
            return "patched"
        elif exec_name == 'Discord':
            return "unpatched"
        return "unknown"
    except Exception as e:
        print(f"Error reading Info.plist: {e}", file=sys.stderr)
        return "permissions_needed"

def patch_plist():
    # To run this, usually root access is required.
    # Swift will call this python script with escalated privileges or run standard operations.
    if not os.path.exists(INFO_PLIST_PATH):
        print("Discord Info.plist not found.", file=sys.stderr)
        return False
        
    try:
        # Create backup if not exists
        if not os.path.exists(INFO_PLIST_BACKUP):
            shutil.copy2(INFO_PLIST_PATH, INFO_PLIST_BACKUP)
            print("Created backup of Info.plist")
            
        with open(INFO_PLIST_PATH, 'rb') as f:
            plist = plistlib.load(f)
            
        plist['CFBundleExecutable'] = 'discord_'
        
        with open(INFO_PLIST_PATH, 'wb') as f:
            plistlib.dump(plist, f)
            
        print("Successfully patched Info.plist (CFBundleExecutable -> discord_)")
        return True
    except PermissionError:
        print("Permission Denied: Root permissions required to modify /Applications/Discord.app contents", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Error patching Info.plist: {e}", file=sys.stderr)
        return False

def restore_plist():
    if not os.path.exists(INFO_PLIST_BACKUP):
        print("No backup Info.plist.bak found.", file=sys.stderr)
        return False
    try:
        shutil.copy2(INFO_PLIST_BACKUP, INFO_PLIST_PATH)
        print("Restored Info.plist from backup")
        return True
    except PermissionError:
        print("Permission Denied: Root permissions required to restore Info.plist", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Error restoring Info.plist: {e}", file=sys.stderr)
        return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: DiscordPatch.py [check_settings|patch_settings|restore_settings|check_plist|patch_plist|restore_plist]")
        sys.exit(1)
        
    cmd = sys.argv[1]
    if cmd == 'check_settings':
        print(check_settings_patched())
    elif cmd == 'patch_settings':
        sys.exit(0 if patch_settings() else 1)
    elif cmd == 'restore_settings':
        sys.exit(0 if restore_settings() else 1)
    elif cmd == 'check_plist':
        print(check_plist_patched())
    elif cmd == 'patch_plist':
        sys.exit(0 if patch_plist() else 1)
    elif cmd == 'restore_plist':
        sys.exit(0 if restore_plist() else 1)
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)
