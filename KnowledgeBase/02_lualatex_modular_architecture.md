# LuaLaTeX Modular Architecture & Compilation Engineering Guide

**Document ID:** `KB-TATTO-002`  
**Classification:** Technical Reference / Architecture Specification  
**Project:** Tatto Linear Power Supply (Silicon Architecture)  
**Standard:** LuaHBTeX / TeX Live 2024+ / Modular Standalone Schema  

---

## 1. Engine Selection: Why LuaLaTeX?

For high-complexity engineering documentation incorporating deep CircuiTikZ schematics and multiple mathematical plots, classical 8-bit TeX engines (`pdflatex`, `latex`) impose hard architectural limitations that result in fatal compilation aborts.

### 1.1 Technical Comparison
| Architectural Feature | pdfLaTeX | XeLaTeX | LuaLaTeX (Target Engine) |
| :--- | :--- | :--- | :--- |
| **Memory Allocation** | Static limits (hardcoded in `texmf.cnf`) | Static with higher defaults | **Fully Dynamic** (Allocates system RAM on demand) |
| **TeX Capacity Exceeded** | Common with large PGF loops | Occasional on huge trees | **Virtually Eliminated** (Dynamic heap expansion) |
| **Native Scripting** | None (pure macro expansion) | None | **Embedded Lua 5.3+ runtime** |
| **Font Subsystem** | 8-bit T1 font metrics (`pdftype1`) | Native OS OpenType (`fontspec`) | Modern OpenType & TrueType with HarfBuzz (`lua-uni-alg`) |
| **Microtypography** | Full `microtype` support | Partial support | **Full expansion and protrusion** support |

### 1.2 The `TeX capacity exceeded` Hazard
When rendering multi-layer PGF schematics with dense graticules and trigonometric plots (e.g. 5 analytical oscilloscopes with 100 sample points each, combined with multi-transistor discrete loops), pdfLaTeX frequently aborts with:
```
! TeX capacity exceeded, sorry [main memory size=5000000].
```
LuaLaTeX completely eliminates this failure mode by dynamically resizing internal string pools, hash tables, and node trees directly from OS memory pools.

---

## 2. Directory Hierarchy & Taxonomy

To maintain modularity and atomic traceability across multi-agent workflows, the project adheres to a decoupled folder taxonomy:

```
.
├── main.tex                         # Master orchestrator document
├── main.pdf                         # Consolidated output dossier
├── preamble/
│   ├── packages.tex                 # Core LaTeX package imports & options
│   ├── circuitikz_styles.tex        # IEEE ctikzset, custom TikZ line styles
│   └── macros.tex                   # Analytical macros (\renderScope, math helpers)
├── chapters/
│   ├── 01_macro_power.tex           # Transformer & Bridge sub-document
│   ├── 02_silicon_regulator.tex     # Pass transistor & current limiter sub-document
│   ├── 03_transistor_error_amp.tex  # Differential pair, VAS & push-pull sub-document
│   └── 04_simulation_validation.tex # SPICE & Simscape numerical validation sub-document
├── figures/
│   └── tikz/
│       ├── standalone_master.tex    # Full unified standalone schematic
│       ├── 01_transformer_bridge.tex# Isolated stage 1 schematic
│       ├── 02_reference_error.tex   # Isolated stage 2 schematic
│       └── 03_vas_driver_pass.tex   # Isolated stage 3 schematic
├── attachments/
│   ├── simulation_spice.cir         # Industrial SPICE netlist
│   └── simulation_simscape.m        # MATLAB Simscape executable model
└── KnowledgeBase/                   # Canonical technical references (KB-TATTO-*)
```

---

## 3. Package Management & Loading Sequence

Package conflicts in LaTeX arise predominantly from order-dependent macro collisions and option clashes. The loading sequence in `preamble/packages.tex` must be strictly maintained.

### 3.1 Strict Loading Order
```latex
% 1. Encoding & Engine Essentials (When using LuaLaTeX, fontspec handles encodings)
\usepackage{fontspec}
\usepackage[spanish,es-tabla]{babel}

% 2. Page Geometry & Layout
\usepackage{geometry}
\geometry{
    a4paper,
    top=25mm,
    bottom=25mm,
    left=20mm,
    right=20mm,
    footskip=12mm
}

% 3. Mathematical Typology
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{mathtools}
\usepackage{siunitx}
\sisetup{
    output-decimal-marker = {.},
    per-mode = symbol,
    range-phrase = { \text{to} }
}

% 4. Graphics & Colors (Load xcolor BEFORE any PGF/TikZ packages)
\usepackage[dvipsnames,svgnames]{xcolor}
\usepackage{graphicx}

% 5. Circuit Design & PGF Framework
\usepackage{tikz}
\usepackage[american, cute inductors, american currents, american voltages]{circuitikz}
\usetikzlibrary{calc, positioning, backgrounds, external}

% 6. Modularity Packages
\usepackage{standalone}
\usepackage{subfiles}

% 7. Micro-typographic Optimization (Load after fonts and languages)
\usepackage{microtype}

% 8. Hyperlinks & Metadata (Always load hyperref NEAR THE END)
\usepackage{hyperref}
\hypersetup{
    colorlinks=true,
    linkcolor=black,
    citecolor=black,
    urlcolor=blue!70!black,
    pdftitle={Tatto Linear Power Supply Technical Dossier},
    pdfauthor={Silicon Architecture Group}
}

% 9. Intelligent References (Load cleveref strictly AFTER hyperref)
\usepackage{cleveref}
```

> [!WARNING]
> Loading `xcolor` *after* `circuitikz` or `tikz` will trigger an `Option clash for package xcolor` if any loaded library attempts to load `xcolor` with conflicting driver settings.

---

## 4. Standalone vs Subfiles Integration

### 4.1 The `standalone` Pattern (Recommended for TikZ Schematics)
The `standalone` workflow decouples graphical rendering from document composition.

#### Sub-figure File (`figures/tikz/stage1_bridge.tex`):
```latex
\documentclass[tikz, border=10pt]{standalone}
\usepackage[american]{circuitikz}
\usetikzlibrary{calc, backgrounds}
% Reusable styles can be input here
\input{../../preamble/circuitikz_styles.tex}

\begin{document}
\begin{circuitikz}
    % Standalone schematic code compiles by itself for instant debugging!
    \draw (0,0) to[sV, l=$v_{\text{AC}}$] (0,3) -- (2,3);
\end{circuitikz}
\end{document}
```

#### Master File Inclusion (`main.tex`):
In the master document preamble, include `\usepackage{standalone}`. Then include the sub-figure seamlessly:
```latex
\begin{figure}[htbp]
    \centering
    \includestandalone[width=\textwidth]{figures/tikz/stage1_bridge}
    \caption{Parametric Rectifier Subsystem.}
    \label{fig:bridge_stage}
\end{figure}
```
**Benefits:**
- Compiling `stage1_bridge.tex` takes ~0.5 seconds, avoiding full 30-second document recompiles during layout tweaking.
- `\includestandalone` automatically strips `\documentclass`, preambles, and `\begin{document}` blocks during master compilation.

### 4.2 The `subfiles` Pattern (Recommended for Text Chapters)
For textual narrative chapters containing tables, equations, and local figures, the `subfiles` package allows independent compilation while maintaining inherited master styling:

#### Chapter File (`chapters/01_macro_power.tex`):
```latex
\documentclass[../main.tex]{subfiles}

\begin{document}
\section{Macro Power Subsystem: Transformer and Rectification}
\label{sec:macro_power}
Detailed theoretical derivation...
\end{document}
```

---

## 5. TikZ Externalization (`tikzexternalize`)

For large schematics containing high-density oscilloscope graphs, compile times in LuaLaTeX can grow excessively if the PGF engine recalculates every plot path on every pass. TikZ Externalization converts each `tikzpicture` into a standalone cached PDF during the first pass and includes the pre-rendered PDF on subsequent passes.

### 5.1 Externalization Setup
In `main.tex`:
```latex
\usetikzlibrary{external}
\tikzset{external/system call={lualatex \tikzexternalcheckshellescape -halt-on-error -interaction=batchmode -jobname "\image" "\texsource"}}
\tikzexternalize[prefix=figures/cache/] % Store cached PDFs in figures/cache/
```

### 5.2 Compiling with Shell Escape
Because externalization spawns sub-processes to compile each figure, the LuaLaTeX compiler must be invoked with `-shell-escape`:
```bash
lualatex -shell-escape -synctex=1 -interaction=nonstopmode main.tex
```

### 5.3 Handling `pgfonlayer` with Externalization
When using custom layers (`\pgfdeclarelayer{background}`), externalization operates correctly as long as layers are declared in the global preamble before `\tikzexternalize` is called. If a particular figure needs to bypass caching during active development, disable it locally:
```latex
\tikzset{external/export next=false}
\begin{circuitikz}
    ...
\end{circuitikz}
```

---

## 6. Layout Sanitation & Typesetting Hygiene

### 6.1 Eliminating Overfull / Underfull Boxes
In technical reports, Overfull `\hbox` warnings (>0.5pt) represent text or math protruding into page margins, which is unacceptable in professional silicon dossiers.

#### Automated Mitigation Settings:
```latex
% Preamble tolerances for technical typesetting
\emergencystretch 3em
\hfuzz 0.5pt
\vfuzz 0.5pt
\hbadness 1000
\vbadness 1000

% microtype configuration for LuaLaTeX
\usepackage{microtype}
\microtypesetup{
    protrusion=true,
    expansion=true,
    factor=1000,
    unit=full
}
```

### 6.2 Float Management
To prevent floating figures from migrating across chapter boundaries, use `\usepackage{placeins}` and enforce barriers:
```latex
\usepackage{placeins}

% Automatically insert a \FloatBarrier at every \section
\let\Oldsection\section
\renewcommand{\section}{\FloatBarrier\Oldsection}
```

---

## 7. Automated Clean Build Script (PowerShell / Windows)

For reproducible local builds within the Tatto project, use the standard non-destructive build script:

```powershell
# build_dossier.ps1
$ErrorActionPreference = "Stop"
$ProjectDir = "."
Set-Location $ProjectDir

Write-Host ">>> Compiling Master Dossier via LuaLaTeX..." -ForegroundColor Cyan

# First pass (auxiliary and label generation)
lualatex -synctex=1 -interaction=nonstopmode -shell-escape main.tex

# Second pass (cross-reference and citation resolution)
lualatex -synctex=1 -interaction=nonstopmode -shell-escape main.tex

Write-Host ">>> Compilation Complete: main.pdf successfully generated." -ForegroundColor Green
```
