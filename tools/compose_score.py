"""Deterministic original chamber-score stems; offline only, no sampled music.

NumPy models bowed harmonics, decaying felt-piano partials and glass pulses.
Godot crossfades the aligned 32-second loops in response to authoritative state.
"""

from pathlib import Path
import wave

import numpy as np

RATE = 22050
SECONDS = 32
ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def save(name, data):
    ROOT.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(data, -0.95, 0.95) * 32767).astype("<i2")
    with wave.open(str(ROOT / (name + ".wav")), "wb") as output:
        output.setnchannels(2 if data.ndim == 2 else 1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())
    print(f"Original score: {name}, {len(data) / RATE:.1f}s")


def hz(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def note(track, midi, onset, duration, gain, pan, bowed=False):
    size = int(duration * RATE)
    t = np.arange(size) / RATE
    f = hz(midi)
    signal = np.zeros(size)
    for partial in range(1, 7):
        phase = 2 * np.pi * f * partial * t
        if bowed:
            phase += 0.015 * partial * np.sin(2 * np.pi * 4.8 * t)
        decay = 1 if bowed else np.exp(-t * (0.45 + partial * 0.3))
        signal += np.sin(phase) * decay / partial**1.7
    envelope = np.minimum(1, t / (1.8 if bowed else 0.018))
    envelope *= np.minimum(1, (duration - t) / (2.5 if bowed else 0.8))
    signal *= envelope * gain
    index = (np.arange(size) + int(onset * RATE)) % len(track)
    track[index, 0] += signal * np.sqrt((1 - pan) / 2)
    track[index, 1] += signal * np.sqrt((1 + pan) / 2)


def main():
    shape = (RATE * SECONDS, 2)
    bed, piano, tension = (np.zeros(shape) for _ in range(3))
    # D minor / B-flat / G minor / A suspended: no quotation of existing music.
    chords = [[38, 45, 53], [34, 41, 50], [31, 43, 50], [33, 40, 50]]
    melody = [74, 69, 65, 72, 70, 65, 62, 69, 67, 62, 65, 74, 69, 64, 62, 61]
    for bar, chord in enumerate(chords):
        for voice, pitch in enumerate(chord):
            note(bed, pitch, bar * 8 - 1, 11, 0.065, (voice - 1) * 0.6, True)
        for beat in range(4):
            note(
                piano,
                melody[bar * 4 + beat],
                bar * 8 + beat * 2,
                5,
                0.17,
                (-1) ** beat * 0.35,
            )
        for beat in range(8):
            note(tension, chord[0], bar * 8 + beat, 0.9, 0.13, 0)
            if beat % 2 == 0:
                note(tension, chord[2] + 24, bar * 8 + beat + 0.5, 2, 0.055, 0.5)
    # Sparse cross-channel room reflections; circular delays preserve looping.
    for name, track in [("bed", bed), ("piano", piano), ("tension", tension)]:
        dry = track.copy()
        for delay, gain in [(0.137, 0.19), (0.293, 0.13), (0.619, 0.07)]:
            track += np.roll(dry[:, ::-1], int(delay * RATE), axis=0) * gain
        save(name, track)
    rng = np.random.default_rng(19371117)
    t = np.arange(RATE * 7) / RATE
    noise = rng.normal(0, 1, len(t))
    kernel = np.exp(-np.arange(400) / 70)
    kernel /= kernel.sum()
    low = np.convolve(noise, kernel, mode="same")
    thunder = (low * 2 + np.sin(t * 2 * np.pi * 41) * 0.1) * np.exp(-t * 0.6)
    thunder *= np.minimum(1, t * 12) * np.minimum(1, (7 - t) * 2)
    save("thunder", thunder)
    breeze = np.convolve(noise, np.ones(35) / 35, mode="same")
    breeze *= np.sin(np.pi * t / 7) ** 2 * (0.6 + np.sin(t * 3.3) * 0.25)
    save("breeze", breeze)


if __name__ == "__main__":
    main()
