#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil

SPOTIFY_APP = '/Applications/Spotify.app'
SPICETIFY_BIN = os.path.expanduser('~/.spicetify/spicetify')
SPICETIFY_CONFIG = os.path.expanduser('~/.config/spicetify')

def is_spotify_installed():
    return os.path.exists(SPOTIFY_APP)

def get_spicetify_status():
    if not is_spotify_installed():
        return "spotify_not_found"
        
    spicetify_installed = os.path.exists(SPICETIFY_BIN) or shutil.which("spicetify") is not None
    if not spicetify_installed:
        return "missing"
        
    # Check if patched or backup exists
    # If backup folder exists inside Spotify contents or spicetify config has backed up files
    backup_path = os.path.expanduser('~/.config/spicetify/Backup')
    if os.path.exists(backup_path) and len(os.listdir(backup_path)) > 0:
        return "installed"
    return "installed_no_backup"

def run_command(cmd, text_output=True):
    try:
        result = subprocess.run(
            cmd, 
            shell=True, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE, 
            text=text_output
        )
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        return -1, "", str(e)

def install_spicetify():
    if not is_spotify_installed():
        print("Error: Spotify must be installed in /Applications first.", file=sys.stderr)
        return False
        
    print("Installing Spicetify CLI...")
    # Standard official install script
    install_cmd = "curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh"
    rc, stdout, stderr = run_command(install_cmd)
    
    if rc != 0:
        print(f"Failed to download/install Spicetify: {stderr}", file=sys.stderr)
        return False
        
    print("Spicetify CLI installed successfully.")
    
    # Initialize spicetify backup
    print("Running initial backup apply...")
    # Add spicetify path to command since shell environment might not have loaded ~/.spicetify in PATH yet
    bin_path = SPICETIFY_BIN if os.path.exists(SPICETIFY_BIN) else "spicetify"
    rc, stdout, stderr = run_command(f"{bin_path} backup apply")
    if rc != 0:
        # Fallback to absolute paths
        rc, stdout, stderr = run_command(f"~/.spicetify/spicetify backup apply")
        
    print(stdout)
    if rc == 0:
        print("Spicetify initial patch applied!")
        return True
    else:
        print(f"Backup apply warning/error: {stderr}", file=sys.stderr)
        # Even if backup apply fails slightly, CLI was installed
        return True

def restore_spicetify():
    bin_path = SPICETIFY_BIN if os.path.exists(SPICETIFY_BIN) else "spicetify"
    print("Restoring Spotify back to original state...")
    rc, stdout, stderr = run_command(f"{bin_path} restore")
    if rc != 0:
        rc, stdout, stderr = run_command(f"~/.spicetify/spicetify restore")
        
    print(stdout)
    if rc == 0:
        print("Successfully restored original Spotify settings.")
        return True
    else:
        print(f"Restore failed: {stderr}", file=sys.stderr)
        return False

def update_spicetify():
    bin_path = SPICETIFY_BIN if os.path.exists(SPICETIFY_BIN) else "spicetify"
    print("Updating Spicetify CLI...")
    rc, stdout, stderr = run_command(f"{bin_path} upgrade")
    if rc != 0:
        rc, stdout, stderr = run_command(f"~/.spicetify/spicetify upgrade")
        
    print(stdout)
    if rc == 0:
        print("Re-applying Spicetify rules after upgrade...")
        rc, stdout, stderr = run_command(f"{bin_path} apply")
        if rc != 0:
            run_command(f"~/.spicetify/spicetify apply")
        return True
    else:
        print(f"Upgrade failed: {stderr}", file=sys.stderr)
        return False

def backup_config():
    if not os.path.exists(SPICETIFY_CONFIG):
        print("Spicetify configuration not found. Cannot backup.", file=sys.stderr)
        return False
        
    backup_dest = os.path.expanduser('~/.config/spicetify_toolbox_backup')
    try:
        if os.path.exists(backup_dest):
            shutil.rmtree(backup_dest)
        shutil.copytree(SPICETIFY_CONFIG, backup_dest)
        print(f"Configuration backed up successfully to {backup_dest}")
        return True
    except Exception as e:
        print(f"Failed to backup configuration: {e}", file=sys.stderr)
        return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: SpicetifyMgr.py [status|install|restore|update|backup]")
        sys.exit(1)
        
    cmd = sys.argv[1]
    if cmd == 'status':
        print(get_spicetify_status())
    elif cmd == 'install':
        sys.exit(0 if install_spicetify() else 1)
    elif cmd == 'restore':
        sys.exit(0 if restore_spicetify() else 1)
    elif cmd == 'update':
        sys.exit(0 if update_spicetify() else 1)
    elif cmd == 'backup':
        sys.exit(0 if backup_config() else 1)
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)
