# AudioKit AUv3 Instrument Template

A production-ready template for creating AUv3 (Audio Unit version 3) instruments for iOS and macOS using AudioKit 5 and **full SwiftUI**.

[![How to Make an AUv3 Instrument for iOS with AudioKit 5](https://img.youtube.com/vi/L8SMyBHOTJo/0.jpg)](https://www.youtube.com/watch?v=L8SMyBHOTJo "How to Make an AUv3 Instrument for iOS with AudioKit 5")

## ✨ Features

- ✅ **Full SwiftUI** - Both standalone app and AUv3 extension use SwiftUI
- ✅ **AudioKit 5** - Built on the latest AudioKit framework
- ✅ **MIDI Support** - Full MIDI input with external MIDI device support
- ✅ **Sample Playback** - Uses MIDISampler for EXS24/SoundFont playback
- ✅ **Cross-Platform** - Runs on iOS and macOS
- ✅ **AUv3 Extension** - Ready to load in GarageBand, Logic Pro, AUM, etc.
- ✅ **Parameter Automation** - Built-in reverb parameter with DAW automation support
- ✅ **Factory Presets** - Example preset implementation

## 🚀 Quick Start

### Using the Setup Script (Recommended)

```bash
curl -O https://raw.githubusercontent.com/hagenkaiser/AudioKitTemplate/main/setup-template.sh
chmod +x setup-template.sh
./setup-template.sh
```

Follow the prompts to create your custom project!

### Manual Clone

```bash
git clone https://github.com/hagenkaiser/AudioKitTemplate.git YourProjectName
cd YourProjectName
```

Then customize the project name, bundle IDs, and Audio Unit codes.

## 📖 Documentation

- [TEMPLATE_README.md](TEMPLATE_README.md) - Complete template usage guide
- [CLAUDE.md](CLAUDE.md) - Architecture and implementation details

## 🎵 What You Get

- Standalone iOS/macOS app with on-screen keyboard
- AUv3 plugin that works in any compatible DAW
- MIDI sampler with example sounds
- Reverb effect with automation
- SwiftUI throughout (no UIKit/AppKit except for AUv3 hosting)

## 📦 Requirements

- Xcode 14.0+
- iOS 15.0+ / macOS 12.0+
- Swift 5.7+

## 🙏 Credits

Based on [AudioKit](https://github.com/AudioKit/AudioKit) by the AudioKit team.

Original template by Nick Culbertson [@MobyPixel](https://twitter.com/MobyPixel) • [MobyPixel.com](http://www.mobypixel.com)

SwiftUI conversion and template setup by [@hagenkaiser](https://github.com/hagenkaiser)
