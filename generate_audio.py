import wave, struct, math, random, os

SAMPLE_RATE = 44100
OUT_DIR = "assets/audio"
os.makedirs(OUT_DIR, exist_ok=True)

def write_wav(filename, frames, rate=SAMPLE_RATE):
    path = os.path.join(OUT_DIR, filename)
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(b''.join(struct.pack('<h', max(-32767, min(32767, int(s)))) for s in frames))
    print(f"  ✓ {filename}")

def sine(freq, t, amp=1.0):
    return amp * math.sin(2 * math.pi * freq * t)

def noise(amp=1.0):
    return amp * (random.random() * 2 - 1)

def adsr(t, dur, attack=0.05, decay=0.1, sustain=0.7, release=0.15):
    if t < attack:
        return t / attack
    elif t < attack + decay:
        return 1.0 - (1.0 - sustain) * (t - attack) / decay
    elif t < dur - release:
        return sustain
    else:
        return sustain * max(0, (dur - t) / release)

# ── 1. engine_idle.mp3 (saved as .mp3 name but WAV data — audioplayers handles it)
# Low rumble loop: layered low-freq sine + noise
print("Generating engine_idle...")
dur = 2.0
frames = []
for i in range(int(SAMPLE_RATE * dur)):
    t = i / SAMPLE_RATE
    s  = sine(55,  t, 0.35)   # fundamental
    s += sine(110, t, 0.20)   # 2nd harmonic
    s += sine(165, t, 0.10)   # 3rd harmonic
    s += noise(0.04)           # texture
    # Slight tremolo
    s *= 0.85 + 0.15 * math.sin(2 * math.pi * 8 * t)
    frames.append(s * 32767)
write_wav("engine_idle.mp3", frames)

# ── 2. skid.mp3 — white noise burst with pitch drop
print("Generating skid...")
dur = 0.8
frames = []
for i in range(int(SAMPLE_RATE * dur)):
    t = i / SAMPLE_RATE
    env = adsr(t, dur, 0.01, 0.05, 0.6, 0.3)
    s = noise(0.9) * env
    # Add a slight screech tone
    s += sine(800 - 400 * (t / dur), t, 0.15) * env
    frames.append(s * 32767)
write_wav("skid.mp3", frames)

# ── 3. collision_hard.mp3 — sharp impact thud
print("Generating collision_hard...")
dur = 0.6
frames = []
for i in range(int(SAMPLE_RATE * dur)):
    t = i / SAMPLE_RATE
    env = math.exp(-t * 12)
    s  = sine(80,  t, 0.5) * env
    s += sine(120, t, 0.3) * env
    s += noise(0.6) * math.exp(-t * 20)
    frames.append(s * 32767)
write_wav("collision_hard.mp3", frames)

# ── 4. collision_soft.mp3 — soft bump
print("Generating collision_soft...")
dur = 0.4
frames = []
for i in range(int(SAMPLE_RATE * dur)):
    t = i / SAMPLE_RATE
    env = math.exp(-t * 18)
    s  = sine(120, t, 0.4) * env
    s += noise(0.3) * math.exp(-t * 25)
    frames.append(s * 32767)
write_wav("collision_soft.mp3", frames)

# ── 5. cone_hit.mp3 — plastic knock
print("Generating cone_hit...")
dur = 0.35
frames = []
for i in range(int(SAMPLE_RATE * dur)):
    t = i / SAMPLE_RATE
    env = math.exp(-t * 22)
    s  = sine(400, t, 0.5) * env
    s += sine(800, t, 0.2) * env
    s += noise(0.2) * math.exp(-t * 30)
    frames.append(s * 32767)
write_wav("cone_hit.mp3", frames)

# ── 6. park_success.mp3 — happy ascending chime
print("Generating park_success...")
notes = [523, 659, 784, 1047]  # C5 E5 G5 C6
dur_per = 0.18
frames = []
for note in notes:
    for i in range(int(SAMPLE_RATE * dur_per)):
        t = i / SAMPLE_RATE
        env = adsr(t, dur_per, 0.01, 0.04, 0.7, 0.08)
        s  = sine(note,     t, 0.5) * env
        s += sine(note * 2, t, 0.15) * env
        frames.append(s * 32767)
# Final long chord
chord = [523, 659, 784]
for i in range(int(SAMPLE_RATE * 0.6)):
    t = i / SAMPLE_RATE
    env = adsr(t, 0.6, 0.01, 0.05, 0.7, 0.25)
    s = sum(sine(n, t, 0.3) for n in chord) * env
    frames.append(s * 32767)
write_wav("park_success.mp3", frames)

# ── 7. gear_shift.mp3 — mechanical click
print("Generating gear_shift...")
dur = 0.15
frames = []
for i in range(int(SAMPLE_RATE * dur)):
    t = i / SAMPLE_RATE
    env = math.exp(-t * 40)
    s  = sine(300, t, 0.4) * env
    s += noise(0.5) * math.exp(-t * 50)
    frames.append(s * 32767)
write_wav("gear_shift.mp3", frames)

# ── 8. countdown.mp3 — 3 beeps (low low HIGH)
print("Generating countdown...")
frames = []
beeps = [(440, 0.12), (440, 0.12), (880, 0.25)]
gap = int(SAMPLE_RATE * 0.55)
for freq, bdur in beeps:
    for i in range(int(SAMPLE_RATE * bdur)):
        t = i / SAMPLE_RATE
        env = adsr(t, bdur, 0.005, 0.02, 0.8, 0.05)
        s = sine(freq, t, 0.7) * env
        frames.append(s * 32767)
    frames.extend([0] * gap)
write_wav("countdown.mp3", frames)

# ── 9. music_menu.mp3 — cheerful looping melody (kids-friendly)
print("Generating music_menu...")
BPM = 120
beat = 60 / BPM
# Simple C major pentatonic melody
melody = [
    (523, 1), (659, 1), (784, 1), (880, 2),
    (784, 1), (659, 1), (523, 2),
    (659, 1), (784, 1), (880, 1), (1047, 2),
    (880, 1), (784, 1), (659, 4),
]
bass = [262, 330, 392, 330]  # C4 E4 G4 E4 loop
frames = []
bass_i = 0
t_global = 0.0
for freq, beats in melody:
    dur = beats * beat
    n = int(SAMPLE_RATE * dur)
    for i in range(n):
        t = i / SAMPLE_RATE
        env = adsr(t, dur, 0.01, 0.05, 0.75, 0.1)
        # Melody
        s  = sine(freq,     t, 0.35) * env
        s += sine(freq * 2, t, 0.08) * env
        # Bass (quarter notes)
        bi = int(t_global / beat) % len(bass)
        bt = t_global % beat
        benv = adsr(bt, beat, 0.01, 0.05, 0.6, 0.1)
        s += sine(bass[bi], t, 0.25) * benv
        # Hi-hat on every beat
        if bt < 0.04:
            s += noise(0.06) * math.exp(-bt * 80)
        frames.append(s * 32767)
        t_global += 1 / SAMPLE_RATE
write_wav("music_menu.mp3", frames)

# ── 10. music_game.mp3 — upbeat driving loop
print("Generating music_game...")
BPM = 140
beat = 60 / BPM
drive_melody = [
    (784, 1), (880, 1), (784, 1), (659, 1),
    (698, 2), (784, 2),
    (880, 1), (988, 1), (880, 1), (784, 1),
    (698, 4),
    (784, 1), (659, 1), (523, 2),
    (587, 1), (659, 1), (698, 2),
    (784, 4),
]
drive_bass = [196, 220, 247, 220]
frames = []
t_global = 0.0
for freq, beats in drive_melody:
    dur = beats * beat
    n = int(SAMPLE_RATE * dur)
    for i in range(n):
        t = i / SAMPLE_RATE
        env = adsr(t, dur, 0.005, 0.04, 0.8, 0.08)
        s  = sine(freq,     t, 0.30) * env
        s += sine(freq * 2, t, 0.10) * env
        # Bass
        bi = int(t_global / beat) % len(drive_bass)
        bt = t_global % beat
        benv = adsr(bt, beat, 0.005, 0.04, 0.65, 0.08)
        s += sine(drive_bass[bi], t, 0.30) * benv
        # Kick on beats 1 & 3
        bar_pos = t_global % (beat * 4)
        if bar_pos < 0.04 or abs(bar_pos - beat * 2) < 0.04:
            s += sine(60, bar_pos % 0.04, 0.5) * math.exp(-(bar_pos % 0.04) * 60)
        # Snare on beats 2 & 4
        if abs(bar_pos - beat) < 0.04 or abs(bar_pos - beat * 3) < 0.04:
            sp = bar_pos % beat
            s += noise(0.35) * math.exp(-sp * 40)
        frames.append(s * 32767)
        t_global += 1 / SAMPLE_RATE
write_wav("music_game.mp3", frames)

print("\n✅ All 10 audio files generated in assets/audio/")
