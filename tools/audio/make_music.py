"""Composes the game's music loops into assets/audio/music/*.ogg.

    python3 tools/audio/make_music.py

A small synth + drum machine: each track is a chord progression in a minor key,
bass, pads, an arpeggio and drums, mixed with side-chain ducking and rendered so the
end flows straight back into the start (the reverb tail is folded onto the head).
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from dsp import *  # noqa: E402,F401

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "music")


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ── Instruments (mono clips) ──────────────────────────────────────────────────
def kick(g=1.0):
    d = 0.4
    return (osc(glide(130, 42, d, 0.35), d) * env_exp(d, 0.16, 0.001) + hp(noise(d), 3000) * env_exp(d, 0.003) * 0.3) * g


def snare(g=1.0):
    d = 0.3
    return (bp(noise(d), 1200, 7000) * env_exp(d, 0.09) * 0.8 + osc(190, d) * env_exp(d, 0.05) * 0.5) * g


def hat(open_=False, g=1.0):
    d = 0.25 if open_ else 0.06
    return hp(noise(d), 7000) * env_exp(d, 0.12 if open_ else 0.02) * g


def tom(f, g=1.0):
    d = 0.6
    return (osc(glide(f * 1.6, f, d, 0.3), d) * env_exp(d, 0.22) + lp(noise(d), 600) * env_exp(d, 0.03) * 0.3) * g


def bass_note(n, d, bright=600.0, dist=1.0):
    f = midi(n)
    x = osc(f, d, "saw") * 0.6 + osc(f / 2, d) * 0.7
    x = lp(x, bright) * env_adsr(d, 0.005, 0.15, 0.7, 0.05)
    return drive(x, 1.0 + dist)


def pad_chord(notes, d, cutoff=1400.0):
    """Stereo: detuned saws per note, slow swell."""
    L = np.zeros(int(d * SR))
    R = np.zeros(int(d * SR))
    for n in notes:
        f = midi(n)
        L += osc(f * 0.997, d, "saw") + osc(f * 1.004, d, "saw") * 0.6
        R += osc(f * 1.003, d, "saw") + osc(f * 0.995, d, "saw") * 0.6
    e = env_adsr(d, d * 0.3, d * 0.2, 0.8, d * 0.3)
    return lp(L, cutoff) * e, lp(R, cutoff) * e


def pluck(n, d=0.3, shape="tri", dec=0.12):
    f = midi(n)
    return (osc(f, d, shape) + osc(f * 2, d, "sine") * 0.25) * env_exp(d, dec, 0.002)


def drone(n, d):
    f = midi(n)
    x = osc(f, d) * 0.6 + osc(f * 1.5, d) * 0.15 + lp(noise(d), 180) * 0.25
    return x * (0.85 + 0.15 * np.sin(2 * np.pi * 0.11 * t(d)))


# ── Arrangement ───────────────────────────────────────────────────────────────
SCALE = [0, 2, 3, 5, 7, 8, 10]  # natural minor


def triad(root, degree):
    """Minor-key triad on a scale degree (0-based), as MIDI notes around root."""
    idx = [degree, degree + 2, degree + 4]
    return [root + SCALE[i % 7] + 12 * (i // 7) for i in idx]


def render(spec):
    bpm = spec["bpm"]
    beat = 60.0 / bpm
    bar = beat * 4
    bars = spec["bars"]
    total = bars * bar
    tail = 3.0
    n = int((total + tail) * SR)
    L = np.zeros(n)
    R = np.zeros(n)
    duck = np.ones(n)
    drums = np.zeros(n)
    root = spec["root"]
    prog = spec["prog"]
    chords_per_bar = spec.get("chord_bars", 2)

    for b in range(bars):
        t0 = b * bar
        deg = prog[(b // chords_per_bar) % len(prog)]
        chord = triad(root, deg)
        second_half = b >= bars // 2
        # Pads: one swell per chord
        if b % chords_per_bar == 0 and spec.get("pad", True):
            pl, pr = pad_chord([c + 12 for c in chord], bar * chords_per_bar + 0.3, spec.get("pad_cut", 1400))
            place(L, pl, t0, spec.get("pad_gain", 0.22))
            place(R, pr, t0, spec.get("pad_gain", 0.22))
        # Drone
        if spec.get("drone") and b % 4 == 0:
            dr = drone(root - 12, bar * 4 + 0.5)
            place(L, dr, t0, spec["drone"])
            place(R, dr, t0, spec["drone"])
        # Bass
        pattern = spec.get("bass", "8ths")
        if pattern:
            steps = {"8ths": 8, "quarters": 4, "half": 2, "16ths": 16}[pattern]
            for s in range(steps):
                if pattern == "8ths" and spec.get("bass_skip") and s in spec["bass_skip"]:
                    continue
                note = chord[0] - 12 + (12 if (pattern == "16ths" and s % 4 == 3) else 0)
                bn = bass_note(note, bar / steps * 0.95, spec.get("bass_bright", 600), spec.get("bass_dist", 1.0))
                place(L, bn, t0 + s * bar / steps, spec.get("bass_gain", 0.35))
                place(R, bn, t0 + s * bar / steps, spec.get("bass_gain", 0.35))
        # Arpeggio (second half, or always)
        if spec.get("arp") and (second_half or spec.get("arp_always")):
            arp_notes = [chord[0] + 12, chord[1] + 12, chord[2] + 12, chord[1] + 24]
            div = spec.get("arp_div", 8)
            for s in range(div):
                nn = arp_notes[s % len(arp_notes)]
                pk = pluck(nn, 0.35, spec.get("arp_shape", "tri"), spec.get("arp_dec", 0.12))
                at = t0 + s * bar / div
                place(L, pk, at, spec["arp"])
                place(R, pk, at + 0.375 * beat, spec["arp"] * 0.5)  # echo on the right
        # Drums
        kpat = spec.get("kick", [0, 2])
        for k in kpat:
            at = t0 + k * beat
            place(drums, kick(), at, spec.get("kick_gain", 0.8))
            i = int(at * SR)
            dn = int(0.25 * SR)
            duck[i:i + dn] = np.minimum(duck[i:i + dn], 0.45 + 0.55 * np.linspace(0, 1, len(duck[i:i + dn])))
        for sn in spec.get("snare", [1, 3]):
            place(drums, snare(), t0 + sn * beat, spec.get("snare_gain", 0.45))
        hats = spec.get("hats", 8)
        for h in range(hats):
            place(drums, hat(open_=(h % 4 == 2 and spec.get("open_hats"))), t0 + h * bar / hats, spec.get("hat_gain", 0.18) * (1.0 if h % 2 == 0 else 0.6))
        for tb, tf in spec.get("toms", []):
            place(drums, tom(tf), t0 + tb * beat, 0.6)
        # Fill into the loop point
        if b == bars - 1 and spec.get("fill"):
            for s in range(4):
                place(drums, snare(), t0 + 3 * beat + s * beat / 4, 0.35 + 0.1 * s)

    # Pads/bass duck under the kick; reverb on the melodic layers
    L *= duck
    R *= duck
    L = reverb(L, 2.0, spec.get("verb", 0.3), 3000)[:n]
    R = reverb(R, 2.1, spec.get("verb", 0.3), 3000)[:n]
    L += drums
    R += drums
    # Fold the tail back onto the head so the loop is seamless
    cut = int(total * SR)
    for ch in (L, R):
        ch[:n - cut] += ch[cut:]
    st = np.stack([L[:cut], R[:cut]], axis=1)
    st = np.tanh(st * 1.3) / np.tanh(1.3)
    return st


TRACKS = {
    # Title and hub: slow, wide, no drums but a heartbeat kick
    "menu": dict(bpm=70, bars=16, root=57, prog=[0, 5, 2, 6], chord_bars=2, bass="half", bass_gain=0.25,
                 kick=[0], snare=[], hats=0, arp=0.12, arp_div=8, arp_dec=0.3, pad_gain=0.3, pad_cut=1100,
                 drone=0.15, verb=0.45),
    # Sector 1: steady push
    "sector1": dict(bpm=100, bars=16, root=50, prog=[0, 5, 2, 6], bass="8ths", bass_gain=0.32,
                    kick=[0, 2, 2.5], snare=[1, 3], hats=8, arp=0.1, fill=True),
    # Sector 2: golden hour, a little brighter and faster
    "sector2": dict(bpm=108, bars=16, root=52, prog=[0, 3, 5, 4], bass="8ths", bass_gain=0.3, bass_bright=900,
                    kick=[0, 1.5, 2], snare=[1, 3], hats=16, hat_gain=0.12, arp=0.12, arp_div=16, arp_dec=0.08,
                    arp_always=True, fill=True),
    # Sector 3: night docks, sparse and tense
    "sector3": dict(bpm=88, bars=16, root=48, prog=[0, 0, 5, 4], bass="quarters", bass_gain=0.32, bass_bright=400,
                    kick=[0], snare=[2], snare_gain=0.3, hats=16, hat_gain=0.08, arp=0.09, arp_div=4, arp_dec=0.4,
                    arp_shape="sine", pad_gain=0.2, pad_cut=900, drone=0.2, verb=0.4),
    # Sector 4: the Complex, heavy
    "sector4": dict(bpm=120, bars=16, root=53, prog=[0, 5, 3, 4], bass="16ths", bass_gain=0.3, bass_dist=3.0,
                    kick=[0, 1, 2, 3], snare=[1, 3], hats=8, open_hats=True, arp=0.08, fill=True,
                    toms=[(3.5, 90)]),
    # Bosses and holds
    "boss": dict(bpm=136, bars=16, root=45, prog=[0, 1, 0, 6], chord_bars=1, bass="16ths", bass_gain=0.32,
                 bass_dist=4.0, bass_bright=900, kick=[0, 1, 2, 3], snare=[1, 3], hats=16, hat_gain=0.14,
                 arp=0.1, arp_div=16, arp_dec=0.06, arp_shape="square", arp_always=True, fill=True,
                 toms=[(2.5, 100), (3.5, 80)], pad_gain=0.18),
}


def main():
    names = sys.argv[1:] or list(TRACKS)
    for name in names:
        st = render(TRACKS[name])
        write_ogg(os.path.join(OUT, name + ".ogg"), st, quality=3, peak=0.85)
        print("%s: %.1f s" % (name, len(st) / SR))


if __name__ == "__main__":
    main()
