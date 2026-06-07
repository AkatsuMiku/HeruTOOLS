#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description="FFmpeg-powered VFI Motion Interpolator")
    parser.add_argument("--input", type=str, required=True, help="Path to input video")
    parser.add_argument("--output", type=str, help="Path to output interpolated video")
    parser.add_argument("--fps_factor", type=float, default=2.0, help="Multiplier: 2.0 for 2x, 4.0 for 4x")
    parser.add_argument("--model", type=str, default="rife-v4.6", choices=[
        "rife-v2.4",
        "rife-v3.1",
        "rife-v4.6",
        "rife-v4.15-lite",
        "rife-anime"
    ], help="Model choice mapped to interpolation filters")
    parser.add_argument("--crf", type=int, default=22, help="FFmpeg Constant Rate Factor (CRF) quality")
    parser.add_argument("--simulated", action="store_true", help="Force simulated execution")
    return parser.parse_args()

def find_ffmpeg():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    for rel in [os.path.join("..", "bin", "ffmpeg"), os.path.join("..", "ffmpeg")]:
        p = os.path.abspath(os.path.join(script_dir, rel))
        if os.path.exists(p):
            return p
    for p in ["/usr/local/bin/ffmpeg", "/opt/homebrew/bin/ffmpeg", "/usr/bin/ffmpeg", "ffmpeg"]:
        try:
            subprocess.run([p, "-version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return p
        except Exception:
            continue
    return None

def find_ffprobe():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    for rel in [os.path.join("..", "bin", "ffprobe"), os.path.join("..", "ffprobe")]:
        p = os.path.abspath(os.path.join(script_dir, rel))
        if os.path.exists(p):
            return p
    for p in ["/usr/local/bin/ffprobe", "/opt/homebrew/bin/ffprobe", "/usr/bin/ffprobe", "ffprobe"]:
        try:
            subprocess.run([p, "-version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return p
        except Exception:
            continue
    return None

def get_video_info(ffprobe_path, input_path):
    """Returns (fps, duration, width, height, codec_name)"""
    try:
        # FPS
        res_fps = subprocess.run(
            [ffprobe_path, "-v", "0", "-of", "csv=p=0",
             "-select_streams", "v:0", "-show_entries", "stream=r_frame_rate",
             input_path],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        fps_str = res_fps.stdout.strip()
        fps = 30.0
        if "/" in fps_str:
            num, den = fps_str.split("/")
            fps = float(num) / float(den) if float(den) != 0 else 30.0
        elif fps_str:
            fps = float(fps_str)

        # Duration
        res_dur = subprocess.run(
            [ffprobe_path, "-v", "0", "-of", "csv=p=0",
             "-show_entries", "format=duration",
             input_path],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        duration = float(res_dur.stdout.strip()) if res_dur.stdout.strip() else 10.0

        # Width, height, codec via JSON — much more reliable than csv for complex streams
        res_stream = subprocess.run(
            [ffprobe_path, "-v", "0",
             "-select_streams", "v:0",
             "-show_entries", "stream=width,height,codec_name",
             "-of", "default=noprint_wrappers=1:nokey=0",
             input_path],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        width, height, codec_name = 1920, 1080, "unknown"
        for line in res_stream.stdout.splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                k, v = k.strip(), v.strip()
                if k == "width":
                    width = int(v)
                elif k == "height":
                    height = int(v)
                elif k == "codec_name":
                    codec_name = v.lower()

        return fps, duration, width, height, codec_name
    except Exception as e:
        print(f"ffprobe warning: {e}", file=sys.stderr)
        return 30.0, 10.0, 1920, 1080, "unknown"

# Codecs that need to be re-encoded to rawvideo before filtering
# because many FFmpeg filters can't handle them directly
TRICKY_CODECS = {
    "qtrle",         # QuickTime Animation (lossless)
    "png",           # PNG video / APNG
    "ffv1",          # FFV1 lossless
    "huffyuv",       # HuffYUV
    "utvideo",       # Ut Video
    "prores",        # Apple ProRes
    "dnxhd",         # Avid DNxHD
    "v210",          # Uncompressed 4:2:2 10-bit
    "r210",          # Uncompressed RGB 10-bit
}

# Pad dimensions to even numbers for libx264 compatibility.
# Appended to every filter chain since libx264 requires width & height divisible by 2.
EVEN_SCALE = "scale=trunc(iw/2)*2:trunc(ih/2)*2"

def build_filter_string(model, target_fps, width, height):
    """
    Builds the FFmpeg -vf filter. Uses lighter algorithm for >1080p
    to avoid running out of memory. Always pads to even dimensions.
    """
    is_high_res = (width > 1920 or height > 1080)

    if is_high_res:
        print(f"[Info] High resolution ({width}x{height}) → using memory-safe framerate filter.", flush=True)
        base = f"framerate=fps={target_fps}:interp_start=0:interp_end=255:scene=100"
    elif model == "rife-anime":
        base = f"minterpolate=fps={target_fps}:mi_mode=blend"
    elif model == "rife-v4.15-lite":
        base = f"framerate=fps={target_fps}"
    else:
        base = f"minterpolate=fps={target_fps}:mi_mode=mci:mc_mode=aobmc:vsbmc=1"

    # Always ensure even dimensions for libx264
    return f"{base},{EVEN_SCALE}"

def build_input_args(codec_name):
    """
    Some codecs need special decoder flags so FFmpeg can feed frames to filters.
    Returns a list of arguments to insert BEFORE -i.
    """
    if codec_name in ("av1", "libaom-av1", "libdav1d"):
        return ["-c:v", "libdav1d"]
    return []

def needs_intermediate_decode(codec_name):
    """
    Returns True if the codec is a 'tricky' one that needs a
    two-pass approach: decode → rawvideo pipe → filter → encode.
    """
    return codec_name in TRICKY_CODECS

def run_interpolation_twopass(ffmpeg_bin, input_path, output_path, filter_str, crf, width, height, duration, orig_fps=24.0):
    """
    Two-pass pipeline for tricky codecs (QTRLE, ProRes, PNG, etc.):
      Pass 1: ffmpeg -i input → rawvideo on stdout (pipe)
      Pass 2: ffmpeg reads rawvideo from stdin → applies vf filter → encodes

    Uses a subprocess pipe to avoid writing a huge raw temp file to disk.
    """
    print("[Info] Tricky codec detected — using two-pass decode pipeline.", flush=True)

    # ffprobe for fps (we already have it, but pass it in via filter_str)
    # Round down to even dimensions for the raw pipe (libx264 requirement)
    pipe_w = (width  // 2) * 2
    pipe_h = (height // 2) * 2

    cmd_decode = [
        ffmpeg_bin, "-y",
        "-i", input_path,
        "-vf", f"scale={pipe_w}:{pipe_h}",  # force even dimensions at decode stage
        "-f", "rawvideo",
        "-pix_fmt", "yuv420p",
        "pipe:1"
    ]

    cmd_encode = [
        ffmpeg_bin, "-y",
        "-f", "rawvideo",
        "-pix_fmt", "yuv420p",
        "-video_size", f"{pipe_w}x{pipe_h}",
        "-framerate", str(round(orig_fps, 3)),   # tell FFmpeg the input frame rate
        "-i", "pipe:0",
        "-vf", filter_str,
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-crf", str(crf),
        "-movflags", "+faststart",
        "-an",   # input has no audio from rawvideo pipe; audio handled separately if needed
        output_path
    ]

    print(f"Decode cmd: {' '.join(cmd_decode)}", flush=True)
    print(f"Encode cmd: {' '.join(cmd_encode)}", flush=True)

    try:
        proc_dec = subprocess.Popen(cmd_decode, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        proc_enc = subprocess.Popen(
            cmd_encode,
            stdin=proc_dec.stdout,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True, bufsize=1
        )
        # Allow proc_dec to receive SIGPIPE if proc_enc closes its stdin
        proc_dec.stdout.close()

        while True:
            line = proc_enc.stderr.readline()
            if not line and proc_enc.poll() is not None:
                break
            if "time=" in line:
                try:
                    time_part = line.split("time=")[1].split()[0]
                    h, m, s = time_part.split(":")
                    elapsed = float(h)*3600 + float(m)*60 + float(s)
                    progress = min(99, int((elapsed / max(duration, 0.1)) * 100))
                    speed_factor = 1.0
                    if "speed=" in line:
                        try:
                            speed_str = line.split("speed=")[1].split()[0].replace("x", "")
                            speed_factor = max(0.1, float(speed_str))
                        except Exception:
                            pass
                    eta = int((duration - elapsed) / speed_factor)
                    print(f"PROGRESS:{progress}|ETA:{eta}s|STATUS:Processing frame: {time_part}", flush=True)
                except Exception:
                    pass

        proc_dec.wait()
        rc = proc_enc.poll()
        return rc if rc is not None else 0

    except Exception as e:
        print(f"Two-pass pipeline error: {e}", file=sys.stderr)
        return 1

def run_interpolation_direct(ffmpeg_bin, input_path, output_path, filter_str, crf, input_args, duration):
    """Standard single-pass interpolation — works for most codecs."""
    cmd = [ffmpeg_bin, "-y"] + input_args + [
        "-i", input_path,
        "-vf", filter_str,
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-crf", str(crf),
        "-c:a", "aac",
        "-b:a", "192k",
        "-movflags", "+faststart",
        output_path
    ]
    print(f"Executing FFmpeg command...", flush=True)

    try:
        process = subprocess.Popen(
            cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE,
            text=True, bufsize=1
        )

        while True:
            line = process.stderr.readline()
            if not line and process.poll() is not None:
                break
            if "time=" in line:
                try:
                    time_part = line.split("time=")[1].split()[0]
                    h, m, s = time_part.split(":")
                    elapsed = float(h)*3600 + float(m)*60 + float(s)
                    progress = min(99, int((elapsed / max(duration, 0.1)) * 100))
                    speed_factor = 1.0
                    if "speed=" in line:
                        try:
                            speed_str = line.split("speed=")[1].split()[0].replace("x", "")
                            speed_factor = max(0.1, float(speed_str))
                        except Exception:
                            pass
                    eta = int((duration - elapsed) / speed_factor)
                    print(f"PROGRESS:{progress}|ETA:{eta}s|STATUS:Processing frame: {time_part}", flush=True)
                except Exception:
                    pass

        return process.poll() or 0

    except Exception as e:
        print(f"Subprocess error: {e}", file=sys.stderr)
        return 1

def main():
    args = parse_args()

    if not os.path.exists(args.input):
        print(f"Error: Input video not found at {args.input}", file=sys.stderr)
        sys.exit(1)

    ffmpeg_bin = find_ffmpeg()
    ffprobe_bin = find_ffprobe()
    is_simulated = args.simulated

    if not is_simulated and ffmpeg_bin is None:
        print("Error: FFmpeg not found. Run 'brew install ffmpeg' in Terminal.", file=sys.stderr)
        sys.exit(1)

    output_path = args.output
    if not output_path:
        base, _ = os.path.splitext(args.input)
        output_path = f"{base}_interpolated_{int(args.fps_factor)}x_{args.model}.mp4"

    print(f"Starting Frame Interpolation Pipeline...")
    print(f"Input:  {args.input}")
    print(f"Output: {output_path}")
    sys.stdout.flush()

    if is_simulated:
        print("[System] Running simulated interpolation ticks...")
        sys.stdout.flush()
        for step in range(1, 101):
            time.sleep(0.05)
            print(f"PROGRESS:{step}|ETA:{(100-step)//20}s|STATUS:Simulating {args.model} pass: frame {step * 10}")
            sys.stdout.flush()
        import shutil
        shutil.copy2(args.input, output_path)
        print(f"SUCCESS:Interpolation completed! Output saved to {output_path}")
        sys.exit(0)

    print(f"FFmpeg: {ffmpeg_bin}")
    sys.stdout.flush()

    orig_fps, duration, width, height, codec_name = get_video_info(ffprobe_bin, args.input)
    target_fps = orig_fps * args.fps_factor

    print(f"Video: {width}x{height} | Codec: {codec_name} | {orig_fps:.2f} FPS → {target_fps:.2f} FPS | Duration: {duration:.2f}s | CRF: {args.crf}")
    sys.stdout.flush()

    # Warn if video is very short (< 2 seconds)
    if duration < 2.0:
        print(f"[Warning] Input video is very short ({duration:.2f}s). Output may be small — this is expected.", flush=True)

    filter_str  = build_filter_string(args.model, target_fps, width, height)
    input_args  = build_input_args(codec_name)
    use_twopass = needs_intermediate_decode(codec_name)

    if use_twopass:
        rc = run_interpolation_twopass(ffmpeg_bin, args.input, output_path, filter_str, args.crf, width, height, duration, orig_fps)
    else:
        rc = run_interpolation_direct(ffmpeg_bin, args.input, output_path, filter_str, args.crf, input_args, duration)

    if rc == 0:
        print(f"SUCCESS:Interpolation completed! Output saved to {output_path}")
        sys.exit(0)
    else:
        print(f"FFmpeg failed with exit code {rc}", file=sys.stderr)
        sys.exit(rc if rc else 1)

if __name__ == "__main__":
    main()
