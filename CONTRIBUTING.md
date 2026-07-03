# Contributing to KoK3 Decompilation

Thank you for your interest in helping decompile the King of Kings 3 WE Engine! This guide will help you get started.

## Prerequisites

### Required Tools

- **Disassembler**: [IDA Pro](https://hex-rays.com/ida-pro/) (recommended, Hex-Rays decompiler is extremely helpful) or [Ghidra](https://ghidra-sre.org/) (free)
- **Compiler**: Visual Studio 2005 SP1 (MSVC 8.0) — see build setup below
- **Diffing tool**: [BinDiff](https://www.zynamics.com/bindiff.html) or [Diaphora](https://github.com/joxeankoret/diaphora)
- **Git**: For version control

### Build Environment Setup

You **must** use Visual Studio 2005 SP1 to compile. Other compiler versions will produce different codegen and binary matching will be impossible.

1. Obtain Visual Studio 2005 Professional/Team Edition
   - Available from MSDN subscriptions or Internet Archive
2. Install VS 2005 SP1 (KB926601)
3. Install DirectX SDK (June 2006 or later)
4. Install Platform SDK for Windows Server 2003 SP1

### Getting the Reference Binaries

You need the original game client binaries to decompile against. These are not included in this repository:

- `WEbug.exe` — **Debug build** (13.5 MB, compiled 2009-12-28) — PRIMARY reference
- `WE.exe` — Release build (6.0 MB, compiled 2013-03-12) — MATCH target
- `We_Lite.exe` — Release build (5.7 MB, compiled 2009-12-23) — Cross-reference

## Workflow

### 1. Pick a File

Browse the `src/` directory and find a file with `Status: Not started`. Smaller, self-contained modules are easiest to start with:

**Good first files (isolated, small):**
- `share/nhelper/ezstring.cpp` — String utilities
- `share/nhelper/btlist.cpp` — Linked list implementation
- `share/nhelper/btstream.cpp` — Stream I/O
- `share/hashmap.cpp` — Hash map implementation
- `network/netlzss.cpp` — LZSS compression
- `filesystemlib/packfileobj.cpp` — File system abstraction
- `thread/cjobmanager.cpp` — Job/thread manager

**Medium difficulty:**
- `audio/` module — Audio playback system
- `model/` module — 3D model loading/rendering
- `texture/` module — Texture management

**Advanced (large, many dependencies):**
- `scene/cbeing.cpp` — Game entity system
- `network/cnetwork.cpp` — Main networking class
- `interface/gameui/` — Game UI forms

### 2. Analyze in Disassembler

1. Load `WEbug.exe` in IDA Pro / Ghidra
2. Use the **source file path** from the stub comment to locate relevant functions
3. The debug build preserves:
   - Function boundaries (accurate due to no optimization)
   - RTTI class names (518 classes)
   - Source file paths in assert/debug strings
   - Stack variable names (in some cases)
4. Cross-reference with `WE.exe` using BinDiff to see the optimized Release version

### 3. Write Matching C++

- Replace the stub content with your decompiled code
- Update the status comment at the top of the file:
  ```cpp
  // Status: In progress
  ```
- Use the original naming conventions (Hungarian notation with `c` prefix for classes, `C` for some utility classes)
- Match the original code style observed in the binary

### 4. Verify Your Work

```bash
# Build the project
msbuild WE.sln /p:Configuration=Debug

# Compare your compiled output against the original
# (tooling for automated comparison TBD)
```

### 5. Submit a Pull Request

- One file per PR (or one logical module if files are tightly coupled)
- Include in your PR description:
  - Which functions were decompiled
  - Confidence level (exact match / approximate / structural only)
  - Any assumptions or unknowns
- The CI pipeline will attempt to compile your code with VS 2005

## Code Style Guidelines

Based on the original source paths and RTTI, the codebase follows these conventions:

### Naming

- **Classes**: Prefix `c` for game classes (e.g., `cBeing`, `cScene`, `cNetWork`)
- **Classes**: Prefix `C` for utility/framework classes (e.g., `CAreaCellContainer`, `CChatKernel`)
- **Files**: Lowercase, matching class name (e.g., `cbeing.cpp` for `cBeing`)
- **Member functions**: PascalCase
- **Member variables**: Hungarian notation likely (e.g., `m_pScene`, `m_nCount`)

### Includes

Use the relative paths matching the original project structure:
```cpp
#include "scene/cbeing.h"
#include "share/nhelper/nhelper.h"
```

### Third-Party Code

Some modules wrap third-party libraries. Do NOT decompile these — use the original library instead:
- **SpeedTree RT** (`speedtreert/`) — Licensed middleware
- **TinyXML** (`share/tinyxmlonlpq.cpp`) — Open source, find matching version
- **zlib** — Open source, shipped as `zlib.dll`

## Communication

- **Issues**: Use GitHub Issues for tracking decompilation progress per-module
- **Discussions**: Use GitHub Discussions for architecture questions and findings

## Rich Header Reference

For those doing deep binary analysis, here's the decoded Rich header from WEbug.exe:

```
Build 50727 = MSVC 8.0 (Visual Studio 2005)
Build 50327 = MSVC 8.0 import library tool
Build 3077  = MASM 6.15
Build 4035  = VC 6.0 legacy components

692 C/C++ compilation units (50727.110)
243 C-compiled files (50727.109)
 64 C++-compiled files (50727.125)
453 imported objects from libraries (0.1)
 37 VC 6.0 legacy object files (4035.93)
```
