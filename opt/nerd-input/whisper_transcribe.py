import sys
import os
import subprocess
from faster_whisper import WhisperModel

def record_audio(output_path, duration=5):
    # Use ffmpeg to record from default pulse/pipewire source
    # -y overwrite, -f pulse, -i default, -t duration
    print(f"Recording for {duration} seconds...", file=sys.stderr)
    try:
        subprocess.run([
            "ffmpeg", "-y", "-f", "pulse", "-i", "default",
            "-t", str(duration), output_path
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"Error recording: {e}", file=sys.stderr)
        sys.exit(1)

def transcribe(audio_path):
    print("Loading Whisper model...", end="", file=sys.stderr, flush=True)
    model_size = "small" # Higher fidelity than base, still fast
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    print(" Done.\nTranscribing...", end="", file=sys.stderr, flush=True)
    segments, info = model.transcribe(audio_path, beam_size=5)
    
    text = ""
    for segment in segments:
        text += segment.text
    print(" Done.", file=sys.stderr)
    return text.strip()

if __name__ == "__main__":
    audio_file = "/tmp/nerd_input.wav"
    # Duration could be passed as arg, default 5s
    duration = 5
    if len(sys.argv) > 1:
        duration = int(sys.argv[1])
        
    record_audio(audio_file, duration)
    result = transcribe(audio_file)
    print(result)
    if os.path.exists(audio_file):
        os.remove(audio_file)
