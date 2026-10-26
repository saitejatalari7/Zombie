"""Synthesizes every sound effect into assets/audio/sfx/*.ogg.

    python3 tools/audio/make_sfx.py

Names match AudioManager.sfx_registry; "name_2.ogg", "name_3.ogg" are variants the
manager picks between at random.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from dsp import *  # noqa: E402,F401

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")
made = []


def save(name, x, **kw):
    write_ogg(os.path.join(OUT, name + ".ogg"), x, **kw)
    made.append(name)


# ── Weapons ───────────────────────────────────────────────────────────────────
def gunshot(seed):
    r = np.random.default_rng(seed)
    d = 0.5
    crack = hp(noise(d), 2500) * env_exp(d, 0.006)
    body = bp(noise(d), 250, 2600) * env_exp(d, 0.035 + 0.01 * r.random())
    thump = osc(glide(110 + 20 * r.random(), 42, d, 0.4), d) * env_exp(d, 0.07)
    tail = lp(noise(d), 900) * env_exp(d, 0.18) * 0.35
    x = crack * 0.7 + body * 1.0 + thump * 0.9 + tail
    return reverb(drive(x, 2.2), 0.6, 0.12, 2500)


def reload_sound():
    d = 0.75
    buf = np.zeros(int(d * SR))
    def metal(dur, f1, f2, dec):
        return (osc(f1, dur) * 0.6 + osc(f2, dur) * 0.4) * env_exp(dur, dec) + hp(noise(dur), 3000) * env_exp(dur, 0.004)
    place(buf, metal(0.08, 2300, 3700, 0.02), 0.00, 0.8)            # mag release
    place(buf, bp(noise(0.12), 900, 4000) * env_adsr(0.12, 0.01, 0.05, 0.4, 0.06), 0.18, 0.5)  # mag slides out
    place(buf, metal(0.1, 1600, 2900, 0.025) + lp(noise(0.1), 500) * env_exp(0.1, 0.02), 0.42, 1.0)  # mag seats
    place(buf, metal(0.06, 2800, 4400, 0.015), 0.58, 0.7)            # bolt back
    place(buf, metal(0.07, 2000, 3300, 0.02), 0.66, 0.9)             # bolt forward
    return buf


def rocket_fire():
    d = 0.9
    w = bp(noise(d), 300, 3000)
    w = sweep_filter(w, 600, 3500, "low") * env_adsr(d, 0.02, 0.3, 0.4, 0.5)
    thump = osc(glide(90, 40, d), d) * env_exp(d, 0.1)
    return reverb(drive(w + thump * 0.8, 1.6), 0.8, 0.18)


def explosion(size=1.0):
    d = 2.2 * size
    boom = osc(glide(70, 26, d, 0.5), d) * env_exp(d, 0.45 * size, 0.004)
    rumble = lp(noise(d), 700) * env_exp(d, 0.7 * size, 0.003)
    blast = bp(noise(d), 200, 5000) * env_exp(d, 0.09)
    crackle = np.zeros(int(d * SR))
    for _ in range(int(60 * size)):
        at = rng.uniform(0.05, d * 0.7)
        place(crackle, hp(noise(0.01), 1500) * env_exp(0.01, 0.002), at, rng.uniform(0.1, 0.5) * np.exp(-at * 2))
    x = boom * 1.2 + rumble * 0.9 + blast * 0.8 + crackle
    return reverb(drive(x, 2.5), 1.6, 0.28, 2000)


# ── Impacts ───────────────────────────────────────────────────────────────────
def flesh(seed):
    r = np.random.default_rng(seed)
    d = 0.22
    squelch = bp(noise(d), 180 + 80 * r.random(), 900) * env_exp(d, 0.03)
    thud = osc(glide(200, 70, d), d) * env_exp(d, 0.03)
    wet = bp(noise(d), 1200, 3500) * env_exp(d, 0.012) * 0.4
    return drive(squelch + thud * 0.7 + wet, 1.5)


def wall_hit(seed):
    r = np.random.default_rng(seed)
    d = 0.3
    tick = hp(noise(d), 2000) * env_exp(d, 0.005)
    dust = bp(noise(d), 600, 3000) * env_exp(d, 0.03) * 0.5
    x = tick + dust
    if r.random() < 0.5:  # ricochet whine
        x += osc(glide(2600 + 400 * r.random(), 1700, d), d) * env_exp(d, 0.09, 0.01) * 0.35
    return x


def casing():
    d = 0.35
    buf = np.zeros(int(d * SR))
    for at, g in ((0.0, 1.0), (0.09, 0.55), (0.16, 0.3)):
        ping = (osc(4300, 0.08) + osc(6100, 0.08) * 0.6) * env_exp(0.08, 0.018)
        place(buf, ping, at, g)
    return buf


# ── Molotov and fire ──────────────────────────────────────────────────────────
def whoosh(d=0.45):
    w = bp(noise(d), 400, 3000)
    return sweep_filter(w, 500, 2500, "low") * env_adsr(d, 0.15, 0.1, 0.6, 0.2)


def shatter():
    d = 1.3
    buf = np.zeros(int(d * SR))
    place(buf, hp(noise(0.08), 2500) * env_exp(0.08, 0.02), 0.0, 0.9)
    for _ in range(26):
        f = rng.uniform(2500, 8000)
        place(buf, osc(f, 0.15) * env_exp(0.15, rng.uniform(0.02, 0.06)), rng.uniform(0.0, 0.25), rng.uniform(0.1, 0.35))
    ign = lp(noise(1.0), 900)
    ign = sweep_filter(ign, 200, 1600, "low") * env_adsr(1.0, 0.12, 0.3, 0.5, 0.5)
    place(buf, ign, 0.05, 1.1)
    return reverb(buf, 0.9, 0.2)


def fire_loop():
    d = 3.0
    rumble = lp(noise(d), 400) * 0.6
    hiss = bp(noise(d), 1500, 6000) * 0.12
    pops = np.zeros(int(d * SR))
    for _ in range(70):
        place(pops, hp(noise(0.012), 1200) * env_exp(0.012, 0.003), rng.uniform(0, d - 0.02), rng.uniform(0.2, 0.9))
    x = rumble + hiss + pops * 0.6
    # Seamless loop: crossfade the tail into the head
    n = int(0.4 * SR)
    head, tail = x[:n], x[-n:]
    ramp = np.linspace(0, 1, n)
    x = x[:-n].copy()
    x[:n] = head * ramp + tail * (1 - ramp)
    return x


# ── Voices (zombies, player) ──────────────────────────────────────────────────
def voice(f0_path, d, vowel, rasp=0.3, jitter=0.04, breath=0.15):
    """Glottal pulse train through vowel formants, with pitch jitter and breath noise."""
    n = int(d * SR)
    jit = 1.0 + jitter * lp(rng.uniform(-1, 1, n), 18) * 6
    f = np.asarray(f0_path)[:n] * jit
    src = osc(f, d, "saw") * 0.7 + osc(f * 0.5, d, "square") * 0.15
    # Rasp: noise gated by the glottal cycle, kept under the harmonics so it reads as a throat
    src += 0.35 * rasp * bp(noise(d), 300, 3000) * (0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(f) / SR)) ** 4
    vowels = {
        "uh": [(520, 1.0), (1100, 0.6), (2500, 0.25)],
        "ah": [(750, 1.0), (1200, 0.7), (2600, 0.3)],
        "oh": [(450, 1.0), (800, 0.6), (2600, 0.15)],
        "ee": [(300, 0.8), (2200, 0.6), (3000, 0.3)],
    }
    out = formants(src, vowels[vowel], 7.0) + 0.3 * breath * bp(noise(d), 500, 4000)
    return out


def groan(seed):
    r = np.random.default_rng(seed)
    d = r.uniform(1.2, 1.8)
    f0 = 75 + 30 * r.random()
    path = glide(f0 * 1.15, f0 * 0.8, d) * (1 + 0.04 * np.sin(2 * np.pi * 4.5 * t(d)))
    x = voice(path, d, ["uh", "oh", "ah"][seed % 3], rasp=0.45)
    x *= env_adsr(d, 0.25, 0.3, 0.7, 0.5)
    return reverb(drive(x, 2.0), 0.8, 0.15)


def zombie_hit(seed):
    r = np.random.default_rng(seed)
    d = 0.3
    x = voice(glide(150 + 40 * r.random(), 110, d), d, "uh", rasp=0.6) * env_exp(d, 0.09, 0.008)
    return drive(place(x, flesh(seed), 0.0, 0.5), 2.0)


def zombie_death(seed):
    r = np.random.default_rng(seed)
    d = 1.1
    x = voice(glide(130 + 30 * r.random(), 55, d, 0.6), d, "ah", rasp=0.6) * env_adsr(d, 0.02, 0.3, 0.6, 0.6)
    splat = bp(noise(0.4), 150, 1200) * env_exp(0.4, 0.08)
    x = place(x, splat, 0.0, 0.8)
    return reverb(drive(x, 2.2), 0.8, 0.15)


def runner_scream(seed):
    r = np.random.default_rng(seed)
    d = 0.9
    path = glide(260 + 60 * r.random(), 420, d, 0.5)
    x = voice(path, d, "ah", rasp=0.8, jitter=0.08, breath=0.3) * env_adsr(d, 0.04, 0.2, 0.7, 0.35)
    return reverb(drive(x, 4.0), 0.6, 0.18)


def boss_roar():
    d = 2.4
    path = glide(62, 48, d) * (1 + 0.05 * np.sin(2 * np.pi * 3 * t(d)))
    x = voice(path, d, "ah", rasp=0.9, breath=0.4)
    x *= 1 + 0.5 * np.sin(2 * np.pi * 28 * t(d))  # growl
    x = lp(x, 2500) * env_adsr(d, 0.15, 0.4, 0.8, 0.9)
    x += osc(path * 0.5, d) * env_adsr(d, 0.2, 0.4, 0.8, 0.9) * 0.4
    return reverb(drive(x, 3.0), 2.0, 0.3, 1800)


def player_grunt(seed):
    r = np.random.default_rng(seed)
    d = 0.35
    x = voice(glide(170 + 20 * r.random(), 120, d), d, "uh", rasp=0.15, jitter=0.02, breath=0.1)
    return x * env_exp(d, 0.1, 0.01)


def player_death():
    d = 1.6
    x = voice(glide(160, 70, d, 0.7), d, "ah", rasp=0.25, breath=0.2) * env_adsr(d, 0.03, 0.4, 0.5, 0.8)
    x = place(x, osc(glide(80, 40, 0.5), 0.5) * env_exp(0.5, 0.12), 0.9, 0.6)
    return reverb(x, 1.4, 0.3)


def footstep(seed):
    r = np.random.default_rng(seed)
    d = 0.12
    thud = lp(noise(d), 300 + 100 * r.random()) * env_exp(d, 0.02)
    grit = bp(noise(d), 1500, 5000) * env_exp(d, 0.01) * 0.25
    return thud + grit


# ── Hives ─────────────────────────────────────────────────────────────────────
def hive_scream():
    d = 1.2
    x = np.zeros(int(d * SR))
    for k in range(4):  # a chorus of shrieks out of the growth
        path = glide(rng.uniform(300, 500), rng.uniform(180, 260), d)
        v = voice(path, d, "ee", rasp=0.9, jitter=0.1, breath=0.4) * env_adsr(d, 0.05 + 0.03 * k, 0.3, 0.6, 0.5)
        x += v * rng.uniform(0.5, 1.0)
    squelch = bp(noise(d), 120, 900) * env_exp(d, 0.15)
    return reverb(drive(x + squelch, 3.0), 1.2, 0.25)


def hive_death():
    d = 1.8
    burst = bp(noise(d), 100, 1500) * env_exp(d, 0.2)
    drop = osc(glide(110, 35, d), d) * env_exp(d, 0.35)
    drips = np.zeros(int(d * SR))
    for _ in range(18):
        place(drips, osc(rng.uniform(300, 900), 0.06) * env_exp(0.06, 0.015), rng.uniform(0.2, 1.4), rng.uniform(0.1, 0.3))
    x = burst * 1.0 + drop * 0.9 + drips
    x = place(x, hive_scream(), 0.0, 0.3)
    return reverb(drive(x, 2.0), 1.4, 0.25)


def hive_pulse_loop():
    d = 2.0
    x = np.zeros(int(d * SR))
    for at in (0.0, 0.28):  # lub-dub
        beat = osc(glide(70, 45, 0.25), 0.25) * env_exp(0.25, 0.08) + bp(noise(0.25), 80, 400) * env_exp(0.25, 0.05) * 0.6
        place(x, beat, at, 1.0 if at == 0 else 0.7)
    x += lp(noise(d), 200) * 0.08
    return x


# ── Pickups, UI, stingers ─────────────────────────────────────────────────────
def note(freq, d, shape="tri", dec=0.15):
    return osc(freq, d, shape) * env_exp(d, dec, 0.004)


def arp(freqs, step, d_note, shape="tri", dec=0.18, gain=1.0):
    total = step * (len(freqs) - 1) + d_note
    buf = np.zeros(int(total * SR) + 1)
    for i, f in enumerate(freqs):
        place(buf, note(f, d_note, shape, dec) + note(f * 2, d_note, "sine", dec * 0.6) * 0.3, i * step, gain)
    return buf


def ui_click():
    d = 0.05
    return osc(1300, d) * env_exp(d, 0.008, 0.0005) + hp(noise(d), 3000) * env_exp(d, 0.002) * 0.3


def stinger_complete():
    chord = [261.6, 329.6, 392.0, 523.3]
    d = 2.6
    x = np.zeros(int(d * SR))
    place(x, arp([392.0, 523.3, 659.3, 784.0], 0.09, 0.5, "tri", 0.25), 0.0, 0.7)
    for f in chord:
        place(x, (osc(f, 2.2, "saw") * 0.3 + osc(f * 1.003, 2.2, "saw") * 0.3) * env_adsr(2.2, 0.15, 0.4, 0.6, 1.2), 0.35, 0.35)
    return reverb(lp(x, 4000), 1.8, 0.3)


def stinger_failed():
    d = 2.8
    x = np.zeros(int(d * SR))
    for i, f in enumerate([220.0, 207.7, 196.0, 164.8]):
        place(x, (osc(f, 1.0, "saw") + osc(f * 0.5, 1.0)) * env_adsr(1.0, 0.05, 0.3, 0.5, 0.5), i * 0.4, 0.5)
    x = place(x, osc(glide(80, 40, 1.4), 1.4) * env_exp(1.4, 0.5), 1.2, 0.6)
    return reverb(lp(x, 2200), 2.0, 0.35)


def heli_loop():
    d = 2.0
    rate = 11.0  # blade thumps per second
    x = t(d)
    am = 0.5 + 0.5 * np.maximum(np.sin(2 * np.pi * rate * x), 0) ** 3
    body = lp(noise(d), 350) * am
    whine = osc(820, d) * 0.05 + osc(1640, d) * 0.02
    return (body + whine) * 0.9


def main():
    for i in range(3):
        save("gun_fire" + ("" if i == 0 else "_%d" % (i + 1)), gunshot(10 + i))
    save("gun_reload", reload_sound())
    save("rocket_fire", rocket_fire())
    save("rocket_explode", explosion(1.0))
    for i in range(3):
        save("bullet_impact_flesh" + ("" if i == 0 else "_%d" % (i + 1)), flesh(20 + i))
    for i in range(2):
        save("bullet_impact_wall" + ("" if i == 0 else "_%d" % (i + 1)), wall_hit(30 + i))
    save("shell_casing_drop", casing())
    save("molotov_throw", whoosh())
    save("molotov_shatter", shatter())
    save("fire_loop", fire_loop(), do_trim=False)
    for i in range(4):
        save("zombie_groan" + ("" if i == 0 else "_%d" % (i + 1)), groan(40 + i))
    for i in range(2):
        save("zombie_hit" + ("" if i == 0 else "_%d" % (i + 1)), zombie_hit(50 + i))
    for i in range(3):
        save("zombie_death" + ("" if i == 0 else "_%d" % (i + 1)), zombie_death(60 + i))
    for i in range(2):
        save("zombie_runner_scream" + ("" if i == 0 else "_%d" % (i + 1)), runner_scream(70 + i))
    save("boss_roar", boss_roar())
    save("hive_scream", hive_scream())
    save("hive_death", hive_death())
    save("hive_pulse_loop", hive_pulse_loop(), do_trim=False)
    for i in range(3):
        save("player_footstep" + ("" if i == 0 else "_%d" % (i + 1)), footstep(80 + i), peak=0.5)
    for i in range(2):
        save("player_hurt" + ("" if i == 0 else "_%d" % (i + 1)), player_grunt(90 + i))
    save("player_death", player_death())
    save("powerup_pickup", reverb(arp([523.3, 659.3, 784.0, 1046.5], 0.07, 0.3), 0.8, 0.2))
    save("intel_pickup", reverb(arp([880.0, 1318.5], 0.1, 0.35, "sine", 0.2), 0.7, 0.2))
    rise = drive(sweep_filter(osc(glide(110, 440, 0.9), 0.9, "saw"), 300, 6000) * env_adsr(0.9, 0.05, 0.2, 0.8, 0.3), 1.5)
    save("hyper_burst_activate", reverb(place(rise, arp([440, 554.4, 659.3, 880], 0.08, 0.4, "square", 0.12), 0.0, 0.4), 0.9, 0.2))
    save("ui_click", ui_click(), peak=0.6)
    save("ui_confirm", arp([659.3, 987.8], 0.06, 0.18, "tri", 0.08), peak=0.7)
    save("ui_back", arp([659.3, 493.9], 0.06, 0.18, "tri", 0.08), peak=0.7)
    save("objective_complete", reverb(arp([523.3, 659.3, 784.0], 0.1, 0.5, "tri", 0.3), 1.0, 0.25))
    save("level_up", reverb(arp([392.0, 523.3, 659.3, 784.0, 1046.5], 0.08, 0.6, "square", 0.25, 0.6), 1.2, 0.3))
    save("mission_complete", stinger_complete())
    save("mission_failed", stinger_failed())
    save("extraction_countdown", note(880.0, 0.14, "sine", 0.05), peak=0.6)
    save("heli_loop", heli_loop(), do_trim=False)
    print("made %d sounds into %s" % (len(made), os.path.normpath(OUT)))


if __name__ == "__main__":
    main()
