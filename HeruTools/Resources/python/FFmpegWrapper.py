#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import argparse
import json

def parse_args():
    parser = argparse.ArgumentParser(description="FFmpeg Compression Swift Wrapper")
    parser.add_argument("--input", type=str, required=True, help="Input video path")
    parser.add_argument("--output", type=str, help="Output compressed path")
    parser.add_argument("--preset", type=str, default="medium", choices=["small", "medium", "high"], help="Compression preset")
    parser.add_argument("--codec", type=str, default="h264", choices=["h264", "hevc"], help="Target codec")
    parser.add_argument("--remove_audio", action="store_true", help="Remove audio track")
    parser.add_argument("--target_size", type=float, help="Target file size in Megabytes")
    parser.add_argument("--simulated", action="store_true", help="Force simulated execution")
    return parser.parse_args()

def find_ffmpeg():
    # 1. Search bundled path inside the macOS App bundle Contents/Resources/bin/
    script_dir = os.path.dirname(os.path.abspath(__file__))
    bundled = os.path.abspath(os.path.join(script_dir, "..", "bin", "ffmpeg"))
    if os.path.exists(bundled):
        return bundled
        
    alt_bundled = os.path.abspath(os.path.join(script_dir, "..", "ffmpeg"))
    if os.path.exists(alt_bundled):
        return alt_bundled

    # 2. Fallback to standard system paths
    paths = [
        "/usr/local/bin/ffmpeg",
        "/opt/homebrew/bin/ffmpeg",
        "/usr/bin/ffmpeg",
        "ffmpeg"
    ]
    for p in paths:
        try:
            subprocess.run([p, "-version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return p
        except Exception:
            continue
    return None

def find_ffprobe():
    # 1. Search bundled path inside the macOS App bundle Contents/Resources/bin/
    script_dir = os.path.dirname(os.path.abspath(__file__))
    bundled = os.path.abspath(os.path.join(script_dir, "..", "bin", "ffprobe"))
    if os.path.exists(bundled):
        return bundled
        
    alt_bundled = os.path.abspath(os.path.join(script_dir, "..", "ffprobe"))
    if os.path.exists(alt_bundled):
        return alt_bundled

    # 2. Fallback to standard system paths
    paths = [
        "/usr/local/bin/ffprobe",
        "/opt/homebrew/bin/ffprobe",
        "/usr/bin/ffprobe",
        "ffprobe"
    ]
    for p in paths:
        try:
            subprocess.run([p, "-version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return p
        except Exception:
            continue
    return None

def get_video_info(ffprobe_path, input_path):
    try:
        cmd = [
            ffprobe_path, 
            "-v", "quiet", 
            "-print_format", "json", 
            "-show_format", 
            "-show_streams", 
            input_path
        ]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        data = json.loads(result.stdout)
        
        fmt = data.get("format", {})
        duration = float(fmt.get("duration", 0))
        size = int(fmt.get("size", 0))
        
        return {"duration": duration, "size": size}
    except Exception as e:
        print(f"Error reading video info: {e}", file=sys.stderr)
        return None

def main():
    args = parse_args()
    
    if not os.path.exists(args.input):
        print(f"Error: Input video file not found at {args.input}", file=sys.stderr)
        sys.exit(1)
        
    orig_size_bytes = os.path.getsize(args.input)
    orig_size_mb = orig_size_bytes / (1024 * 1024)
    
    output_path = args.output
    if not output_path:
        base, ext = os.path.splitext(args.input)
        output_path = f"{base}_compressed_{args.preset}_{args.codec}{ext}"
        
    print(f"Initializing video compression...")
    print(f"Input File: {args.input} ({orig_size_mb:.2f} MB)")
    print(f"Output File: {output_path}")
    sys.stdout.flush()
    
    ffmpeg_bin = find_ffmpeg()
    ffprobe_bin = find_ffprobe()
    
    is_simulated = args.simulated
    
    if not is_simulated and ffmpeg_bin is None:
        print("Error: FFmpeg is required but was not found on your Hackintosh system!", file=sys.stderr)
        print("Please run 'brew install ffmpeg' in Terminal to set up real processing.", file=sys.stderr)
        sys.exit(1)
        
    if is_simulated:
        print("[System] Executing simulation mode as requested.")
        sys.stdout.flush()
        
        factor = 0.25 if args.preset == "small" else (0.5 if args.preset == "medium" else 0.75)
        if args.target_size:
            est_size_mb = min(args.target_size, orig_size_mb * 0.9)
        else:
            est_size_mb = orig_size_mb * factor
            
        print(f"ESTIMATED_SIZE:{est_size_mb:.2f} MB")
        sys.stdout.flush()
        
        steps = 50
        duration_per_tick = 0.08
        
        for step in range(1, steps + 1):
            time.sleep(duration_per_tick)
            progress = int((step / steps) * 100)
            eta = int((steps - step) * duration_per_tick)
            print(f"PROGRESS:{progress}|ETA:{eta}s|STATUS:Encoding video packet {step * 8}/{steps * 8}")
            sys.stdout.flush()
            
        try:
            import shutil
            shutil.copy2(args.input, output_path)
            print(f"SUCCESS:Compression completed! Output saved to {output_path}")
            sys.exit(0)
        except Exception as e:
            print(f"Error copying simulated file: {e}", file=sys.stderr)
            sys.exit(1)
            
    # REAL FFMPEG COMPRESSION
    print(f"FFmpeg binary detected at: {ffmpeg_bin}")
    sys.stdout.flush()
    
    info = None
    if ffprobe_bin:
        info = get_video_info(ffprobe_bin, args.input)
        
    duration = info["duration"] if info else 120.0
    
    cmd = [ffmpeg_bin, "-y", "-i", args.input]
    
    if args.remove_audio:
        cmd.append("-an")
        
    if args.codec == "hevc":
        cmd.extend(["-c:v", "libx265"])
    else:
        cmd.extend(["-c:v", "libx264"])
        
    if args.target_size and duration > 0:
        target_bits = args.target_size * 8 * 1024 * 1024
        target_bps = int(target_bits / duration)
        if not args.remove_audio:
            target_bps = max(50000, target_bps - 128000)
        cmd.extend(["-b:v", f"{target_bps}", "-maxrate", f"{int(target_bps * 1.5)}", "-bufsize", f"{int(target_bps * 2)}"])
    else:
        if args.preset == "small":
            crf = "28"
        elif args.preset == "medium":
            crf = "23"
        else:
            crf = "18"
        cmd.extend(["-crf", crf])
        
    cmd.extend(["-preset", "veryfast"])
    cmd.append(output_path)
    
    print(f"Executing FFmpeg: {' '.join(cmd)}")
    sys.stdout.flush()
    
    factor = 0.25 if args.preset == "small" else (0.5 if args.preset == "medium" else 0.75)
    est_size_mb = args.target_size if args.target_size else (orig_size_mb * factor)
    print(f"ESTIMATED_SIZE:{est_size_mb:.2f} MB")
    sys.stdout.flush()
    
    try:
        process = subprocess.Popen(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
        
        while True:
            line = process.stderr.readline()
            if not line and process.poll() is not None:
                break
            
            if "time=" in line:
                try:
                    time_part = line.split("time=")[1].split()[0]
                    h, m, s = time_part.split(":")
                    elapsed = float(h)*3600 + float(m)*60 + float(s)
                    progress = min(99, int((elapsed / duration) * 100))
                    speed_factor = 1.0
                    if "speed=" in line:
                        try:
                            speed_str = line.split("speed=")[1].split()[0].replace("x", "")
                            speed_factor = max(0.1, float(speed_str))
                        except Exception:
                            pass
                    eta = int((duration - elapsed) / speed_factor)
                    print(f"PROGRESS:{progress}|ETA:{eta}s|STATUS:Encoding: {time_part}")
                    sys.stdout.flush()
                except Exception:
                    pass
                    
        rc = process.poll()
        if rc == 0:
            print(f"SUCCESS:Compression completed! Output saved to {output_path}")
            sys.exit(0)
        else:
            print(f"FFmpeg failed with return code {rc}", file=sys.stderr)
            sys.exit(rc)
            
    except Exception as e:
        print(f"FFmpeg subprocess failure: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
