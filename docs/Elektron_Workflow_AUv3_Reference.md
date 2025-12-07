# Elektron Workflow Reference for AUv3 Development

This document summarizes key features from the Digitakt II and Tonverk manuals relevant for creating an AUv3 instrument that captures the Elektron workflow.

## Core Sequencer Concepts

### Pattern Structure
- **128 patterns** per project (8 banks x 16 patterns)
- **Up to 128 steps** (Digitakt II: 8 pages x 16) or **256 steps** (Tonverk: 16 pages x 16)
- Each pattern contains: presets, sequencer data (trigs, parameter locks), tempo, swing, length settings

### Tracks
- **Digitakt II**: 16 tracks (can be audio or MIDI)
- **Tonverk**: 8 audio tracks, 4 bus tracks, 3 send FX tracks, 1 mix track
- Each audio track: sample + SRC/FLTR/AMP/FX/MOD parameter pages

### Trig Types
1. **Note Trigs** - Trigger sounds (red keys)
2. **Lock Trigs** - Trigger parameter changes only, no sound (yellow keys)

---

## Recording Modes

### Grid Recording Mode
- Press [RECORD] to enter
- Use [TRIG] keys to place/remove trigs
- [FUNC] + [TRIG] adds lock trigs
- Direct step-based editing
- Parameter locks added by holding [TRIG] + turning knobs

### Live Recording Mode
- [RECORD] + [PLAY] to enter
- Real-time recording of [TRIG] key presses
- Keyboard mode for chromatic input
- Parameter changes recorded as p-locks automatically
- Optional auto-quantization (double-tap [PLAY] while holding [RECORD])

### Step Recording Mode (Digitakt II)
- [RECORD] + [STOP] to enter
- Add note, auto-advance to next step
- JUMP mode: LEN parameter controls step advance distance

---

## Parameter Locks (P-Locks)

**The signature Elektron feature** - Per-step parameter automation.

### How They Work
- Hold a [TRIG] key + turn any parameter knob
- Parameter display inverts to show locked value
- Blinking trig key indicates p-locks present
- **Up to 80 different parameters** can be locked per pattern
- A parameter counts as 1 locked parameter regardless of how many trigs lock it

### Adding P-Locks
1. **Grid Recording**: Hold [TRIG] + turn DATA ENTRY knob
2. **Live Recording**: Turn knobs while playing - auto-adds lock trigs
3. **Step Recording**: Hold [TRIG] + turn knob

### Removing P-Locks
- Hold [TRIG] + press the DATA ENTRY knob (removes single p-lock)
- Remove trig and re-enter (removes all p-locks)
- Live: Hold [NO] + press knob to remove in real-time

---

## Trig Conditions (Conditional Locks)

Logical rules determining if a trig plays. Set via COND parameter on TRIG page.

### Probability
- **X%** - Percentage chance (1%-99%)

### Pattern Position
- **1ST** - Plays first loop only
- **!1ST** - Doesn't play first loop
- **LST** - Plays last loop before pattern change
- **!LST** - Doesn't play last loop

### Cycle Conditions (A:B)
- **A:B** - Plays on Ath loop, resets every B loops
- Examples:
  - 1:2 = plays loops 1, 3, 5, 7...
  - 2:4 = plays loops 2, 6, 10...
  - 4:7 = plays loops 4, 11, 18...
- **!A:B** - Inverse (plays when A:B would NOT play)

### Neighbor/Previous Conditions
- **PRE** - Plays if previous conditional trig on same track played
- **!PRE** - Plays if previous conditional trig did NOT play
- **NEI** - Plays if most recent conditional trig on neighbor track played
- **!NEI** - Inverse of NEI

### Fill Conditions
- **FILL** - Plays only when FILL mode active
- **!FILL** - Plays only when FILL mode NOT active

---

## Fill Mode

Temporary pattern variation (drum fills, transitions).

### Activation
- **[YES] + [PAGE]** - Active for one full pattern cycle
- **Hold [PAGE]** - Active while held
- **[PAGE] + [YES] (hold), release [PAGE]** - Latched until [PAGE] pressed again

---

## Micro Timing

Per-step timing offset (ahead or behind the beat).

- Hold [TRIG] + press [LEFT]/[RIGHT] to access
- Moves notes off-grid for groove/swing
- Settings stored per pattern

---

## Retrigs

Rapid re-triggering within a single step.

- Access via TRIG PAGE 2
- Rates: 1/1, 1/2, 1/3, 1/4, 1/5, 1/6, 1/8, 1/12, 1/16, 1/20, 1/24, 1/32, 1/40, 1/48, 1/64, 1/80
- Additional parameters: velocity curve, length

---

## Page Setup / Track Length

### Per Pattern Mode
- All tracks share same length/speed

### Per Track Mode (Polyrhythm)
- Each track can have different length
- Each track can have different speed multiplier
- Speed options: 1/8X, 1/4X, 1/2X, 3/4X, 1X, 3/2X, 2X
- **CHANGE** - Steps before pattern change
- **RESET** - Steps before all tracks restart (INF = never)

---

## Euclidean Sequencer (Digitakt II)

Algorithmic trig generation.

- **PL1/PL2** - Pulse generators (number of trigs)
- **R01/R02** - Rotation per generator
- **TRO** - Track rotation (both generators)
- **OP** - Boolean operator:
  - OR: all trigs from both
  - XOR: trigs unless both on same step
  - AND: only where both generators place trig
  - SUB: PL1 trigs minus PL2 overlaps

---

## Sample/Sound Architecture

### Signal Flow (per track)
```
SAMPLE/SRC → FILTER → AMP → FX → OUTPUT
                ↑
               LFO/MOD
```

### Parameter Pages
1. **TRIG** - Note, velocity, length, conditions, retrigs
2. **SRC** - Sample selection, playback mode, tune, start/end points
3. **FLTR** - Filter type, cutoff, resonance, envelope
4. **AMP** - Volume, pan, amp envelope (ADSR)
5. **FX** - Bit reduction, overdrive, sample rate reduction, sends
6. **MOD** - LFO settings (speed, depth, destination, shape)

### Sample Parameters (SRC Page)
- **TUNE** - Pitch (+/- semitones)
- **FINE** - Fine tuning (cents)
- **SAMP** - Sample selection
- **STRT** - Sample start point
- **END** - Sample end point
- **LOOP** - Loop on/off
- **LPOS** - Loop position

---

## Keyboard Mode

Chromatic playing of samples/sounds.

- Enter with [KEYBOARD] key
- [TRIG] keys become piano-like layout
- [UP]/[DOWN] transpose octaves
- Root note and scale selection
- KB FOLD: All keys play notes (wraps scale)
- Notes recordable in Live Recording mode

### Chord/Scale Setup
- Scale selection (chromatic, major, minor, modes, etc.)
- Root note
- Chord mode (auto-add harmony notes)
- Guide modes: OFF, LIGHT, SNAP, FILTER

---

## Mute Mode

Track muting for live performance.

### Digitakt II
- **Global Mute** - Mutes across all patterns
- **Pattern Mute** - Mutes only in active pattern
- Quick Mute: [FUNC] + [TRIG]

### Tonverk
- Single mute mode
- [MUTE] + [TRIG] for quick mute

---

## Preset/Sound Management

### Preset Pool
- Quick-access collection of sounds
- Required for **preset locks** (sound changes per step)
- Up to 128 presets in pool

### Preset Locks
- Hold [TRIG] + turn LEVEL/DATA to select preset
- Different sound per step on same track
- Massive sound design possibilities

---

## Pattern Chains

Sequences of patterns for arrangement.

- Create by holding pattern keys in sequence
- Up to 64 patterns in chain
- Lost on power-off (not saved)

---

## Song Mode

Full arrangement capability.

- Up to 16 songs per project
- Up to 99 rows per song
- Per-row settings: pattern, repeat count, length, tempo, mutes
- Loop or stop at end

---

## Key UI/UX Principles for AUv3

### 8 Knobs Paradigm
- 8 parameters visible at once
- Direct 1:1 knob-to-parameter mapping
- Parameter pages (TRIG/SRC/FLTR/AMP/FX/MOD) switch which 8

### 16 Trig Keys
- Visual feedback: red=note, yellow=lock, off=empty, blinking=p-locks
- Multi-function based on mode (trigs, keyboard, mutes, track select)

### Screen Information
- Current bank/pattern
- Pattern name
- Tempo
- Active track
- 8 parameter values with labels
- Page indicator

### Copy/Paste/Clear Pattern
- [FUNC] + [RECORD] = Copy
- [FUNC] + [STOP] = Paste
- [FUNC] + [PLAY] = Clear
- Works on: patterns, tracks, pages, trigs

### Temporary Save/Reload
- Quick save state for live performance
- Undo tweaks without permanent save

---

## AUv3 Implementation Priorities

### Essential Features
1. 16-step grid with visual trig indication
2. Parameter locks on any parameter
3. Multiple recording modes (Grid, Live)
4. Per-step conditions (at least probability + FILL)
5. Sample playback with start/end/loop
6. Filter + Amp envelope per track
7. LFO modulation

### Important Features
1. Micro timing
2. Retrigs
3. Pattern chains
4. Track mutes
5. Preset locks
6. Keyboard/chromatic mode
7. Scale/chord helpers

### Nice to Have
1. Euclidean generator
2. Song mode
3. Full trig conditions (PRE, NEI, A:B)
4. Per-track length/polyrhythms
5. Multiple tracks (8-16)
