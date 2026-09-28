# Aether 🌌 — Neural macOS Optimizer & On-Device Micro-SLM

<div align="center">

![Aether Banner](Resources/AppIcon.icns)

**Ultra-lightweight, 100% Native, Liquid Glass System & Developer Optimizer powered by Apple Neural Engine (ANE).**

[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B-black?logo=apple&style=flat-square)](#)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white&style=flat-square)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](#)
[![On-Device SLM](https://img.shields.io/badge/AI%20Core-On--Device%20ANE%20(Zero--Cloud)-purple?style=flat-square)](#)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Offline%20%26%20Private-green?style=flat-square)](#)

</div>

---

## 🌟 Why Aether?

Commercial macOS optimizers often suffer from background daemon bloat, telemetry trackers, and 400MB+ Electron memory footprints. **Aether** is engineered from the ground up in pure Swift & SwiftUI to deliver a zero-compromise, hyper-fast, privacy-first system optimizer.

- 🧠 **On-Device Micro-SLM Copilot:** Runs on Apple Neural Engine (ANE) with 0.7ms inference latency. Assesses safety confidence and executes natural language system commands offline.
- 🛡️ **Zero-Risk Developer Armor:** Automatically scans active background processes, open ports, and repos modified within the last 7 days to shield your work from accidental deletion.
- 🪟 **Liquid Glass Aesthetics:** Acrylic vibrancy, specular light-refracting borders, and smooth micro-animations.
- ⚡ **Unified RAM Turbo Booster:** Active kernel VM page flushing recycles gigabytes of cache memory for local LLMs (Ollama, LM Studio) and intensive compilation workflows.
- 🌐 **Seamless Multi-Language:** Instant runtime switching between English (EN) and Turkish (TR).

---

## ⚡ Core Capabilities

### 1. 🧠 On-Device Neural Core (Aether AI 0.5B)
* Dedicated domain-specific micro language model on Apple Silicon ANE.
* Live 3D Pulsing Liquid Orb and real-time reasoning audit log.
* Natural language command bar (*e.g., "Optimize memory for Ollama", "Clean build caches"*).

### 2. 🔍 System Data Deep Inspector
* 100% match with macOS Settings > System Data (110+ GB).
* Detailed breakdown: Direct cleanables, Simulator runtimes, Homebrew caches, APFS snapshots, swap, and Application Support.

### 3. 🗑️ Clean App Uninstaller & Orphaned Leftovers Finder
* Full dependency discovery across `~/Library/Application Support`, `Caches`, `Containers`, `Saved Application State`, and `WebKit`.
* Drag & drop any `.app` to inspect and purge hidden leftovers.
* Dedicated detector for orphaned cache relics from previously deleted applications.

### 4. 🚀 AI & Developer Cache Cleaner
* Target local LLM models (`~/.ollama`, `HuggingFace`, `PyTorch`), package stores (`npm`, `yarn`, `pnpm`, `Gradle`, `Cargo`, `CocoaPods`), and Xcode `DerivedData`.
* Shield badge automatically protects active projects.

### 5. ⚡ Unified Memory Turbo Booster
* Live macOS memory pressure gauge and inactive memory page purging.
* Instant termination of rogue background processes and sleeping Electron helpers.

### 6. 📁 Large & Old Files Finder
* Instant Spotlight-accelerated search for files >100MB, >500MB, >1GB, >5GB.
* Filter archives, ISOs, DMGs, virtual disks, and media with "Reveal in Finder" support.

---

## 🛠️ Build & Installation

### Requirements:
- macOS 13.0 (Ventura) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Xcode 15+ / Swift 5.9+

### Quick Build (.app & .dmg):

```bash
# 1. Clone repository
git clone https://github.com/<your-username>/aether.git
cd aether

# 2. Build and sign native .app
chmod +x bundle_app.sh create_dmg.sh
./bundle_app.sh

# 3. Create distributable .dmg image
./create_dmg.sh
```

The signed `Aether.app` and distribution `Aether.dmg` will be ready in the project root directory.

---

## 🔒 Security & Privacy

- **100% Offline:** Zero analytics, zero telemetric data collection, zero network calls.
- **Safety Safeguards:** System partitions (`/System`, `/usr`, `/bin`, `/sbin`) are hard-locked against modification.
- **Trash vs Permanent Delete:** By default, actions move items safely to macOS Trash (`FileManager.trashItem`) with optional permanent deletion.

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.
