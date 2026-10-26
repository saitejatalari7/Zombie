# Protocol: Crimson audio

All music and sound effects are synthesized from code: no samples, no third-party
recordings, so there is nothing to license or credit.

    pip install numpy scipy        # ffmpeg (with libvorbis) must be on PATH
    python3 tools/audio/make_sfx.py     # -> assets/audio/sfx/*.ogg   (48 files)
    python3 tools/audio/make_music.py   # -> assets/audio/music/*.ogg (6 loops)

`dsp.py` is the small synth kit both scripts share: oscillators, filters, envelopes,
formant voices, a synthetic reverb and the OGG writer.

## How the game uses them

`scripts/audio_manager.gd` (autoload) owns playback:

- `sfx_registry` maps a name to `assets/audio/sfx/<name>.ogg`. Extra takes named
  `<name>_2.ogg` … `<name>_5.ogg` are found automatically and picked at random.
- `play_sfx_near(name, pos, db, min_gap)` plays a world sound faded by its distance to
  the player (the camera is ~40 m up, so 3D attenuation would make everything distant).
- `play_sfx_throttled` keeps full-auto fire and mass deaths from stacking into noise.
- `attach_loop(node, name)` gives fires, hives and the evac chopper a looping voice that
  dies with them.
- `music_registry`: `menu` (title and hub), `sector1`–`sector4` (each sector's theme) and
  `boss` (hunt and defend steps, and holding the LZ). Tracks loop seamlessly.
- A hard limiter on the Master bus; Master, Music and Effects volumes live in Settings.

## Replacing a sound

Drop any CC0 or self-made `.ogg` into `assets/audio/sfx/` or `assets/audio/music/` with
the same file name and it is used instead; no code changes needed.
