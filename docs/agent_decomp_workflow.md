# KoK3 Decompilation Strategy & Multi-Agent Workflow

This document outlines how to structure a collaborative decompilation project between your **Windows VM** (which hosts the original game files and compilers) and your **Mac (running the GLM 5.2 agent)**.

---

## 1. The Strategy: ABI Alignment (Functional Match)

A **byte-for-byte match** (perfect binary identity) is extremely difficult, time-consuming, and largely unnecessary for a 6 MB game client written in C++ on MSVC 2005.

Instead, we target **ABI Alignment (Application Binary Interface compatibility)**:
1. **Memory Layout Matching**: Every class must have the exact same size, member variables, and order of fields as the original. This is vital so that our decompiled code has identical memory offsets.
2. **Virtual Tables (vtable) Matching**: The order of virtual methods in C++ classes must match the virtual function tables in the binary.
3. **Function Signatures Matching**: Parameter count, types, calling conventions (`__thiscall`, `__stdcall`, `__cdecl`), and return types must align.
4. **Functional Equivalence**: The code must execute the exact same logic.

> [!TIP]
> **Why ABI Alignment is powerful:**
> If our compiled classes match the ABI of the original binary, we can compile individual modules (like `LagerPacket.dll` or `xcptlib.dll`) and swap them directly into the original game client, or build a new launcher that links against the original game DLLs.

---

## 2. The Multi-Agent Workflow

Since the **Mac agent (GLM 5.2)** cannot run the legacy Windows compiler (MSVC 8.0), the work is split between the two machines, bridged by a **GitHub Repository**.

```
  ┌──────────────────────────────────────────────────────────┐
  │                   1. WINDOWS VM (You)                    │
  │                                                          │
  │ • Import WEbug.exe into Ghidra                           │
  │ • Run the script to export ref/ assembly and pseudocode  │
  │ • Push the ref/ folder to GitHub                         │
  └────────────────────────────┬─────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────┐
  │              2. GITHUB REPOSITORY (Bridge)               │
  │                                                          │
  │ • src/          ← Decompiled source files (stubs)        │
  │ • ref/          ← Assembly, pseudocode, and RTTI data    │
  │ • .github/      ← CI build configs                       │
  └────────────────────────────┬─────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────┐
  │              3. MAC AGENT (GLM 5.2 - Decompiler)         │
  │                                                          │
  │ • Pulls latest repository changes                        │
  │ • Reads ref/ files to understand a target C++ class      │
  │ • Translates Ghidra C-like pseudocode back into clean C++│
  │ • Writes implementation in src/ and pushes back to GitHub│
  └────────────────────────────┬─────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────┐
  │             4. WINDOWS VM (CI Runner - Automated)        │
  │                                                          │
  │ • GitHub Action triggers on push                         │
  │ • Compiles the src/ directory using VS 2005 SP1          │
  │ • Reports compile errors and success back to GitHub      │
  └──────────────────────────────────────────────────────────┘
```

---

## 3. Ghidra Data Extraction (One-Time Setup on Windows)

To give the Mac agent the data it needs, we must extract assembly, pseudocode, and function metadata from the game binary.

We will write a **Ghidra Script** (in Java or Python) that runs inside Ghidra and exports this automatically.

### The Ghidra Export Script Structure
The script will perform the following actions:
1. Iterate through all analyzed functions in `WEbug.exe`
2. Determine which source file they belong to using the embedded debug line symbols (which we saw mapping back to `c:\we\trunk\...`)
3. For each file:
   - Generate raw assembly (`ref/assembly/path/to/file.asm`)
   - Generate Ghidra decompiler pseudocode (`ref/pseudocode/path/to/file.c`)
   - Generate metadata JSON (`ref/signatures/path/to/file.json`) containing function addresses, sizes, parameter names/types, and return types.
4. Export the RTTI class tree showing virtual tables and parent-child class hierarchy.

Once you run this script on the Windows VM, you commit the resulting `ref/` folder to GitHub.

---

## 4. How the Mac Agent (GLM 5.2) Reconstructs the Code

Because Ghidra's decompiler outputs **flat C-style code**, the Mac agent's role is to convert this back into object-oriented C++ that compiles with MSVC 2005.

### Example: Translating Flat Pseudocode to C++

#### Ghidra Output in `ref/pseudocode/scene/cbeing.c`:
```c
// Address: 0x0045A120
// Original Signature: cBeing::SetActive(cBeing *this, int activeState)
void __thiscall FUN_0045a120(int *this, int param_1) {
    if (param_1 != 0) {
        *(char *)(this + 0x48) = 1;
        FUN_00451A90(this); // Play spawn sound/effect
    } else {
        *(char *)(this + 0x48) = 0;
    }
}
```

#### RTTI Metadata in `ref/rtti_hierarchy.json`:
```json
{
  "class": "cBeing",
  "size": 128,
  "vtable": "0x005D2B10",
  "members": {
    "0x48": { "type": "bool", "name": "m_bActive" }
  }
}
```

#### What the Mac Agent writes to `src/scene/cbeing.h`:
```cpp
#pragma once
#include "share/bclasses.h"

class cBeing {
protected:
    // ... members ...
    bool m_bActive; // Offset 0x48

public:
    void SetActive(bool activeState);
    void PlaySpawnEffect(); // Map from FUN_00451A90
};
```

#### What the Mac Agent writes to `src/scene/cbeing.cpp`:
```cpp
// [Original path: c:\we\trunk\scene\cbeing.cpp]
// Status: Matching
#include "scene/cbeing.h"

void cBeing::SetActive(bool activeState) {
    if (activeState) {
        m_bActive = true;
        PlaySpawnEffect();
    } else {
        m_bActive = false;
    }
}
```

---

## 5. The Verification Loop

When your Mac agent pushes code:
1. **Compilation Check**: The GitHub Actions runner attempts to compile the project. If there are typos, missing includes, or syntax errors, the build fails.
2. **Reviewing Logs**: The Mac agent reads the compilation log from the failed action, identifies the issue (e.g. `error C2065: 'm_bActive' : undeclared identifier`), fixes it, and pushes a new commit.
3. **ABI Check (Optional)**: A post-build script can compare the generated object sizes against the expected RTTI size, warning if a class is the wrong size in memory.
