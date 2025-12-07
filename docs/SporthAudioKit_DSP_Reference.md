# SporthAudioKit DSP Reference

This document provides a reference for SporthAudioKit operations used in the Digitakt AUv3 voice engine.

## Overview

SporthAudioKit is an AudioKit extension providing Sporth (stack-based audio language) functionality. It enables compact, sample-accurate DSP with 100+ unit generators from Soundpipe.

- **Repository**: https://github.com/AudioKit/SporthAudioKit
- **Depends on**: AudioKit, SoundpipeAudioKit
- **Integration**: `OperationGenerator` (sources) and `OperationEffect` (processors)

### Why Sporth for This Project?

1. **Sample-accurate processing** - Frame-level control for slicing
2. **Compact DSP chains** - Complex routing in minimal code
3. **Full modulation** - Any parameter can modulate any other
4. **Elektron-style P-Locks** - Per-step parameter snapshots via indexed parameters

---

## Sample Playback

### Frame-Accurate Playback with phasor + tabread

Load samples into f-tables, use phasor for phase control:

```sporth
# Load sample, play at original speed
"sample" 0 "path/to/file.wav" loadwav
"sample" 1 sr / phasor tabread
```

**Key Operations:**
| Operation | Description |
|-----------|-------------|
| `loadwav` | Load WAV file into named table |
| `phasor` | Generates 0-1 ramp at specified frequency |
| `tabread` | Read from table with interpolation |

**Playback Rate Calculation:**
- For 1x speed: `frequency = sampleRate / sampleLength`
- For pitched playback: multiply by pitch ratio

### Slice Playback

Scale phasor output for start/end control:

```sporth
# Play samples 10000-20000 of a 44100-sample file
"sample"
0.2268 0.4535    # start=10000/44100, end=20000/44100 (normalized)
2dup -           # duration (end - start)
1 swap / phasor  # phasor at slice rate
swap + tabread   # offset to start position
```

**Slice Formula:**
```
normalized_start = start_frame / total_frames
normalized_end = end_frame / total_frames
slice_duration = normalized_end - normalized_start
phasor_freq = 1.0 / (slice_duration * sample_duration_seconds)
```

---

## Filters

| Operation | Description | Parameters |
|-----------|-------------|------------|
| `moogladder` | Moog 4-pole resonant LP (warm, musical) | cutoff(Hz), resonance(0-1) |
| `diode` | Diode ladder LP (aggressive) | cutoff, resonance |
| `korg35` | Korg MS-20 style (screamy) | cutoff, resonance |
| `butlp` | Butterworth LP (clean) | cutoff |
| `buthp` | Butterworth HP | cutoff |
| `butbp` | Butterworth BP | center, bandwidth |

**Example:**
```sporth
1000 0.5 moogladder  # 1kHz cutoff, 0.5 resonance
```

**Swift Operation equivalent:**
```swift
let filtered = source.moogLadderFilter(cutoff: cutoffParam, resonance: resParam)
```

---

## Envelopes

| Operation | Description | Parameters | Best For |
|-----------|-------------|------------|----------|
| `adsr` | Full ADSR | trigger, atk, dec, sus, rel | Sustained sounds |
| `tenvx` | Exponential trigger env | trigger, atk, hold, rel | Drums, percussive |
| `tenv` | Linear trigger env | trigger, atk, hold, rel | Plucks |
| `port` | Portamento/smoothing | input, time | Parameter smoothing |

**Percussive Example (tenvx):**
```sporth
0 p 0.001 0.1 0.2 tenvx  # Parameter 0 triggers, fast attack, short hold, medium release
```

**ADSR Example:**
```sporth
0 p 0.01 0.1 0.7 0.3 adsr  # trigger, 10ms attack, 100ms decay, 0.7 sustain, 300ms release
```

**Swift Operation equivalent:**
```swift
let env = Operation.trigger(triggerParam).triggeredEnvelope(
    attack: 0.001, hold: 0.1, release: 0.3
)
```

---

## LFO / Modulation

Any oscillator at sub-audio rates becomes an LFO:

```sporth
0.5 0.3 sine 1000 +  # LFO at 0.5Hz, depth 0.3, modulating 1000Hz center frequency
```

**Available Oscillators:**
- `sine` - Smooth modulation
- `saw` - Ramp up modulation
- `square` - On/off modulation
- `tri` - Triangle modulation
- `phasor` - 0-1 ramp (useful for sequencing)

**Modulation Depth Control:**
```sporth
# LFO with adjustable depth
1 p sine     # LFO output (-1 to 1)
2 p *        # Scale by depth parameter
3 p +        # Add to center frequency
```

---

## Parameter Control

Sporth parameters accessed via index:
- `0 p` - Parameter 0
- `1 p` - Parameter 1
- Up to ~14 parameters in OperationGenerator

### Swift Integration

```swift
let voice = OperationGenerator { parameters in
    let trigger = parameters[0]    // 0 p in Sporth
    let pitch = parameters[1]      // 1 p in Sporth
    let cutoff = parameters[2]     // 2 p in Sporth
    let resonance = parameters[3]  // 3 p in Sporth

    // Build operation chain...
    return output
}

// Set parameters at runtime
voice.parameters[0] = 1.0  // Trigger
voice.parameters[1] = 440  // Pitch
voice.parameters[2] = 2000 // Cutoff
```

### Parameter Conventions for Digitakt Voice

| Index | Parameter | Range | Default |
|-------|-----------|-------|---------|
| 0 | Trigger | 0/1 | 0 |
| 1 | Playback Rate | 0.25-4.0 | 1.0 |
| 2 | Slice Start | 0.0-1.0 | 0.0 |
| 3 | Slice End | 0.0-1.0 | 1.0 |
| 4 | Filter Cutoff | 20-20000 Hz | 20000 |
| 5 | Filter Resonance | 0.0-1.0 | 0.0 |
| 6 | Amp Attack | 0.001-2.0 s | 0.001 |
| 7 | Amp Decay | 0.001-2.0 s | 0.1 |
| 8 | Amp Sustain | 0.0-1.0 | 1.0 |
| 9 | Amp Release | 0.001-5.0 s | 0.3 |
| 10 | Volume | 0.0-1.0 | 1.0 |

---

## Voice Architecture Patterns

### Single Voice Structure

```
[Trigger] ──────────────────────────────┐
                                        ▼
[Sample Table] → [Phasor] → [TabRead] → [Filter] → [× Envelope] → [× Volume] → [Output]
                    ▲            ▲          ▲
              [Pitch/Rate]  [Slice Pos] [Cutoff/Res]
```

### Swift Voice Pool Pattern

```swift
class VoicePool {
    var voices: [OperationGenerator]
    var activeVoices: [Int: Int]  // note -> voice index

    func noteOn(note: Int, velocity: Int) {
        guard let voiceIndex = findFreeVoice() else { return }
        let voice = voices[voiceIndex]

        voice.parameters[0] = 1.0  // trigger
        voice.parameters[1] = midiNoteToRate(note)
        voice.parameters[10] = Float(velocity) / 127.0

        activeVoices[note] = voiceIndex
    }

    func noteOff(note: Int) {
        guard let voiceIndex = activeVoices[note] else { return }
        voices[voiceIndex].parameters[0] = 0.0  // release
        activeVoices.removeValue(forKey: note)
    }

    private func findFreeVoice() -> Int? {
        // Find voice not in activeVoices
        for i in 0..<voices.count {
            if !activeVoices.values.contains(i) {
                return i
            }
        }
        // Voice stealing: return oldest
        return activeVoices.first?.value
    }
}
```

---

## Common Sporth Patterns

### Basic Sampler Voice

```sporth
# p0=trigger, p1=rate, p2=cutoff, p3=res, p4=volume
0 p 0.001 0.1 0.3 tenvx   # Envelope from trigger
"sample" 1 p phasor tabread  # Sample playback at rate
2 p 3 p moogladder        # Filter
*                         # Apply envelope
4 p *                     # Apply volume
```

### Voice with Slice Control

```sporth
# p0=trigger, p1=rate, p2=slice_start, p3=slice_end, p4=cutoff, p5=res
0 p 0.001 0.05 0.2 tenvx           # Envelope
"sample"
3 p 2 p - dup 0.001 max            # slice_duration = end - start (min 0.001)
1 p * 1 swap / phasor              # phasor at (rate / duration)
2 p + tabread                      # offset to slice start
4 p 5 p moogladder                 # Filter
*                                  # Apply envelope
```

### Full Voice with ADSR

```sporth
# p0=trigger, p1=rate, p2=cutoff, p3=res, p4=atk, p5=dec, p6=sus, p7=rel, p8=vol
0 p 4 p 5 p 6 p 7 p adsr          # Full ADSR envelope
"sample" 1 p phasor tabread        # Sample playback
2 p 3 p moogladder                 # Filter
*                                  # Apply envelope
8 p *                              # Apply volume
```

---

## Swift Operation API Quick Reference

### Creating Operations

```swift
// Oscillators
Operation.sineWave(frequency: freqParam)
Operation.sawtoothWave(frequency: freqParam)
Operation.squareWave(frequency: freqParam)

// Sample playback
Operation.phasor(frequency: rateParam)
    .tabread(table, withOffset: startParam)

// Filters
source.moogLadderFilter(cutoff: cutoffParam, resonance: resParam)
source.lowPassFilter(cutoff: cutoffParam)

// Envelopes
Operation.trigger(triggerParam)
    .triggeredEnvelope(attack: 0.001, hold: 0.1, release: 0.3)

// Math
operationA * operationB
operationA + operationB
operation.scaled(by: factor)
```

### OperationGenerator Setup

```swift
let generator = OperationGenerator { parameters in
    // parameters[0], parameters[1], etc.
    let output: Operation = // ... build chain
    return output
}

engine.output = generator
try engine.start()
generator.start()
```

---

## Debugging Tips

1. **No sound?** Check that:
   - `generator.start()` was called after `engine.start()`
   - Trigger parameter is being set to 1.0 then back to 0.0
   - Sample table loaded successfully

2. **Clicks/pops?**
   - Increase envelope attack time (minimum 0.001s)
   - Ensure sample plays from zero-crossing point
   - Check for discontinuities in slice boundaries

3. **Wrong pitch?**
   - Verify phasor frequency calculation
   - Check sample rate matches expected (usually 44100 or 48000)

---

## Sources

- [SporthAudioKit GitHub](https://github.com/AudioKit/SporthAudioKit)
- [Sporth Documentation](https://paulbatchelor.github.io/proj/sporth.html)
- [Soundpipe Reference](https://paulbatchelor.github.io/res/soundpipe/docs/)
- [Sporth F-Tables](https://pbat.ch/proj/cook/ftables.html)
- [AudioKit Operations](https://audiokit.io/SporthAudioKit/documentation/sporthaudiokit/)
