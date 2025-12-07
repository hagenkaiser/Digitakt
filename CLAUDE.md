# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project aims to create an AUv3 (Audio Unit v3) instrument plugin for iOS/macOS that captures the workflow and feel of Elektron hardware sequencers, specifically the Digitakt II and Tonverk.

**Current Status**: Pre-development/research phase. No code exists yet - only reference documentation.

## Reference Documentation

Located in `docs/`:
- **[AUv3_Feasibility_Assessment.md](docs/AUv3_Feasibility_Assessment.md)** - Architecture analysis, phased development plan, technical decisions
- **[Elektron_Workflow_AUv3_Reference.md](docs/Elektron_Workflow_AUv3_Reference.md)** - Comprehensive feature breakdown (sequencer, p-locks, trig conditions)
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

## Important Rules

- Never commit without explicit user approval
- Never provide timeline estimates (days, weeks, months) - AI estimates are unreliable
- Focus on concrete implementation steps and milestones, not when they'll be done
