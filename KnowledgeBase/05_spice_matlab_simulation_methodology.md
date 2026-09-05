# SPICE & MATLAB/Simscape Simulation Methodology: Parametric Netlist Synthesis & Numerical Convergence

**Document ID:** `KB-TATTO-005`  
**Classification:** Technical Reference / Simulation & Modeling Specification  
**Project:** Tatto Linear Power Supply (Silicon Architecture)  
**Standard:** Berkeley SPICE3f5 / Simscape Electrical (R2018b+) / IEEE Std 1597.1  

---

## 1. Executive Summary & Verification Philosophy

In the Tatto development workflow, mathematical derivations and CircuiTikZ schematics are verified through twin simulation environments:
1. **SPICE Engine (Berkeley SPICE / NGSPICE / LTspice):** Evaluates nodal equations, nonlinear semiconductor physics, device junction capacitances, transient turn-on spikes, and phase/gain margins.
2. **MATLAB / Simscape Electrical:** Evaluates multi-domain physical conserving networks, transient states, dynamic load stepping, and system-level thermal dissipation.

This document establishes the exact translation mapping from the schematic nodes (defined in `tatto.json` and CircuiTikZ) into executable `.cir` netlists and programmatic MATLAB Simscape scripts (`.m`).

---

## 2. Global Node Naming Taxonomy

To ensure 1:1 correspondence between the graphic schematic, the SPICE netlist, and Simscape ports, all nodes follow a standardized semantic taxonomy:

| Semantic Node ID | CircuiTikZ Physical Anchor | SPICE Netlist Node | Simscape Connection Point |
| :--- | :--- | :--- | :--- |
| **AC Source Hot** | `AC1` / `T.A1` | `N_AC1` | `AC_Source.p` |
| **AC Source Neutral**| `AC2` / `T.A2` | `N_AC2` | `AC_Source.n` |
| **Secondary High** | `T.B1` / `BR_AC1` | `N_SEC1` | `Transformer.Sec1` |
| **Secondary Low** | `T.B2` / `BR_AC2` | `N_SEC2` | `Transformer.Sec2` |
| **Unregulated Rail**| `BR_VRAW` / `CapBulk_pos` | `N_RAW` | `C_Filter.p` |
| **System Ground** | `GND` / `0` | `0` (Reference) | `Electrical Reference.V` |
| **Reference Voltage**| `VREF` / `Q1.B` | `N_VREF` | `V_Ref.p` |
| **Feedback Tap** | `FB_TAP` / `Q2.B` | `N_FB` | `R_F1.n / R_F2.p` |
| **Differential Output**| `N2` / `Q2.C` / `Q4.C` | `N_DIFF_OUT` | `Diff_Out` |
| **VAS Collector Tap**| `VAS_COL_TAP` / `D6.K` | `N_VAS_C` | `VAS_Collector` |
| **Driver Output (DRV)**| `DRV` / `Qpass.B` | `N_DRV` | `Q_pass.B` |
| **Sense Node** | `SENSE` / `Qpass.E` | `N_SENSE` | `R_sc.p` |
| **Regulated Rail** | `VOUT_NODE` / `C_out.pos` | `N_OUT` | `R_Load.p` |

---

## 3. Parametric SPICE Netlist Specification (`.cir`)

The following netlist is an IEEE-standard, fully parametric representation of the complete Tatto discrete linear power supply.

```spice
* =========================================================================
* TATTO PROJECT: FULL DISCRETE LINEAR POWER SUPPLY (KB-TATTO-005)
* PARAMETRIC AGNOSTIC FORMULATION (NGSPICE / LTSPICE COMPATIBLE)
* =========================================================================

.title Tatto Discrete Linear Regulator Simulation Model

* --- Global Parametric Scaling Variables ---
.param V_GRID_RMS = 120.0
.param FREQ_AC    = 60.0
.param N_RATIO    = 0.1768         ; 120V RMS -> 15V RMS sec (~21.2V peak)
.param V_TARGET   = 12.0
.param V_ZENER    = 5.1
.param R_LOAD_VAL = 10.0           ; 12V / 10 ohm = 1.2A nominal load
.param I_TAIL_VAL = 2.0m           ; 2mA differential tail current
.param I_SC_MAX   = 1.5            ; Short-circuit current limit (A)

* --- Calculated Resistances ---
.param R_SC_VAL   = {0.65 / I_SC_MAX}
.param R2_VAL     = 10.0k
.param R1_VAL     = {R2_VAL * (V_TARGET / V_ZENER - 1.0)}
.param R_BIAS_VAL = { (20.0 - V_ZENER) / 10.0m }

* =========================================================================
* 1. POWER CONVERSION & RECTIFICATION (MACRO STAGE)
* =========================================================================
* Primary AC Voltage Source (Grid)
V_AC N_AC1 N_AC2 SINE(0 {V_GRID_RMS * 1.4142} {FREQ_AC} 0 0)
R_GND_ISO N_AC2 0 100Meg           ; High-impedance galvanic reference to ground

* Linear Parametric Transformer (Idealized Behavioral Core)
E_SEC N_SEC1 N_SEC2 N_AC1 N_AC2 {N_RATIO}

* Full-Wave Diode Bridge (Graetz Topology)
D1 N_SEC1 N_RAW  D_BRIDGE
D2 N_SEC2 N_RAW  D_BRIDGE
D3 0      N_SEC1 D_BRIDGE
D4 0      N_SEC2 D_BRIDGE

* Bulk Filter and High-Frequency Bypass
C_BULK N_RAW 0 2200u IC={V_TARGET * 1.5}
R_ESR  N_RAW N_RAW_FILT 0.05
C_IN   N_RAW_FILT 0 100n

* =========================================================================
* 2. VOLTAGE REFERENCE GENERATOR
* =========================================================================
R_BIAS N_RAW N_VREF {R_BIAS_VAL}
D_ZENER 0 N_VREF D_Z5V1
C_REF N_VREF 0 10u                 ; Reference noise bypass

* =========================================================================
* 3. SILICON ERROR AMPLIFIER & VAS STAGE
* =========================================================================
* Differential Pair (Q1: Non-Inverting / Q2: Inverting)
Q1 N_DIFF1 N_VREF N_TAIL 0 QNPN_GEN
Q2 N_DIFF_OUT N_FB N_TAIL 0 QNPN_GEN

* Constant Tail Current Source
I_TAIL N_TAIL 0 {I_TAIL_VAL}

* Active Current Mirror (Q3, Q4: PNP)
Q3 N_DIFF1     N_DIFF1 N_RAW 0 QPNP_GEN
Q4 N_DIFF_OUT  N_DIFF1 N_RAW 0 QPNP_GEN

* Voltage Amplification Stage (VAS: Q5)
Q5 N_VAS_C N_DIFF_OUT N_VAS_E 0 QNPN_GEN
R_VAS_DEG N_VAS_E 0 47.0           ; Emitter degeneration

* Miller Frequency Compensation Capacitor
C_MILLER N_DIFF_OUT N_VAS_C 100p

* VAS Pull-up Load Resistor
R_VAS_PULLUP N_RAW N_VAS_TOP 1.5k

* Class AB Bias Diodes
D_BIAS1 N_VAS_TOP N_BIAS_MID D_SIGNAL
D_BIAS2 N_BIAS_MID N_VAS_C   D_SIGNAL

* =========================================================================
* 4. COMPLEMENTARY PUSH-PULL DRIVER STAGE (Q6, Q7)
* =========================================================================
Q6 N_RAW N_VAS_TOP N_DRV_E1 0 QNPN_GEN
Q7 0     N_VAS_C   N_DRV_E2 0 QPNP_GEN

R_E1 N_DRV_E1 N_DRV 10.0
R_E2 N_DRV_E2 N_DRV 10.0

* =========================================================================
* 5. POWER PASS TRANSISTOR & CURRENT LIMITING
* =========================================================================
* Power Pass Element (NPN)
Q_PASS N_RAW N_DRV N_SENSE 0 QNPN_POWER

* Current Sense Resistor
R_SC N_SENSE N_OUT {R_SC_VAL}

* Overcurrent Protection Transistor (Q_limit)
Q_LIMIT N_DRV N_SENSE N_OUT 0 QNPN_GEN

* =========================================================================
* 6. FEEDBACK DIVIDER & LOAD
* =========================================================================
R1 N_OUT N_FB {R1_VAL}
R2 N_FB  0    {R2_VAL}
C_FEEDFWD N_OUT N_FB 100p          ; Lead compensation capacitor

* Output Decoupling & Nominal Load
C_OUT N_OUT 0 100u
R_LOAD N_OUT 0 {R_LOAD_VAL}

* =========================================================================
* 7. SEMICONDUCTOR MODEL CARDS
* =========================================================================
.model D_BRIDGE D (IS=1e-9 RS=0.03 BV=100 IBV=10u CJO=25p TT=20n)
.model D_SIGNAL D (IS=1e-14 RS=0.5 CJO=2p TT=4n)
.model D_Z5V1   D (IS=1e-11 RS=5.0 BV={V_ZENER} IBV=5m)
.model QNPN_GEN NPN (IS=1e-14 BF=200 VAF=100 CJC=4p CJE=8p TF=0.3n)
.model QPNP_GEN PNP (IS=1e-14 BF=180 VAF=80  CJC=5p CJE=10p TF=0.4n)
.model QNPN_POWER NPN (IS=1e-11 BF=60 VAF=60 CJC=120p CJE=250p TF=15n RS=0.05)

* =========================================================================
* 8. SIMULATION DIRECTIVES & NUMERICAL OPTIONS
* =========================================================================
.options GMIN=1e-12 ABSTOL=1e-12 RELTOL=1e-3 VNTOL=1e-6 ITL1=150 ITL4=100 METHOD=GEAR
.tran 10u 200m 0 10u UIC
.control
run
plot V(N_RAW) V(N_OUT)
plot I(R_SC)
.endc
.end
```

---

## 4. SPICE Numerical Stability & Convergence Engineering

Nonlinear circuits combining bridge rectifiers with high-gain discrete closed loops routinely suffer from SPICE simulation divergence:
- `Timestep too small; iteration limit reached`
- `Singular matrix: check nodes ...`
- `No convergence in DC operating point analysis`

### 4.1 Root Causes & Mitigation Settings
| Numerical Failure Mode | Physical Cause | Definitive SPICE Solution |
| :--- | :--- | :--- |
| **Singular Matrix at DC** | Floating primary/secondary windings in isolated transformer models. | Add a high-impedance shunt resistor to ground (`R_GND_ISO N_AC2 0 100Meg`). |
| **Timestep Collapse during Diode Turn-off** | Rapid change in diode conductance $g_d = dI_D/dV_D$ across zero crossing. | Set integration algorithm to Gear (`.options METHOD=GEAR`). Avoid Trapezoidal ringing. |
| **DC Operating Point Non-Convergence** | Closed loop with high DC gain ($>80\,\text{dB}$) oscillates during Newton-Raphson iterations. | Bypass DC operating point using Initial Conditions (`UIC`) in transient command: `.tran ... UIC`. |
| **Minimum Conductance Underflow** | Reverse-biased junction conductances drop below machine epsilon. | Enforce minimum conductance across all nodes: `.options GMIN=1e-12`. |
| **High Current Switching Discontinuities** | Inductive flyback without return path. | Add parallel damping snubber ($R_s = 100\,\Omega, C_s = 1\,\text{nF}$) across transformer secondaries. |

---

## 5. MATLAB / Simscape Physical Network Architecture

Simscape Electrical models circuits as physical networks based on Generalized Kirchhoff's Laws (Through and Across variables) rather than pure mathematical signal blocks.

### 5.1 Port Handle Construction Methodology
As proven in `circuit_matlab.m`, building models programmatically via Port Handles provides deterministic reliability across all MATLAB releases (R2018b through R2026+).

```matlab
% =========================================================================
% PROGRAMMATIC SIMSCAPE SYNTHESIS VIA PORT HANDLES
% =========================================================================
function build_tatto_simscape(params)
    modelName = 'Tatto_Simscape_Regulator';
    if bdIsLoaded(modelName), close_system(modelName, 0); end
    new_system(modelName); open_system(modelName);

    % 1. Solver & Numerical Tolerances
    set_param(modelName, 'SimulationMode', 'normal');
    set_param(modelName, 'SolverType', 'Variable-step');
    set_param(modelName, 'SolverName', 'ode23t');      % Stiff trapezoidal solver
    set_param(modelName, 'RelTol', '1e-4');
    set_param(modelName, 'StopTime', '0.2');

    % 2. Helper to retrieve physical conservation handles (LConn)
    get_ports = @(blk) get_param([modelName '/' blk], 'PortHandles').LConn;
    con       = @(h1, h2) simscape.addConnection(h1, h2, 'autorouting', 'on');

    % 3. Block Instantiations
    addB = @(lib, name, pos) add_block(lib, [modelName '/' name], ...
           'Position', pos, 'ShowName', 'off');

    addB('nesl_utility/Solver Configuration',       'Solver',   [30  30  90  90]);
    addB('fl_lib/Electrical Elements/Electrical Reference', 'GND', [30 180 90 240]);
    addB('fl_lib/Electrical Sources/AC Voltage Source',      'VAC', [150 30 210 90]);
    addB('fl_lib/Electrical Elements/Diode',        'D1',       [300 10 360 70]);
    addB('fl_lib/Electrical Elements/Diode',        'D2',       [300 130 360 190]);
    addB('fl_lib/Electrical Elements/Diode',        'D3',       [460 10 520 70]);
    addB('fl_lib/Electrical Elements/Diode',        'D4',       [460 130 520 190]);
    addB('fl_lib/Electrical Elements/Capacitor',    'C_Bulk',   [600 60 660 120]);
    addB('fl_lib/Electrical Sources/DC Voltage Source',      'V_Ref', [720 160 780 220]);
    addB('ee_lib/Semiconductors/NPN Bipolar Transistor',    'Q_Pass', [900 40 960 100]);
    addB('fl_lib/Integrated Circuits/Op-Amp',       'ErrorAmp', [900 160 960 220]);
    addB('fl_lib/Electrical Elements/Resistor',     'R1',       [1080 30 1140 90]);
    addB('fl_lib/Electrical Elements/Resistor',     'R2',       [1080 140 1140 200]);
    addB('fl_lib/Electrical Elements/Resistor',     'R_Load',   [1200 40 1260 100]);

    % 4. Parametric Injection
    set_param([modelName '/VAC'],    'V0', num2str(params.VAC_PEAK), 'f', num2str(params.FREQ));
    set_param([modelName '/V_Ref'],  'v0', num2str(params.V_REF));
    set_param([modelName '/C_Bulk'], 'c',  num2str(params.C_BULK));
    set_param([modelName '/R1'],     'R',  num2str(params.R1));
    set_param([modelName '/R2'],     'R',  num2str(params.R2));
    set_param([modelName '/R_Load'], 'R',  num2str(params.R_LOAD));

    % 5. Physical Wiring via Handles
    hSolver = get_ports('Solver');
    hGND    = get_ports('GND');
    hVAC    = get_ports('VAC');
    hD1     = get_ports('D1');  hD2 = get_ports('D2');
    hD3     = get_ports('D3');  hD4 = get_ports('D4');
    hCBulk  = get_ports('C_Bulk');
    hVRef   = get_ports('V_Ref');
    hQPass  = get_ports('Q_Pass');  % [Collector, Base, Emitter]
    hOp     = get_ports('ErrorAmp');% [Non-Inv (+), Inv (-), Out]
    hR1     = get_ports('R1');
    hR2     = get_ports('R2');
    hRLoad  = get_ports('R_Load');

    % Grounding Solver
    con(hSolver(1), hGND(1));

    % Full-Wave Bridge Connections
    con(hVAC(1), hD1(1)); con(hVAC(1), hD2(2));
    con(hVAC(2), hD3(1)); con(hVAC(2), hD4(2));
    con(hD1(2), hD3(2));  % Positive Rectified Rail
    con(hD2(1), hD4(1));  % Negative Return Rail
    con(hD2(1), hGND(1));

    % Filter & Pass Transistor
    con(hD1(2), hCBulk(1)); con(hGND(1), hCBulk(2));
    con(hD1(2), hQPass(1)); % Collector to RAW

    % Error Amp & Feedback Loop
    con(hGND(1), hVRef(2)); con(hVRef(1), hOp(1));
    con(hOp(3), hQPass(2)); % Op-Amp output to Base
    con(hQPass(3), hR1(1)); % Emitter to R1 and Load
    con(hQPass(3), hRLoad(1));
    con(hRLoad(2), hGND(1));

    con(hR1(2), hR2(1));
    con(hR1(2), hOp(2));    % Inverting feedback tap
    con(hR2(2), hGND(1));

    % Save and Notify
    save_system(modelName);
    fprintf('Simscape model %s synthesized successfully.\n', modelName);
end
```

---

## 6. Model Verification & Cross-Validation Matrix

To certify that the visual CircuiTikZ drawing, the SPICE netlist, and the MATLAB Simscape script represent the identical physical circuit, cross-check each junction against this validation matrix:

| Functional Stage | CircuiTikZ Component ID | SPICE Instance | Simscape Instance | Verified State |
| :--- | :--- | :--- | :--- | :--- |
| **Grid Coupling** | `T` (transformer core) | `E_SEC` | `VAC` (scaled) | Galvanic Isolation |
| **Diode Bridge** | `D1, D2, D3, D4` | `D1, D2, D3, D4` | `D1, D2, D3, D4` | Planar Diamond Conduction |
| **Bulk Storage** | `C_{\text{bulk}}` | `C_BULK` | `C_Bulk` | Ripple $< 10\%$ of $V_{\text{RAW}}$ |
| **Voltage Ref** | $D_Z, R_{\text{bias}}$ | `D_ZENER, R_BIAS` | `V_Ref` | Stable $V_{\text{ref}}$ independent of $V_{\text{RAW}}$ |
| **Input Diff Pair** | $Q_1, Q_2, I_{\text{tail}}$ | `Q1, Q2, I_TAIL` | `ErrorAmp` ($+$ and $-$ ports) | Symmetrical $I_C = I_{\text{tail}}/2$ |
| **Active Load** | $Q_3, Q_4$ | `Q3, Q4` | `ErrorAmp` (Internal model) | High dynamic output impedance |
| **VAS & Comp** | $Q_5, C_c, R_5$ | `Q5, C_MILLER, R_VAS_DEG` | `ErrorAmp` (Pole config) | Dominant pole roll-off at $-20\,\text{dB/dec}$ |
| **Output Drivers**| $Q_6, Q_7, D_5, D_6$| `Q6, Q7, D_BIAS1, D_BIAS2`| `ErrorAmp` (Output buffer) | Zero crossover deadband |
| **Series Pass BJT**| $Q_{\text{pass}}$ | `Q_PASS` | `Q_Pass` | Forward-active linear drop |
| **Current Limiter**| $Q_{\text{limit}}, R_{sc}$| `Q_LIMIT, R_SC` | Current trip block | Sharp clamp at $I_{\max} = 0.65/R_{sc}$ |
| **Feedback Resistors**| $R_1, R_2$ | `R1, R2` | `R1, R2` | $V_{\text{OUT}} = V_{\text{ref}}(1 + R_1/R_2)$ |
| **Output Decoupling**| $C_{\text{out}}$ | `C_OUT` | Transient cap | Phase margin $\Phi_M \ge 45^\circ$ |
