# King of Kings 3 — WE Engine Decompilation

A community-driven decompilation of [King of Kings 3](https://en.wikipedia.org/wiki/King_of_Kings_3) (also known as KoK3), an MMORPG developed by **Lager Network Technologies** (Taiwan) and published by **gamigo** (EU). The game client is built on the proprietary **WE Engine**.

## 🎯 Project Goal

Produce a fully matching C++ source code reconstruction of the WE Engine game client that compiles to a byte-identical binary using the original toolchain.

## 📋 Binary Targets

| Binary | Build Type | Compile Date | Size | Primary Target? |
|--------|-----------|-------------|------|----------------|
| `WEbug.exe` | **Debug** | 2009-12-28 | 13.5 MB | ✅ Reference (debug symbols) |
| `WE.exe` | Release | 2013-03-12 | 6.0 MB | ✅ Match target |
| `We_Lite.exe` | Release | 2009-12-23 | 5.7 MB | Cross-reference |
| `Login.exe` | Release | 2013-06-13 | 4.6 MB | Future target |

## 🔧 Build Requirements

This project **must** be built with the exact original toolchain to achieve binary matching:

| Tool | Version | Why |
|------|---------|-----|
| **Visual Studio 2005 SP1** | MSVC 8.0 (cl.exe 14.00.50727.x) | Rich header + linker version confirm this exact compiler |
| **Platform SDK** | Windows Server 2003 SP1 SDK | Windows headers / libs |
| **DirectX SDK** | June 2006+ | `d3dx9_30.dll` dependency |

### Setting Up the Build Environment

1. Install **Visual Studio 2005 Professional** (or Team Edition)
2. Install **Visual Studio 2005 SP1** (KB926601)
3. Install the **DirectX SDK** (June 2006 or later version that includes d3dx9_30)
4. Install the **Platform SDK for Windows Server 2003 SP1**
5. Open `WE.sln` in Visual Studio 2005

Alternatively, use the automated setup script:
```powershell
# On a fresh Windows VM/container:
.\tools\setup_build_env.ps1
```

## 📁 Project Structure

```
kok3-decomp/
├── src/                        # Decompiled source (mirrors c:\we\trunk\)
│   ├── audio/                  # Sound engine
│   ├── buffer/                 # Render buffers
│   ├── casualgame/             # Mini-games
│   ├── chatwindow/             # Chat system
│   ├── directxclass/           # DirectX abstraction
│   ├── effect/                 # Particle / VFX
│   ├── filesystemlib/          # LPQ virtual filesystem
│   ├── gameglobal/             # Global game state
│   ├── gamerecorder/           # Replay recording
│   ├── inputcontrol/           # Input handling
│   ├── interface/              # GUI framework
│   │   ├── component/          # UI widgets
│   │   ├── driver/             # Render backend
│   │   ├── gamefont/           # Font system
│   │   ├── gameui/             # Game windows/forms
│   │   └── kernel/             # GUI kernel
│   ├── model/                  # 3D model system
│   ├── network/                # Networking / protocol
│   ├── pathfinding/            # Navigation / A*
│   ├── playerprop/             # Player properties
│   ├── portrait/               # Character portraits
│   ├── scene/                  # 3D scene management
│   ├── scriptingmodules/       # Script engine
│   ├── shader/                 # GPU shaders
│   ├── share/                  # Shared utilities
│   ├── speedtreert/            # SpeedTree integration
│   ├── terrain/                # Terrain engine
│   ├── texture/                # Texture management
│   └── thread/                 # Threading / job system
├── include/                    # Project-wide headers
├── tools/                      # Build scripts & utilities
├── docs/                       # Documentation
├── .github/workflows/          # CI/CD
└── WE.sln                      # VS 2005 Solution file
```

## 🚀 How to Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Quick Start

1. **Fork** this repository
2. **Pick an unstarted file** from `src/` (check the status comment at the top)
3. **Decompile** using IDA Pro, Ghidra, or your preferred tool
4. **Open a PR** with your decompiled code

### Decompilation Workflow

1. Load `WEbug.exe` (Debug build) in your disassembler — it has full source paths and RTTI
2. Use the source path comments in stub files to find the corresponding code in the binary
3. Use BinDiff/Diaphora to correlate functions between WEbug.exe ↔ WE.exe
4. Write matching C++ that compiles to identical machine code
5. Verify with the CI pipeline (automated binary diff)

### File Status Tracking

Each source file begins with a status comment:

```cpp
// Status: Not started     — No decompilation work done
// Status: In progress     — Partially decompiled
// Status: Functions done   — All functions decompiled, needs cleanup
// Status: Matching        — Produces byte-identical output
```

## 📊 Progress

<!-- This section will be auto-generated -->
| Module | Files | Matching | In Progress | Not Started |
|--------|-------|----------|-------------|-------------|
| Total | 317 | 0 | 0 | 317 |

## ⚖️ Legal Disclaimer

This project is a **clean-room decompilation** effort for educational and preservation purposes. No original copyrighted source code or assets are included. All code in this repository is independently reconstructed from analysis of publicly available binaries.

## 📚 Resources

- [IDA Pro](https://hex-rays.com/ida-pro/) — Primary disassembler
- [Ghidra](https://ghidra-sre.org/) — Free alternative disassembler
- [BinDiff](https://www.zynamics.com/bindiff.html) — Binary diffing tool
- [Diaphora](https://github.com/joxeankoret/diaphora) — Open-source binary diffing
- [decomp.me](https://decomp.me/) — Collaborative decompilation scratchpad

## 🏗️ Architecture Notes

- The engine uses a **MUD-heritage networking layer** (`mudclientfunctions`, `mudserverfunctions`)
- Custom **LPQ archive format** for game assets (`.lpq` / `.bhl` files)
- **SpeedTree RT** for vegetation rendering
- Custom **GUI framework** with widget system (edit, listbox, combobox, memo, etc.)
- **DirectX 9** rendering with shader support (HLSL effects)
- **TinyXML** for configuration parsing (adapted for LPQ archives)
- **LZSS compression** for network packets
