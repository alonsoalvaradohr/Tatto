# CTAN CircuiTikZ Deep Architectural & Anchor Index

> **Primary Source Document:** `KnowledgeBase\circuitikzmanual.pdf`  
> **Package:** `circuitikz`  
> **Version:** 1.8.5 (Release date: 2026/02/04)  
> **Authors:** Massimo A. Redaelli, Stefan Lindner, Stefan Erhardt, Romano Giannetti  
> **File Size:** 2,628,936 bytes (2.63 MB, 305 pages)  
> **SHA-256:** `7DE983904AE4DBF46313FA185C48593B9B6B8EF11BAB082A3AB3D46FAB2D9B67`  
> **Upstream Authority:** [CTAN circuitikz Package](https://ctan.org/pkg/circuitikz) | [Direct CTAN Manual PDF](https://mirrors.ctan.org/graphics/pgf/contrib/circuitikz/doc/circuitikzmanual.pdf)

---

## 1. System Architecture & Component Models

CircuiTikZ components are implemented as native PGF/TikZ node shapes, split into two fundamental paradigms:

1. **Path-Style Components (`to[component, ...]`)**  
   - Inserted along a path between two coordinates: `\draw (A) to[R, l=$R_1$] (B);`.
   - The path engine automatically computes rotation angle, length scaling, and segment insertion.
   - Every path component is backed by an internal node shape (accessible by appending `shape`, e.g., `genericshape`, `resistorshape`, `diodeshape`, `cuteinductorshape`).

2. **Node-Style Components (`node[component, ...]`)**  
   - Instantiated at a specific coordinate: `\draw (0,0) node[npn] (Q1) {};` or `\draw (0,0) node[transformer] (T1) {};`.
   - Expose rich sets of terminal pins, internal subnodes, and polar reference anchors.

### Class-Based Hierarchical Styling (`\ctikzset`)
CircuiTikZ 1.8.5 provides granular control over component classes:
```latex
\ctikzset{
    resistors/scale=0.8,
    capacitors/scale=0.8,
    inductors/scale=0.8,
    inductors/coils=5,
    inductors/width=0.6,
    transistors/scale=0.85,
    transistors/thickness=2,
    bipoles/border margin=1.1
}
```

---

## 2. Bipoles Anchor Architecture (Manual §3.1 – §3.3, §4.2 – §4.4)

### 2.1 Standard Geographical Anchors
Every bipole component instantiates an internal rectangular bounding envelope defined horizontally before path rotation:
- **Primary Points:** `left`, `right`, `center`.
- **Geographical Cardinals:** `north`, `south`, `east`, `west`.
- **Ordinals:** `north west`, `north east`, `south west`, `south east`.
- **Shortened Aliases:** `n`, `s`, `e`, `w`.

```latex
% Accessing bipole anchors via name key:
\draw (0,0) to[potentiometer, name=P1] ++(0,3);
\draw (P1.wiper) -- ++(1,0) node[right]{Wiper Output};
\draw (P1.n) node[above]{Top Pin};
\draw (P1.s) node[below]{Bottom Pin};
```

### 2.2 Border Anchors & Label Placement
- Bipoles expose continuous angular border anchors (`0` to `360`).
- By default, labels (`l=...`) and annotations (`a=...`) are attached at angles `90°` (north/above) and `270°` (south/below) relative to component orientation.
- **Margin Clearance:** The parameter `bipoles/border margin` controls standoff distance (default: `1.1`). To touch the exact body border:
  ```latex
  \ctikzset{bipoles/border margin=1.0}
  ```

### 2.3 Standalone Node-Shape Access
When precise manual pin-routing is required, bipoles can be placed as standard nodes:
```latex
\draw (2,2) node[potentiometershape, rotate=-90] (P_REG) {};
\draw (P_REG.left) -- ++(-1,0);
\draw (P_REG.right) -- ++(1,0);
\draw (P_REG.wiper) -- ++(0,-1);
```

---

## 3. Transistor Anchor Architecture (Manual §4.15)

Transistors are multi-terminal active components with distinct physical, electrical, and rotational anchor sets.

### 3.1 Bipolar Junction Transistors (BJT: `npn`, `pnp`, `nigbt`, `pigbt`)
- **Primary Electrical Anchors:**
  - `B` / `base`: Base terminal lead.
  - `C` / `collector`: Collector terminal lead.
  - `E` / `emitter`: Emitter terminal lead (indicated by arrow).
- **Sub-anchors & Internal Features:**
  - `nobase`: Instantiates transistor without the protruding base lead stub.
  - `bodydiode`: Adds protection antiparallel diode across C-E (customizable via `\ctikzset{transistor bodydiode/...}`).
  - `tr circle`: Encloses transistor in schematic circle without displacing electrical pins.
  - Circle anchors: `circle top`, `circle bottom`, `circle left`, `circle right`.

```latex
% High-Current Series-Pass BJT Driver:
\draw (4,2) node[npn] (Q_PASS) {$Q_1$};
\draw (Q_PASS.B) -- ++(-0.5,0) node[left] {Base Drive};
\draw (Q_PASS.C) node[above] {Collector (Raw DC)};
\draw (Q_PASS.E) node[below] {Emitter (Regulated)};
```

### 3.2 Field-Effect Transistors (FET: `nmos`, `pmos`, `nfet`, `pfet`, `hemt`)
- **Primary Electrical Anchors:**
  - `G` / `gate`: Gate control terminal.
  - `D` / `drain`: Drain terminal.
  - `S` / `source`: Source terminal.
  - `bulk`: Substrate connection (for 4-terminal MOSFETs like `nigfete`, `pigfete`).
- **Critical Invariance Rule (§4.15.9):**
  Geographical anchors (`north`, `south`, `east`, `west`) and pin anchors (`G`, `D`, `S`) remain mathematically invariant regardless of whether `bodydiode` or `tr circle` options are enabled. Text labels placed on transistors are positioned outside the nominal bounding box.

---

## 4. Transformers & Quadrupoles Anchor Architecture (Manual §4.19)

Transformers in CircuiTikZ (`transformer`, `transformer core`) model inductive coupling with exact multi-terminal access.

### 4.1 Four-Port Quadrupole Anchors
- **Primary Port A (Left / Input):**
  - `A1`: Upper terminal of primary winding.
  - `A2`: Lower terminal of primary winding.
- **Secondary Port B (Right / Output):**
  - `B1`: Upper terminal of secondary winding.
  - `B2`: Lower terminal of secondary winding.
- **Core & Polarity Anchors:**
  - `base`: Center label coordinate.
  - `inner dot A1`, `inner dot A2`: Polarity dot positions on inner edge of Port A.
  - `outer dot A1`, `outer dot A2`: Polarity dot positions on outer edge of Port A.
  - `inner dot B1`, `inner dot B2`: Polarity dot positions on inner edge of Port B.
  - `outer dot B1`, `outer dot B2`: Polarity dot positions on outer edge of Port B.

### 4.2 Internal Coil Subnode Access (`T-L1` and `T-L2`)
CircuiTikZ automatically instantiates internal child nodes for both windings:
- **Primary Inductor:** `T-L1` (rotated `-90°`).
- **Secondary Inductor:** `T-L2` (rotated `+90°`).
- **Coil Tap Anchors:**
  - `T-L1.a` and `T-L1.b`: Physical winding start and end endpoints.
  - `T-L2.a` and `T-L2.b`: Physical winding start and end endpoints.
  - `T-L1.midtap`: Center tap of primary coil.
  - `T-L2.midtap`: Center tap of secondary coil (critical for center-tapped full-wave rectifiers!).

```latex
% Center-Tapped Step-Down Transformer:
\draw (0,0) node[transformer core] (T) {};
\draw (T.A1) -- ++(-1,0) node[left] {120VAC Hot};
\draw (T.A2) -- ++(-1,0) node[left] {120VAC Neutral};
\draw (T.B1) -- ++(1,0) node[right] {12VAC Out+};
\draw (T.B2) -- ++(1,0) node[right] {12VAC Out-};
\draw (T-L2.midtap) -- ++(1.5,0) node[right] {Secondary Center Tap (GND)};
\node[circ] at (T.inner dot A1) {};
\node[circ] at (T.inner dot B1) {};
```

---

## 5. Inductors & Cute Chokes Architecture (Manual §4.3.4 – §4.3.6)

CircuiTikZ provides three inductor representations: `cute inductor` (default), `american inductor`, and `european inductor`.

### 5.1 Cute Inductors (`cute inductor` / `cuteinductorshape`)
- Modeled with overlapping helical loop curves.
- **Primary Anchors:** `start`, `end`, `center`, `midtap`.
- **Core Standoff Anchors:** `core west`, `core east` (enables attaching custom magnetic core lines or shields).
- **Variable Inductor Anchors:** `wiper`, `tip`.
- **Key Configuration Parameters:**
  ```latex
  \ctikzset{
      inductors/coils=5,         % Number of helical loops (default: 5)
      inductors/width=0.6,       % Normalized width (default: 0.6)
      inductors/core distance=2pt % Standoff of magnetic core line
  }
  ```

### 5.2 Cute Chokes (`cute choke` / `cutechokeshape`)
- Pre-packaged inductor with integrated magnetic core lines above the winding.
- Inherits all `cuteinductorshape` anchors with core lines automatically positioned and rendered.

---

## 6. Background Layer Integration (`pgfonlayer`)

When designing complex regulated power supply schematics, visual partitioning (e.g., isolating the AC mains domain, secondary rectification stage, and DC linear regulation loop) requires background layer separation.

### 6.1 PGF Layer Declaration Preamble
TikZ evaluates commands sequentially. Without dedicated layers, drawing a background shaded box after circuit components will occlude wires, pins, and labels.
```latex
% Declare background layer alongside main layer:
\pgfdeclarelayer{background}
\pgfsetlayers{background,main}
```

### 6.2 Using `\begin{pgfonlayer}{background}` in CircuiTikZ
All electrical wires, bipoles, and transistors are drawn on the default `main` layer. Functional bounding envelopes, heatsink zones, and chassis ground planes are pushed to the `background` layer:
```latex
\begin{circuitikz}[american]
    % Main Layer: Circuit Schematic
    \draw (0,0) node[transformer core] (T) {};
    \draw (3,1) node[npn] (Q1) {};
    \draw (T.B1) -- (Q1.C);
    
    % Background Layer: Domain Shading
    \begin{pgfonlayer}{background}
        \draw[fill=blue!10, draw=blue!40, rounded corners=4pt, dashed]
            ($(T.A1)+(-0.5,0.5)$) rectangle ($(T.A2)+(0.5,-0.5)$);
        \node[above, font=\tiny\sffamily\color{blue!80!black}]
            at ($(T.north)+(0,0.4)$) {Mains Isolation Zone};
            
        \draw[fill=orange!10, draw=orange!50, rounded corners=6pt]
            ($(Q1.north west)+(-0.4,0.4)$) rectangle ($(Q1.south east)+(0.4,-0.4)$);
        \node[below, font=\tiny\sffamily\color{orange!80!black}]
            at ($(Q1.south)+(0,-0.4)$) {Heatsink Boundary};
    \end{pgfonlayer}
\end{circuitikz}
```

---

## 7. Bounding Box Constraints & Canvas Optimization

### 7.1 Text Node Bounding Box Discrepancies
In CircuiTikZ, certain component annotations (transistor text labels, operational amplifier labels, voltage/current arrows) are positioned mathematically outside the underlying PGF node bounding box. This can lead to:
- Clipping when compiling with `standalone` class.
- Asymmetrical margins in modular page layouts.

### 7.2 Mitigation Strategies
1. **Auxiliary Canvas Extenders:**
   ```latex
   % Expand bounding box to encompass protruding text:
   \path (Q1.north) ++(0, 0.5);
   \path (T.south) ++(0, -0.5);
   ```
2. **Explicit Bounding Box Declaration:**
   ```latex
   \useasboundingbox (xmin, ymin) rectangle (xmax, ymax);
   ```
3. **Resetting Bounding Box:**
   ```latex
   \pgfresetboundingbox
   ```
4. **Overlay Annotations:**
   When adding diagnostic testpoint arrows or non-critical labels that must NOT affect canvas dimensions:
   ```latex
   \node[overlay, red, above] at (TP1) {TP1: 12.0V DC};
   ```

---

## 8. Cross-Reference Index Table

| Component Category | Section in Manual | Node / Bipole Shape Name | Primary Anchors |
| :--- | :--- | :--- | :--- |
| **Resistive Bipoles** | §4.2 (p. 55) | `genericshape`, `resistorshape`, `potentiometershape` | `left`, `right`, `wiper`, `n`, `s`, `e`, `w` |
| **Capacitors** | §4.3.1 (p. 61) | `capacitorshape`, `elkoshape` | `left`, `right`, `+`, `-` |
| **Inductors** | §4.3.4 (p. 63) | `cuteinductorshape`, `americaninductorshape` | `start`, `end`, `midtap`, `core west`, `core east` |
| **Chokes** | §4.3.4 (p. 64) | `cutechokeshape` | `start`, `end`, `midtap`, `core west`, `core east` |
| **Diodes** | §4.4 (p. 66) | `diodeshape`, `fulldiodeshape`, `schottkyshape` | `left`, `right`, `anode`, `cathode` |
| **BJT Transistors** | §4.15.1 (p. 120) | `npn`, `pnp`, `nigbt`, `pigbt` | `B` (base), `C` (collector), `E` (emitter) |
| **FET Transistors** | §4.15.3 (p. 122) | `nmos`, `pmos`, `njfet`, `pjfet` | `G` (gate), `D` (drain), `S` (source), `bulk` |
| **Transformers** | §4.19 (p. 156) | `transformer`, `transformer core` | `A1`, `A2`, `B1`, `B2`, `T-L1.midtap`, `T-L2.midtap` |
| **Op-Amps** | §4.20 (p. 163) | `op amp`, `en amp` | `+`, `-`, `out`, `up`, `down`, `v+`, `v-` |
| **Logic Ports** | §4.22 (p. 181) | `american and port`, `american or port` | `in 1`, `in 2`, `out`, `bin 1`, `bin 2` |
| **Multiplexers** | §4.24 (p. 200) | `muxdemux` | `blpin 1`, `brpin 1`, `bbpin 1`, `btpin 1` |
