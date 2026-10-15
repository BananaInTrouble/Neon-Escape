#!/usr/bin/env python3
"""Synthétise les effets sonores du jeu (aucune ressource externe, aucune licence).

Usage (depuis la racine du projet) : python3 tools/generate_sfx.py
Écrit des fichiers WAV mono 16 bits dans assets/audio/sfx/. Relancer après une
modification ; Godot réimporte automatiquement les fichiers.
"""
import os
import wave

import numpy as np

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")
rng = np.random.default_rng(7)  # graine fixe : fichiers identiques à chaque génération


def t_axis(duration):
    return np.arange(int(RATE * duration)) / RATE


def envelope(n, attack=0.004, decay=8.0):
    t = np.arange(n) / RATE
    env = np.exp(-decay * t)
    a = max(1, int(RATE * attack))
    env[:a] *= np.linspace(0.0, 1.0, a)
    env[-64:] *= np.linspace(1.0, 0.0, 64)  # fin douce, pas de clic
    return env


def tone(freq_start, freq_end, duration, decay, harmonics=(1.0, 0.25)):
    t = t_axis(duration)
    freq = np.linspace(freq_start, freq_end, t.size)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    sig = sum(a * np.sin(phase * (i + 1)) for i, a in enumerate(harmonics))
    return sig * envelope(t.size, decay=decay)


def lowpass(sig, alpha):
    out = np.empty_like(sig)
    acc = 0.0
    for i, x in enumerate(sig):
        acc += alpha * (x - acc)
        out[i] = acc
    return out


def concat(*parts, gap=0.0):
    silence = np.zeros(int(RATE * gap))
    chunks = []
    for p in parts:
        chunks += [p, silence]
    return np.concatenate(chunks[:-1])


def save(name, sig, peak_db=-3.0):
    sig = sig / max(1e-9, np.max(np.abs(sig))) * (10 ** (peak_db / 20))
    data = (sig * 32767).astype("<i2")
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print(f"{path}  ({len(data) / RATE:.2f} s)")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    # Changement de voie : petit « swoosh » montant, très court.
    save("move", tone(520, 880, 0.07, decay=35, harmonics=(1.0, 0.3, 0.1)), peak_db=-9)
    # Point marqué : deux notes cristallines (mi, si).
    save("score", concat(tone(1318, 1318, 0.07, 30), tone(1976, 1976, 0.12, 22)), peak_db=-8)
    # Collision : souffle filtré + grondement descendant.
    noise = lowpass(rng.uniform(-1, 1, int(RATE * 0.5)), 0.18) * envelope(int(RATE * 0.5), decay=7)
    rumble = tone(260, 45, 0.5, decay=5, harmonics=(1.0, 0.5, 0.25))
    save("crash", noise * 1.4 + rumble, peak_db=-2)
    # Nouveau record : arpège montant do-mi-sol-do.
    notes = [1047, 1319, 1568, 2093]
    save("record", concat(*[tone(f, f, 0.11, 14, (1.0, 0.2)) for f in notes]), peak_db=-5)
    # Bouton : clic discret.
    save("click", tone(1400, 1100, 0.035, 60, (1.0,)), peak_db=-12)


if __name__ == "__main__":
    main()
