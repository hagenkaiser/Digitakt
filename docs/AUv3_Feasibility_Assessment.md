# AUv3 Feasibility Assessment: Digitakt-Style Instrument

## Executive Summary: FEASIBLE BUT COMPLEX

This is a **highly ambitious but achievable** project. The Digitakt workflow is sophisticated, but the core concepts map well to modern iOS audio architecture.

**Complexity**: High - requires custom audio engine, sequencer, and UI

### Critical Success Factors
- **Strong points**: AudioKit 5 + AVAudioEngine provide solid foundation
- **Parameter locks**: Achievable with smart data structures
- **Sample playback**: Well-supported on iOS
- **Challenge**: Host sync + parameter lock coordination
- **Challenge**: UI complexity (40% of the work)
- **Risk**: CPU budget on older iPads with 8 simultaneous tracks + effects

---

## 1. Technical Feasibility: VIABLE

### What works in your favor:
- iOS is excellent for audio (Core Audio is rock-solid)
- AUv3 supports MIDI and audio generation perfectly for this use case
- Sample playback is efficient on modern iOS devices
- Parameter automation is native to AUv3
- SwiftUI can handle the UI (though custom controls needed)

### What's challenging:
- **Parameter lock system**: No built-in framework support—architect from scratch
- **Host sync reliability**: AUv3 timing can be tricky across different hosts
- **CPU budget**: 8 tracks × (sample playback + filter + envelope + effects) pushes iPad limits
- **State management**: Complex sequencer state + parameter locks = sophisticated data model
- **UI/UX complexity**: The Digitakt interface is deceptively complex

### Scope Reality Check

**As a SINGLE AUv3 plugin**: Recommended
**Why**: Splitting sequencer + sound engine creates sync nightmares. Keep it monolithic.

**Target devices**:
- Primary: iPad Pro (M1/M2) or iPad Air (M1+)
- Minimum: iPad Air 3 (A12) with reduced polyphony
- iPhone: Possible but UI will be cramped

**Voice budget estimate**:
- Conservative: 16-24 voices simultaneous (8 tracks × 2-3 retrigs)
- Aggressive: 32 voices on M1+ iPads
- Each voice: sample player + filter + envelope + 1-2 LFOs

---

## 2. Recommended Architecture

### High-Level Signal Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SEQUENCER ENGINE                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Master Clock (internal or host-synced)              │  │
│  │         ↓                                             │  │
│  │  Track 1-8 Step Processors (parameter lock resolver) │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           ↓ (MIDI-like events)
┌─────────────────────────────────────────────────────────────┐
│                    AUDIO ENGINE (per track)                 │
│                                                              │
│  [Voice Pool] → [Sample Player] → [Filter] → [Amp Env]     │
│       ↑              ↑                ↑          ↑           │
│       │          [LFO Module]────────┴──────────┘           │
│       │                                                      │
│  [Voice Allocator] ← Trig events + p-lock data             │
│                                                              │
│       ↓                                                      │
│  [Track Mixer] → [Send FX Bus] → [Master Out]              │
└─────────────────────────────────────────────────────────────┘
```

### Module Breakdown

#### Module 1: Sequencer Engine (NOT in audio thread)
```
SequencerClock
  ├── Maintains timeline (steps, subdivisions)
  ├── Host sync or internal tempo
  └── Fires step events at precise timing

TrackSequencer (×8)
  ├── Pattern storage (step data + parameter locks)
  ├── Trig condition evaluation (probability, fills, cycle)
  ├── Parameter lock resolution (per step)
  └── Outputs: NoteEvent(velocity, parameterSnapshot)

ParameterLockResolver
  ├── Merges base track parameters + step overrides
  └── Outputs: ParameterSnapshot for each trig
```

#### Module 2: Audio Engine (real-time safe)
```
Conductor (owns AudioEngine)
  └── TrackVoice[8]
        ├── Voice (dynamic allocation, no artificial limits)
        │     ├── AVAudioPlayerNode (with scheduleSegment for slicing)
        │     ├── LowPassFilter (AudioKit)
        │     ├── AmplitudeEnvelope (AudioKit)
        │     └── LFO → modulation router
        │
        ├── SlicedSample (metadata for slice boundaries)
        │     ├── Zero-crossing detector
        │     └── SliceDefinition[] (start/end frames)
        │
        ├── TrackEffects (bit crusher, overdrive, decimator)
        ├── SendFX routing (to global reverb/delay)
        └── TrackMixer
```

#### Module 3: Effects Chain
```
MasterEffects
  ├── Delay (send-based, global)
  ├── Reverb (send-based, global)
  ├── Chorus (send-based, global)
  └── MasterCompressor (optional)
```

---

## 3. Critical Architectural Decisions

### Decision 1: Parameter Lock Storage

**Problem**: 8 tracks × 128 steps × ~80 parameters = potential 81,920 values

**Solution**: Sparse storage with delta encoding

```swift
// DON'T store every parameter for every step
struct Step {
    let index: Int
    var trigActive: Bool
    var locks: [ParameterID: Float]? // nil if no locks on this step
}

struct Track {
    var baseParameters: [ParameterID: Float] // Default values
    var steps: [Step] // Only stores CHANGED parameters per step
}

// At playback time:
func resolveParameters(track: Track, stepIndex: Int) -> [ParameterID: Float] {
    var params = track.baseParameters
    if let locks = track.steps[stepIndex].locks {
        params.merge(locks) { _, new in new } // Locks override base
    }
    return params
}
```

**Memory estimate**:
- Base parameters: 8 tracks × 80 params × 4 bytes = 2.5 KB
- Locked steps (assume 20% steps have ~5 locks): 8 × 128 × 0.2 × 5 × 4 = ~4 KB
- **Total: ~10 KB** (vs 320 KB for dense storage)

### Decision 2: Sequencer Timing Architecture

**Challenge**: AUv3 must sync to host OR run standalone

**Solution**: Dual-mode clock with sample-accurate scheduling

```swift
protocol ClockSource {
    func currentBeat() -> Double
    func scheduleTrigger(at beat: Double, handler: @escaping () -> Void)
}

class HostSyncClock: ClockSource {
    // Uses AUHostMusicalContextBlock for DAW sync
}

class InternalClock: ClockSource {
    // Uses AVAudioEngine timeline for standalone mode
}
```

**Key insight**: Schedule triggers slightly ahead (10-20ms lookahead), then send sample-accurate events to audio thread.

### Decision 3: Voice Management

**Problem**: Need to handle retrigs and polyphonic playback

**Solution**: Dynamic voice allocation (no artificial limits)

```swift
class TrackVoice {
    var activeVoices: [Voice] = []

    func triggerNote(sample: SlicedSample, sliceIndex: Int, parameters: ParameterSnapshot) {
        let voice = Voice()
        voice.trigger(
            sample: sample.audioFile,
            startFrame: sample.slices[sliceIndex].startFrame,
            frameCount: sample.slices[sliceIndex].frameCount,
            parameters: parameters
        )
        activeVoices.append(voice)
    }

    func cleanupFinishedVoices() {
        activeVoices.removeAll { $0.isFinished }
    }
}
```

Modern iOS devices have ample resources - no need for artificial voice limits.

### Decision 4: Real-Time Safety for Parameter Application

**Solution**: Lock-free circular buffer between sequencer and audio threads

```swift
struct TrigEvent {
    let trackID: Int
    let sampleID: Int
    let parameterSnapshot: UnsafeMutablePointer<Float> // Pre-allocated
    let timestamp: UInt64 // Sample time
}

class EventQueue {
    private var ringBuffer: TPCircularBuffer // Lock-free FIFO
}
```

---

## 4. AudioKit 5 Component Mapping

| Digitakt Feature | AudioKit 5 Component | Notes |
|------------------|----------------------|-------|
| Sample playback | `AVAudioPlayerNode` | Supports pitch, loop, start/end |
| Filter | `LowPassFilter`, `HighPassFilter`, `BandPassFilter` | Resonant filters available |
| Amp envelope | Custom `ADSREnvelope` | Build using `Fader` + envelope logic |
| LFO | Custom oscillator | AudioKit's `Oscillator` for LFO source |
| Bit crusher | `Bitcrusher` | Native support |
| Overdrive | `Distortion` or `Tanh` | Multiple options |
| Decimator | `Decimator` | Sample rate reduction |
| Delay | `Delay` or `VariableDelay` | Multiple modes |
| Reverb | `CostelloReverb` or `Reverb2` | High-quality |
| Chorus | `Chorus` | Native support |
| Master mixer | `Mixer` | Built-in |

### What You'll Build Custom
1. Envelope generators (AudioKit doesn't have ADSR nodes)
2. LFO routing matrix
3. Voice allocator
4. Sequencer engine (entirely custom)

---

## 5. Technical Challenges & Mitigations

### Challenge 1: CPU Budget on iPad
**Mitigations**:
- Implement voice limiting (max 16-24 total voices)
- Optimize sample playback: use compressed audio formats (CAF with IMA4)
- Share effect instances (one reverb for all tracks)
- Offer "Low CPU" mode
- Profile on iPad Air 3 (A12) as minimum target

**Target**: <40% CPU on iPad Air 3 with all 8 tracks active

### Challenge 2: Host Sync Reliability
**Mitigations**:
- Primary mode: Internal clock (always works)
- Test in AUM, Cubasis, GarageBand, Beatmaker 3
- Fallback warning if host tempo unstable
- Consider MIDI clock sync as alternative

### Challenge 3: SwiftUI Performance for Step Grid
**Mitigations**:
- Use `Canvas` for step grid rendering
- Only redraw visible page (16-32 steps)
- Throttle UI updates (30 fps is fine)
- Consider UIKit for grid if needed

---

## 6. MVP Feature Set (Recommended Phasing)

### Phase 1: Core Audio Engine
- Single track sample playback
- **Sample slicing (Grid machine)** - auto-slice samples, trigger individual slices
- Basic 16-step sequencer (no p-locks yet)
- Internal clock only
- Velocity-sensitive triggering
- Simple filter + amp envelope
- Host as AUv3 instrument
- Minimal UI: 16 pads, play/stop, tempo, slice controls

**Deliverable**: Can trigger samples and slices in a DAW, sounds good

#### Key Architecture Decision: Custom Voice Engine
Using custom AVAudioPlayerNode-based voice engine instead of DunneAudioKit Sampler:
- **Why**: DunneAudioKit lacks programmatic start/end point control for slicing
- **Approach**: `AVAudioPlayerNode.scheduleSegment()` for frame-accurate slice playback
- **Signal chain**: AVAudioPlayerNode → AudioKit LowPassFilter → AudioKit AmplitudeEnvelope → TrackMixer

#### Sample Slicing (Grid Machine) Scope
**Include in Phase 1**:
- Even grid slicing (GRID: 4, 8, 16, 32, 64)
- Zero-crossing detection for click-free cuts
- SLICE parameter (select which slice to play)
- LEN parameter (consecutive slices)
- MIDI note to slice mapping

**Defer**:
- Transient detection (auto-detect drum hits)
- Manual slice point editing
- Individual slice tuning/reverse

### Phase 2: Parameter Locks
- Parameter lock storage system
- Lock/unlock parameters per step
- Visual feedback for locked steps
- 8-16 lockable parameters
- Copy/paste/clear operations
- Preset save/load with p-locks

**Deliverable**: Digitakt-style sequences with evolving parameters

### Phase 3: Multi-Track + Host Sync
- 8 independent tracks
- Per-track mute/solo
- Host tempo sync
- Transport sync
- Track mixer with levels
- Sample browser

**Deliverable**: Full drum machine with DAW integration

### Phase 4: Advanced Sequencer Features
- Trig conditions (probability, fill mode)
- Micro timing per step
- Retrigs (1/1 to 1/32)
- Per-track length (polyrhythms)
- Live recording mode
- Pattern chaining

**Deliverable**: Professional-grade sequencer

### Phase 5: Effects + Polish
- Send effects (reverb, delay, chorus)
- Per-track effect routing
- Master compressor/limiter
- Keyboard mode (chromatic playing)
- MIDI learn for external controllers
- Preset management system

**Deliverable**: Shippable product

---

## 7. Recommended Project Structure

```
DigitaktAUv3/
├── DigitaktAUv3/
│   ├── App/
│   │   ├── DigitaktApp.swift
│   │   └── ContentView.swift
│   │
│   ├── Audio/
│   │   ├── Conductor.swift
│   │   ├── TrackVoice.swift
│   │   ├── Voice.swift
│   │   ├── Effects/
│   │   │   ├── MasterEffects.swift
│   │   │   └── TrackEffects.swift
│   │   └── DSP/
│   │       ├── EnvelopeGenerator.swift
│   │       ├── LFO.swift
│   │       └── ModulationRouter.swift
│   │
│   ├── Sequencer/
│   │   ├── SequencerEngine.swift
│   │   ├── SequencerClock.swift
│   │   ├── TrackSequencer.swift
│   │   ├── Pattern.swift
│   │   ├── ParameterLockResolver.swift
│   │   ├── TrigConditions.swift
│   │   └── EventQueue.swift
│   │
│   ├── UI/
│   │   ├── Components/
│   │   │   ├── StepGrid.swift
│   │   │   ├── TrigPad.swift
│   │   │   ├── ParameterKnob.swift
│   │   │   └── TransportControls.swift
│   │   ├── Panels/
│   │   │   ├── TrigPanel.swift
│   │   │   ├── SourcePanel.swift
│   │   │   ├── FilterPanel.swift
│   │   │   ├── AmpPanel.swift
│   │   │   ├── FXPanel.swift
│   │   │   └── ModPanel.swift
│   │   └── MainView.swift
│   │
│   ├── Models/
│   │   ├── Parameter.swift
│   │   ├── ParameterSnapshot.swift
│   │   ├── Track.swift
│   │   ├── Project.swift
│   │   └── Sample.swift
│   │
│   └── Shared/
│       ├── Constants.swift
│       └── PresetManager.swift
│
├── DigitaktAUv3Extension/
│   ├── AudioUnit/
│   │   └── DigitaktAudioUnit.swift
│   └── UI/
│       └── AudioUnitViewController.swift
│
└── Sounds/
    └── Factory/
```

---

## 8. Performance Targets

| Metric | Target | Stretch Goal |
|--------|--------|--------------|
| CPU usage (8 tracks active) | <40% on iPad Air 3 | <25% on iPad Pro M1 |
| Sequencer timing jitter | <1ms | <0.5ms |
| UI frame rate | 30 fps | 60 fps |
| Memory footprint | <100 MB | <50 MB |
| Maximum voices | 24 | 32 |

---

## 9. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| CPU overload on older iPads | High | High | Implement voice limiting |
| Host sync unreliability | Medium | Medium | Prioritize internal clock |
| UI complexity | Medium | High | Invest in UX design |
| Parameter lock state bugs | High | High | Extensive testing |

---

## 10. MVP Scope Recommendation: "Digitakt Lite"

### Include in MVP:
- 8 tracks, 16-32 steps
- Parameter locks (10-20 key parameters)
- Probability + fill mode
- Micro timing + retrigs
- Sample playback + basic effects
- Solid, beautiful UI

### Defer to Later:
- Cycle conditions (A:B) - complex, low usage
- Neighbor track logic (PRE/NEI) - niche feature
- 128 steps - start with 32
- Song mode / pattern chaining
- Sampling from audio input

---

## Next Steps

1. **Prototype sequencer timing** - Build simple 16-step sequencer with sample-accurate triggering
2. **Design parameter lock data structure** - Implement sparse storage
3. **Create voice allocator** - Build polyphony/retrig system, measure CPU
4. **UI mockup** - Design step grid and parameter pages
5. **Sample library planning** - Curate initial sound bank
