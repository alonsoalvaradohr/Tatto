# CircuiTikZ Orthogonal Routing & Topology Design Guide

**Document ID:** `KB-TATTO-001`  
**Classification:** Technical Reference / Standards Specification  
**Project:** Tatto Linear Power Supply (Silicon Architecture)  
**Standard:** IEEE Std 315 / IEEE 91/91a / CircuiTikZ 1.6+  

---

## 1. Executive Summary & Design Philosophy

In industrial schematic synthesis and silicon-level technical illustration, visual ambiguity translates directly to engineering failure. Schematics rendered in CircuiTikZ must adhere to deterministic, clean, orthogonal geometry.

This document establishes the binding geometric, topological, and syntactic rules for schematic generation within the Tatto project:
1. **Zero-Tolerance Diagonal Routing:** All signal and power interconnects travel strictly along Cartesian grid axes using orthogonal bends (`|-` or `-|`).
2. **Absolute Symbol Isolation:** Conductor lines must never intersect or traverse component bounding boxes, semiconductor active regions, or magnetic core regions.
3. **Explicit Node Identity:** Distinction between physical junctions (empalmes) and non-connecting wire crossings is enforced using explicit junction dots (`*-*` or `\fill` circles).
4. **Hierarchical Layering:** Analytical instrumentation (oscilloscopes, graticules, signal probes) is strictly isolated to the PGF `background` layer, leaving the physical schematic planar, unobstructed, and clear.

---

## 2. IEEE Standard & Global CircuiTikZ Configurations

### 2.1 Package Options and American Conventions
The project strictly implements the American/IEEE standard for passive and active components. European DIN symbols (e.g., rectangular resistors, curved logic gates) are prohibited.

```latex
\usepackage[american, cute inductors, american currents, american voltages]{circuitikz}
\usetikzlibrary{calc, positioning, backgrounds}

% Standard layer hierarchy declaration
\pgfdeclarelayer{background}
\pgfdeclarelayer{foreground}
\pgfsetlayers{background,main,foreground}
```

### 2.2 Global Scaling & Bipole Dimensions
To maintain proportional balance when mixing macro-level power components (transformers, bulk capacitors) with transistor-level differential stages and integrated current mirrors, use standard proportional scaling via `\ctikzset`:

```latex
\ctikzset{
    logic ports=ieee,
    resistors/scale=0.70,
    capacitors/scale=0.65,
    diodes/scale=0.65,
    transistors/scale=0.80,
    sources/scale=0.70,
    bipoles/thickness=1.0,
    nodes width=0.055
}
```

### 2.3 Strict Monochromatic Line Styles
In accordance with clean publication standards, use explicit semantic line styles:

```latex
\tikzset{
    rail/.style={line width=1.10pt, draw=black},
    signal/.style={line width=0.75pt, draw=black},
    feedback_bus/.style={line width=0.80pt, draw=black},
    probe_line/.style={draw=gray!70, densely dashed, line width=0.75pt},
    box_frame/.style={draw=gray!50, dashed, rounded corners=4pt, line width=0.6pt},
    scope_frame/.style={draw=black, fill=white, rounded corners=3pt, line width=0.85pt},
    scope_grid/.style={step=0.25cm, gray!25, very thin},
    scope_axis/.style={gray!70, thin},
    scope_wave/.style={draw=black, line width=1.15pt}
}
```

---

## 3. Orthogonal Routing Geometry

### 3.1 Fundamental Bend Operators: `|-` vs `-|`
In TikZ and CircuiTikZ, line routing between two points $(X_1, Y_1)$ and $(X_2, Y_2)$ is governed by directional bend operators:
- **Vertical-First (`|-`):** Traverses vertically from $(X_1, Y_1)$ to $(X_1, Y_2)$, then horizontally from $(X_1, Y_2)$ to $(X_2, Y_2)$.
- **Horizontal-First (`-|`):** Traverses horizontally from $(X_1, Y_1)$ to $(X_2, Y_1)$, then vertically from $(X_2, Y_1)$ to $(X_2, Y_2)$.

```
   (A)                (B)           (A) --------------+
    |                                                 |
    |                                                 |
    +---------------> (B)                            (B)
     Vertical-First (A |- B)          Horizontal-First (A -| B)
```

#### Rule Table for Bends
| Source Node | Destination Node | Intended Path Behavior | Correct Syntax |
| :--- | :--- | :--- | :--- |
| Collector $Q_1.C$ ($Y=4.0$) | Mirror Collector $Q_3.C$ ($Y=6.8$) | Collinear vertical trace | `\draw (Q1.C) -- (Q3.C);` |
| Output Tap ($X=38, Y=4$) | Feedback Input $Q_2.B$ ($X=20.2, Y=4$) | Top clearance loop | `\draw (FB) -- (38.6,4) -- (38.6,10) -- (21,10) \|- (Q2.B);` |
| Rail $V_{RAW}$ ($Y=9.0$) | Collector $Q_{pass}.C$ ($X=31.2, Y=8.2$) | Drop directly to pin | `\draw (Qpass.C) -- (Qpass.C \|- 0, 9.0);` |
| Differential Tail Node | GND Rail ($Y=0.0$) | Drop through current source | `\draw (TAIL) to[isource, l_=$I_{tail}$, -*] (18.7, 0.0);` |

### 3.2 Coordinate Arithmetic & Projections (`|-` and `-|`)
To connect a pin to an arbitrary bus line without manually computing intersection coordinates, use coordinate projection notation:
- `(A |- 0, Y)` denotes the point with the X-coordinate of `A` and Y-coordinate `Y`.
- `(0, X -| B)` denotes the point with X-coordinate `X` and the Y-coordinate of `B`.
- `(NodeA |- NodeB)` calculates the Cartesian intersection $(X_{\text{NodeA}}, Y_{\text{NodeB}})$.

#### Example: Direct Connection to Power Rail
```latex
% Connect collector of pass transistor Qpass directly upward to VRAW rail at Y=9.0:
\draw[signal] (Qpass.C) -- (Qpass.C |- 0, 9.0) node[circ, fill=black, inner sep=1.2pt] {};
```

---

## 4. Master Grid Strategy & Elevation Budgeting

A critical failure mode in complex analog schematics is overlap between macro components (inductors, transformers), active silicon, and feedback networks. A deterministic Master Coordinate Grid solves this by allocating explicit horizontal bands.

### 4.1 Tatto Reference Coordinate Grid
```
Y = 13.8 ---------------------------------------------------- [Top Scope Graticule Limit]
Y = 12.5 ---------------------------------------------------- [Oscilloscope Screen Centerlines]
Y = 11.5 ---------------------------------------------------- [Bottom Scope Chassis / Probe Start]
         . . . . . . . . . . . . . . . . . . . . . . . . . . 
Y = 10.0 ==================================================== [Top Feedback Clearance Corridor]
Y =  9.0 ==================================================== [V_RAW / Positive Power Rail]
Y =  7.5 ---------------------------------------------------- [Driver Stage / Pass Transistor Level]
Y =  6.8 ---------------------------------------------------- [Active Load Mirror (PNP: Q3, Q4)]
Y =  4.0 ---------------------------------------------------- [Differential Pair / VAS Centerline]
Y =  2.7 ---------------------------------------------------- [Tail Current Source Level]
Y =  0.0 ==================================================== [GND / Common Reference Rail]
```

### 4.2 Horizontal Stage Progression (X-Axis)
The schematic progresses monotonically from energy conversion on the left to regulated output on the right:
- **$X = 0.0 \to 4.8$:** Primary AC source $v_{\text{AC}}$, galvanic isolation transformer $T_1$, secondary taps.
- **$X = 4.8 \to 9.5$:** Full-wave planar diode bridge ($D_1 \to D_4$).
- **$X = 9.5 \to 14.5$:** Bulk smoothing capacitor $C_{\text{bulk}}$, high-frequency bypass $C_{\text{in}}$, and raw rail generation.
- **$X = 14.5 \to 16.5$:** Zener reference branch ($R_{\text{bias}}$, $D_Z$).
- **$X = 16.5 \to 30.5$:** Silicon Core: NPN Differential pair ($Q_1, Q_2$), PNP Active mirror ($Q_3, Q_4$), VAS ($Q_5$) with Miller cap ($C_c$), Class-AB push-pull drivers ($Q_6, Q_7$).
- **$X = 30.5 \to 36.0$:** Series pass power element ($Q_{\text{pass}}$), current sense resistor ($R_{\text{sc}}$), current limiter ($Q_{\text{limit}}$).
- **$X = 36.0 \to 42.0$:** Output filtering ($C_{\text{out}}$), voltage divider feedback ($R_1, R_2$), test load ($R_{\text{load}}$), and output terminals ($V_{\text{out},+}, V_{\text{out},-}$).

---

## 5. Node Anchoring, Mirroring & Symbol Collision Avoidance

### 5.1 Transistor Terminal Anchoring
CircuiTikZ transistors are 3-terminal non-symmetrical nodes with designated anchors:
- `Q.B` : Base
- `Q.C` : Collector
- `Q.E` : Emitter

#### Symmetrical Differential Pairs:
When drawing differential pairs or current mirrors, mirroring the right-hand transistor along its vertical axis is mandatory for clean inward/outward base connections:
```latex
% Left-hand transistor (standard orientation, base on left)
\node[npn] (Q1) at (17.2, 4.0) {};

% Right-hand transistor (mirrored orientation, base on right)
\node[npn, xscale=-1] (Q2) at (20.2, 4.0) {};
```
> [!IMPORTANT]
> When `xscale=-1` is applied to a transistor node, anchor designations `Q2.C` and `Q2.E` remain in their proper vertical locations (collector up for NPN, emitter down for NPN), but the base anchor `Q2.B` moves to the right.

### 5.2 Planar Diode Bridge Without Overlaps
Standard diamond diode bridge representations frequently suffer from messy line crossings. In the Tatto architecture, planar diamond placement resolves all crossings:
```latex
% Planar Diamond Bridge Coordinates
\coordinate (BR_AC1)  at (7.8, 5.8); % Top Vertex (AC input 1)
\coordinate (BR_AC2)  at (7.8, 2.2); % Bottom Vertex (AC input 2)
\coordinate (BR_GND)  at (6.3, 4.0); % Left Vertex (GND return)
\coordinate (BR_VRAW) at (9.3, 4.0); % Right Vertex (Raw positive output)

% Diode arms (fully planar, zero crossovers)
\draw[signal] (BR_AC1) to[D, l=$D_1$] (BR_VRAW);
\draw[signal] (BR_AC2) to[D, l_=$D_2$] (BR_VRAW);
\draw[signal] (BR_GND) to[D, l=$D_3$] (BR_AC1);
\draw[signal] (BR_GND) to[D, l_=$D_4$] (BR_AC2);
```

### 5.3 Polarized Capacitors: Directional Traps
The electrolytic capacitor component (`eC`) in CircuiTikZ is directional:
- If drawn from top to bottom `(X, Y_top) to[eC] (X, Y_bot)`, the positive curved plate is oriented toward `Y_top`.
- If drawn from bottom to top `(X, Y_bot) to[eC] (X, Y_top)`, the orientation is inverted, violating schematic polarities.

```latex
% CORRECT: Positive plate on top (VRAW rail)
\draw[signal] (12.2, 9.0) to[eC, l=$C_{\text{bulk}}$, *-*] (12.2, 0.0);

% INCORRECT: Inverts capacitor plate polarity
% \draw[signal] (12.2, 0.0) to[eC, l=$C_{\text{bulk}}$, *-*] (12.2, 9.0);
```

### 5.4 Junction Dots vs Wire Crossings
To avoid catastrophic ambiguity between connected wires and crossing conductors:
1. **Explicit Junctions:** Use `*-*`, `*-`, `-*`, or explicit `\node[circ, fill=black, inner sep=1.2pt] at (coord) {};`.
2. **Crossings:** When two orthogonal lines cross without an electrical connection, maintain a clean perpendicular intersection with **no dot**.

---

## 6. Analytical Layering: Embedded Oscilloscopes

### 6.1 Multi-Layer Architecture (`pgfonlayer`)
To ensure scopes, reference grids, and diagnostic probe lines do not obscure physical circuit wires, they are relegated to the `background` layer.

```latex
\begin{pgfonlayer}{background}
    % Macro: \renderScope{X_center}{Y_center}{waveform_drawing_commands}
    \newcommand{\renderScope}[3]{
        \begin{scope}[shift={(#1,#2)}]
            % 1. Bezel / Chassis
            \draw[scope_frame] (-1.25, -0.95) rectangle (1.25, 0.95);
            % 2. Graticule Grid (5mm step, 8x10 div equivalent)
            \draw[scope_grid] (-1.1, -0.8) grid (1.1, 0.8);
            % 3. Graticule Center Axes
            \draw[scope_axis] (-1.1, 0) -- (1.1, 0);
            \draw[scope_axis] (0, -0.8) -- (0, 0.8);
            % 4. Waveform Clip Window
            \begin{scope}
                \clip (-1.1, -0.8) rectangle (1.1, 0.8);
                #3
            \end{scope}
        \end{scope}
    }

    % Example: Primary Sine Wave Scope
    \renderScope{1.0}{12.5}{
        \draw[scope_wave] plot[domain=-1.1:1.1, samples=60] (\x, {0.65*sin(360*\x/1.1)});
    }
\end{pgfonlayer}
```

### 6.2 Test Probe Bug Prevention: `Unknown arrow tip kind '*'`
In standard TikZ, invoking arrow/point syntax like `\draw[probe_line, *-] (A) -- (B);` outside of CircuiTikZ bipole contexts triggers:
`! Package PGF Error: Unknown arrow tip kind '*'`.

#### Mandatory Mitigation Pattern:
Always decouple the dashed connection line from the contact point:
```latex
% 1. Draw dashed line strictly without tip modifiers
\draw[probe_line] (1.0, 11.55) -- (1.0, 4.6);
% 2. Explicitly stamp the contact node as a filled circle
\fill[black] (1.0, 4.6) circle (1.8pt);
```

---

## 7. Quality Checklist for Schematic Verification

Before committing any `.tex` schematic file, verify each condition:
- [ ] No diagonal lines exist in any electrical path (`git grep -E '\([0-9.]+,[0-9.]+\) -- \([0-9.]+,[0-9.]+\)'` checked for slope).
- [ ] Every 3-way or 4-way connection has an explicit junction dot (`circ` or `*`).
- [ ] No conductor lines pass through the interior of transistor symbols ($Q_1 \to Q_7, Q_{\text{pass}}, Q_{\text{limit}}$).
- [ ] Transistors $Q_2$ and $Q_4$ have `xscale=-1` applied for symmetric differential pair routing.
- [ ] Polarized capacitors ($C_{\text{bulk}}$) are drawn from positive rail down to ground.
- [ ] All oscilloscopes reside inside `\begin{pgfonlayer}{background} ... \end{pgfonlayer}`.
- [ ] Test probes use dashed lines without `*-` syntax, terminated with `\fill[black] circle`.
- [ ] Code compiles cleanly with zero errors under `lualatex`.
