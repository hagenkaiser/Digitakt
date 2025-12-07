# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project aims to create an AUv3 (Audio Unit v3) instrument plugin for iOS/macOS that captures the workflow and feel of Elektron hardware sequencers, specifically the Digitakt II and Tonverk.

**Current Status**: Phase 1 in progress - AUv3 shell with 16-step trig pad UI complete.

## Development Workflow

### ⚠️ MANDATORY: USE AGENTS FOR ALL DEVELOPMENT TASKS ⚠️

**DO NOT write code directly.** Always delegate to the appropriate agent:

| Task Type | Agent to Use |
|-----------|--------------|
| Audio DSP, sample playback, filters, effects | `auv3-dsp-engineer` |
| SwiftUI views, knobs, pads, visual design | `auv3-ui-designer` |
| Connecting DSP ↔ UI, AUv3 boilerplate, MIDI | `auv3-integrator` |
| Architecture decisions, signal flow design | `auv3-architect` |
| Feature ideas, GitHub issues, product specs | `auv3-product-manager` |

**Before writing ANY Swift code, ask yourself: "Which agent should handle this?"**

**Skills available:** Use `audiokit-dsp` skill for AudioKit/SporthAudioKit API reference.

Use `/create-auv3` command for new project scaffolding.

## Reference Documentation

Located in `docs/`:
- **[AUv3_Feasibility_Assessment.md](docs/AUv3_Feasibility_Assessment.md)** - Architecture analysis, phased development plan, technical decisions
- **[Elektron_Workflow_AUv3_Reference.md](docs/Elektron_Workflow_AUv3_Reference.md)** - Comprehensive feature breakdown (sequencer, p-locks, trig conditions)
- **[SporthAudioKit_DSP_Reference.md](docs/SporthAudioKit_DSP_Reference.md)** - Sporth operations for sample playback, filters, envelopes, voice architecture
- **[Tonverk_Panel_Layout_Reference.md](docs/Tonverk_Panel_Layout_Reference.md)** - Hardware UI reference with control mappings
- **Digitakt_II_Manual.txt** / **Tonverk-User-Manual.txt** - Full manual text extracts
- **Tonverk_pages_14-15-014_FrontPanel.png** - Front panel image for UI reference

## Core Elektron Concepts to Implement

1. **Parameter Locks (P-Locks)** - Per-step parameter automation; any parameter can have unique value per trig
2. **Trig Conditions** - Probability, FILL mode, cycle conditions (A:B), neighbor/previous logic
3. **16-Step Grid** - Visual trig placement with color coding (red=note, yellow=lock, blinking=has p-locks)
4. **Recording Modes** - Grid (step-based) and Live (real-time with auto p-lock capture)
5. **Parameter Pages** - 8 knobs mapped to TRIG/SRC/FLTR/AMP/FX/MOD pages

## Technology Stack

- **Platform**: iOS (iPad primary), macOS
- **Framework**: AUv3 (Audio Unit v3)
- **Audio**: AudioKit 5, SoundpipeAudioKit, SporthAudioKit
- **Language**: Swift
- **UI**: SwiftUI

## Build Commands

```bash
# Build standalone app for iOS Simulator
xcodebuild -scheme Digitakt -destination 'platform=iOS Simulator,OS=18.1,name=iPad Pro 11-inch (M4)' build

# Build AUv3 extension
xcodebuild -scheme DigitaktAUv3 -destination 'platform=iOS Simulator,OS=18.1,name=iPad Pro 11-inch (M4)' build

# List available simulators
xcrun simctl list devices available | grep iPad
```

## Important Rules

- **ALWAYS use the AUv3 agents for development tasks - DO NOT write code directly**
- **Always announce which agent you're delegating to before spawning it** (e.g., "This is a DSP task, delegating to auv3-dsp-engineer")
- Never commit without explicit user approval
- Never provide timeline estimates (days, weeks, months) - AI estimates are unreliable
- Focus on concrete implementation steps and milestones, not when they'll be done
