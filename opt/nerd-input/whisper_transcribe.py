import sys
import os
import subprocess
import speech_recognition as sr
from faster_whisper import WhisperModel

def record_audio_smart(output_path, timeout=10, phrase_time_limit=15):
    """
    Records audio until silence is detected using SpeechRecognition's VAD.
    """
    r = sr.Recognizer()
    # Adjust for ambient noise for better VAD
    r.dynamic_energy_threshold = True
    r.energy_threshold = 300 
    
    with sr.Microphone() as source:
        print("Adjusting for ambient noise...", file=sys.stderr)
        # r.adjust_for_ambient_noise(source, duration=0.5)
        print("Listening (will stop when you finish speaking)...", file=sys.stderr)
        try:
            # listen() will stop automatically after a period of silence
            audio = r.listen(source, timeout=timeout, phrase_time_limit=phrase_time_limit)
            with open(output_path, "wb") as f:
                f.write(audio.get_wav_data())
            return True
        except sr.WaitTimeoutError:
            print("No speech detected (timeout).", file=sys.stderr)
            return False
        except Exception as e:
            print(f"Error during recording: {e}", file=sys.stderr)
            return False

def transcribe(audio_path):
    print("Loading Whisper model...", end="", file=sys.stderr, flush=True)
    # Using 'small' for good accuracy/speed balance
    model_size = "small" 
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
    
    # We ignore the duration arg if passed, using smart recording instead
    if record_audio_smart(audio_file):
        result = transcribe(audio_file)
        if result:
            print(result)
        if os.path.exists(audio_file):
            os.remove(audio_file)
    else:
        sys.exit(1)
