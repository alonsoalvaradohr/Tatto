# CTAN PGF/TikZ Deep Architectural & Implementation Index

> **Primary Source Document:** `KnowledgeBase\pgfmanual.pdf`  
> **Package:** `pgf` / `tikz`  
> **Version:** 3.1.10+ (LuaTeX engine build)  
> **Authors:** Till Tantau, Christian Feuersänger, Stefan Tibus, et al.  
> **File Size:** 9,444,626 bytes (9.44 MB, 1323 pages)  
> **SHA-256:** `F679B859A0F05F5D9EAF92918DE895AEBFE5F3BC7D52724B278B2C4EC4FB9704`  
> **Upstream Authority:** [CTAN pgf Package](https://ctan.org/pkg/pgf) | [Direct CTAN Manual PDF](https://mirrors.ctan.org/graphics/pgf/base/doc/pgfmanual.pdf)

---

## 1. System Architecture & Core Engine

PGF (Portable Graphics Format) operates as a layered graphic engine beneath TikZ:
1. **System Layer:** Direct backend drivers emitting PDF primitives (`pgfsys-*.def`).
2. **Basic Layer:** Core PGF macros managing the coordinate transformation matrix (CTM), path construction, and layer management.
3. **Frontend Layer (TikZ):** Human-readable macro syntax (`\path`, `\draw`, `\node`, `\fill`, `\coordinate`).

In electronic schematic authoring under LuaLaTeX, mastering the mathematical coordinate engine, orthogonal path construction, and compilation externalization is vital for sub-millimeter layout precision.

---

## 2. Coordinate Math & Vector Geometry (Manual §13, §101)

### 2.1 Native Coordinate Systems (Manual §13.2)
- **Cartesian Canvas Coordinates:** `(x, y)` in dimensions (e.g., `(2.5cm, 1.2cm)` or unitless `(2.5, 1.2)` multiplied by `x` and `y` vectors).
- **Polar Coordinates:** `(theta:radius)` or `(angle:x_radius and y_radius)` for elliptical arcs:
  ```latex
  \draw (0,0) -- (45:2cm); % 45 degrees, 2cm distance
  ```
- **Node Anchor Coordinates:** `(node.anchor)` or `(node)` (which resolves to `node.center` or boundary depending on path operator):
  ```latex
  \draw (Q1.collector) -- ++(0, 1.5);
  ```

### 2.2 Relative vs Incremental Displacements (Manual §13.4)
- **Relative Single-Step (`+`):** Computes coordinate offset relative to the path's previous active point without updating the active point:
  ```latex
  \draw (1,1) -- +(1,0) -- +(0,1);
  % Segment 1: from (1,1) to (2,1)
  % Segment 2: from (2,1) to (1,2) [offset from original (1,1)]
  ```
- **Incremental Multi-Step (`++`):** Computes offset relative to previous point and **advances** the current point to the new location:
  ```latex
  \draw (1,1) -- ++(1,0) -- ++(0,1);
  % Segment 1: from (1,1) to (2,1)
  % Segment 2: from (2,1) to (2,2) [offset from new active point (2,1)]
  ```
  *Schematic Best Practice:* Use `++(dx, dy)` for step-by-step daisy-chained bus routing and layout offsets.

### 2.3 Vector Arithmetic with the `calc` Library (Manual §13.5, p. 147–152)
The `calc` library (`\usetikzlibrary{calc}`) enables coordinate expressions wrapped in `($ ... $)`:

1. **Partway Linear Interpolation (`!factor!`):**
   ```latex
   % Midpoint between transistor emitter and ground:
   \coordinate (R_MID) at ($(Q1.E)!0.5!(GND)$);
   % 30% from Port A to Port B:
   \coordinate (TAP) at ($(T.B1)!0.3!(T.B2)$);
   ```

2. **Coordinate Vector Addition & Subtraction:**
   ```latex
   \coordinate (BUS_TAP) at ($(T.B1) + (1.5cm, 0.5cm)$);
   ```

3. **Orthogonal Line Projection (`!(P)!`):**
   Projects point `P` perpendicularly onto the line passing through `A` and `B`:
   ```latex
   % Drop perpendicular from reference node VREF onto feedback divider trace:
   \coordinate (PROJ) at ($(DIV_TOP)!(VREF)!(DIV_BOT)$);
   ```

4. **Distance and Angle Projection (`!dist!angle:`):**
   ```latex
   % Position 1.5cm from A towards B, rotated by 90 degrees:
   \coordinate (ORTHO_POINT) at ($(A)!1.5cm!90:(B)$);
   ```

---

## 3. Orthogonal Routing Operators (`|-` and `-|`) (Manual §13.3.1, §14.2)

Schematics adhere to strictly orthogonal (Manhattan) routing. Diagonal traces are prohibited in professional circuit schematics.

### 3.1 Path Operators `|-` and `-|`
- **`|-` (Vertical-First, then Horizontal):** Moves vertically from the start point to match the y-coordinate of the target, then moves horizontally to the target:
  ```latex
  \draw (Q1.C) |- (R1.south);
  % Trace: (x_Q, y_Q) -> (x_Q, y_R) -> (x_R, y_R)
  ```
- **`-|` (Horizontal-First, then Vertical):** Moves horizontally from the start point to match the x-coordinate of the target, then moves vertically to the target:
  ```latex
  \draw (Q1.B) -| (OPAMP.out);
  % Trace: (x_Q, y_Q) -> (x_OP, y_Q) -> (x_OP, y_OP)
  ```

### 3.2 Perpendicular Intersection Coordinates `(A |- B)` and `(A -| B)`
TikZ allows immediate calculation of orthogonal corner coordinates without drawing a path:
- `(A |- B)`: Point having the **x-coordinate of A** and the **y-coordinate of B**.
- `(A -| B)`: Point having the **x-coordinate of B** and the **y-coordinate of A**.

```latex
% Aligning a ground symbol exactly beneath an op-amp non-inverting input:
\draw (OPAMP.+) -- (OPAMP.+ |- GND_RAIL) node[ground]{};

% Corner junction between unregulated DC rail and series pass transistor collector:
\coordinate (CORNER) at (V_UNREG -| Q_PASS.C);
\draw (V_UNREG) -- (CORNER) -- (Q_PASS.C);
\node[circ] at (CORNER) {}; % Solder junction
```

---

## 4. Intersection Engine (`intersections` Library) (Manual §13.3.2, §38)

In complex multi-stage topologies (e.g., dual secondary windings with bridge rectifiers and feedback loops), wire crossings often occur.

### 4.1 Path Naming & Automated Root Finding
```latex
\usetikzlibrary{intersections}

% Define intersecting paths:
\path[name path=wire_horizontal] (0, 2) -- (8, 2);
\path[name path=wire_vertical]   (4, 0) -- (4, 5);

% Compute intersections automatically:
\path[name intersections={of=wire_horizontal and wire_vertical, by=X1}];

% Place solder dot or crossing jumper:
\node[circ] at (X1) {}; % For electrical connection
% OR
% Leave unjoined or draw arc jumper for visual clearance:
\draw (4,0) -- ($(X1)+(0,-0.2)$) 
      arc[start angle=-90, end angle=90, radius=0.2] 
      -- (4,5);
```

### 4.2 Multi-Point Intersection Resolution
When intersecting paths have multiple crossings (e.g., sinusoidal ripple waveforms vs DC threshold lines):
```latex
\path[name intersections={of=ac_wave and dc_thresh, name=I}];
% Generates coordinates I-1, I-2, I-3...
\node[above] at (I-1) {Phase Fire $\theta_1$};
\node[above] at (I-2) {Phase Fire $\theta_2$};
```

---

## 5. Layered Graphics Architecture (`pgfdeclarelayer`) (Manual §45, §113)

TikZ renders graphical operations into the output stream in sequential order. In multi-component electronic diagrams, drawing background regions, power planes, and chassis enclosures after component definitions would paint over wires, text, and pins.

### 5.1 Layer Setup Preamble
```latex
% Declare custom rendering layers:
\pgfdeclarelayer{chassis}
\pgfdeclarelayer{background}
\pgfdeclarelayer{foreground}

% Order layers from back to front (main is default):
\pgfsetlayers{chassis,background,main,foreground}
```

### 5.2 Scoped Layer Rendering (`\begin{pgfonlayer}`)
```latex
\begin{tikzpicture}
    % --- MAIN LAYER (Default) ---
    % All electrical circuit components, wires, and pin labels:
    \draw (0,0) node[transformer] (T) {};
    \draw (4,0) node[npn] (Q1) {};
    \draw (T.B1) -- (Q1.C);
    
    % --- BACKGROUND LAYER ---
    % Subcircuit enclosure boundaries and functional block shading:
    \begin{pgfonlayer}{background}
        \filldraw[fill=blue!5, draw=blue!30, dashed, rounded corners=3pt]
            ($(T.A1)+(-0.6,0.6)$) rectangle ($(T.A2)+(0.6,-0.6)$);
    \end{pgfonlayer}

    % --- CHASSIS LAYER ---
    % Overall metallic enclosure grounding and thermal sinks:
    \begin{pgfonlayer}{chassis}
        \fill[gray!15] (-2,-3) rectangle (8,4);
    \end{pgfonlayer}
\end{tikzpicture}
```

### 5.3 Automated Background Rectangles (`backgrounds` Library)
For framing an entire circuit diagram:
```latex
\usetikzlibrary{backgrounds}
\begin{tikzpicture}[show background rectangle, 
    background rectangle/.style={fill=white, draw=gray!40, rounded corners=6pt, line width=0.8pt}]
    % Circuit elements...
\end{tikzpicture}
```

---

## 6. Compilation Optimization & Externalization (`external` Library) (Manual §52)

Complex CircuiTikZ diagrams with mathematical coordinate calculations, multiple layers, and fine wire grids cause significant LuaLaTeX compilation overhead. The `external` library serializes each diagram into an independent, pre-compiled PDF image (`.pdf`), reloading cached vector graphics on subsequent runs.

### 6.1 Preamble Configuration for LuaLaTeX
```latex
\usetikzlibrary{external}
\tikzexternalize[
    prefix=build/figures/, % Directory where standalone PDFs are written
    mode=convert with system call
]

% Ensure LuaLaTeX passes -shell-escape and correct jobname:
\tikzset{
    external/system call={
        lualatex \tikzexternalcheckshellescape -halt-on-error -interaction=batchmode -jobname "\image" "\texsource"
    }
}
```

### 6.2 Granular Externalization Control
- **Explicit Naming:**
  ```latex
  \tikzsetnextfilename{fig_linear_regulator_power_stage}
  \begin{circuitikz}
      ...
  \end{circuitikz}
  ```
- **Disabling for Small Inline Icons:**
  ```latex
  \tikzset{external/export=false}
  \tikz\draw[red,fill] (0,0) circle (2pt);
  \tikzset{external/export=true}
  ```
- **Remake Conditionals:**
  ```bash
  lualatex -shell-escape main.tex
  ```
  If a schematic's source code is unchanged, LuaLaTeX bypasses TikZ parsing and includes `build/figures/fig_linear_regulator_power_stage.pdf` directly via `\includegraphics`, reducing document build times from 15+ seconds to under 0.8 seconds.

---

## 7. Master Cross-Reference Table

| Concept | Manual Chapter | Section & Pages | Primary Macros / Keys |
| :--- | :--- | :--- | :--- |
| **Coordinate Systems** | Ch. 13 | §13.2 (p. 132–140) | `(x,y)`, `(theta:r)`, `(node.anchor)` |
| **Relative Moves** | Ch. 13 | §13.4 (p. 143–146) | `+(dx,dy)` vs `++(dx,dy)` |
| **Vector Math (calc)** | Ch. 13 | §13.5 (p. 147–152) | `($ ... $)`, `!factor!`, `!(P)!`, `!dist!angle:` |
| **Orthogonal Routing** | Ch. 14 & 13 | §14.2 (p. 156), §13.3.1 (p. 141) | `|-`, `-|`, `(A |- B)`, `(A -| B)` |
| **Path Intersections** | Ch. 13 & 38 | §13.3.2 (p. 142), §38 (p. 578) | `name path`, `name intersections={of=...}` |
| **Layer Architecture** | Ch. 113 | §113 (p. 1193–1196) | `\pgfdeclarelayer`, `\pgfsetlayers`, `pgfonlayer` |
| **Background Library** | Ch. 45 | §45 (p. 582–584) | `show background rectangle`, `framed` |
| **Externalization** | Ch. 52 | §52 (p. 605–620) | `\tikzexternalize`, `\tikzsetnextfilename`, `system call` |
