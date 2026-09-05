# Primary Simulation Repositories & Academic Theory Synthesis

> **Target Workspace:** `KnowledgeBase`  
> **Status:** Authoritative Primary Source Synthesis  
> **Referenced Primary Documents:**
> 1. Repository: `Dominik-Workshop/linear-power-supply` (GitHub: https://github.com/Dominik-Workshop/linear-power-supply)
> 2. Repository & Model: `harismuneer/Full-Wave-Bridge-Rectifier` (GitHub: https://github.com/harismuneer/Full-Wave-Bridge-Rectifier) & MathWorks Simscape Electrical Reference Models
> 3. Authoritative Application Report: National Semiconductor / Texas Instruments AN-1148 / AN-1188 (`snva020.pdf`, `snva558.pdf`) by Chester Simpson: *"Linear Regulators: Theory of Operation and Compensation"*

---

## 1. Dominik-Workshop Linear Power Supply (250W Discrete Architecture)

### 1.1 Overview & System Specifications
The `Dominik-Workshop/linear-power-supply` project provides a fully documented, open-source 250W (`0–28V`, `0.01–10A`) lab-grade linear power supply. The physical build incorporates:
- **Modified Mains Transformer:** 300VA, 12V reconfigured secondary split into series windings to achieve 24VAC with center tap plus auxiliary 8VAC bias winding.
- **Pre-regulation Relay Switching:** Automatic transformer secondary tap selection based on output voltage setting to minimize heat dissipation across the series pass element.
- **Pass Transistor Heat Dissipation:** Massive graphics card heatsink with active thermal fan control.

### 1.2 The Critical Stability Finding: MOSFET vs. BJT Driver
The original design utilized an `IRF9530` P-channel power MOSFET for intermediate driving. Empirical physical bench testing and LTspice simulations revealed severe transient instability and sustained oscillation in **Constant Current (CC)** mode.

**Root Cause:**
- The high gate-source capacitance ($C_{iss} \approx 500\text{ pF}$) and gate-drain Miller capacitance ($C_{rss}$) of the power MOSFET introduced an additional low-frequency pole into the high-gain feedback loop.
- The transconductance non-linearity ($g_m = \frac{\partial I_D}{\partial V_{GS}}$) of the MOSFET over a 1000:1 load current dynamic range shifted the loop crossover frequency into unstable phase margin territory.

**Drop-in Replacement Resolution:**
- Replacing the `IRF9530` with a `BD912` (or `2SA2094`) **PNP BJT** completely eradicated CC-mode oscillations and vastly improved step recovery time.
- The base-emitter junction current-drive characteristic decoupled the voltage error amplifier from capacitive gate pole loading.

```
[LM358 Error Amp] ---> [BC337-40 NPN Pre-Driver] ---> [BD912 PNP Driver] ---> [4x 2N3055 NPN Pass]
```

### 1.3 Detailed Circuit Netlist & Topology Decomposition
Extracted directly from `simulations/v2-fix_oscilations/new_transient.asc` and `new_bode.asc`:

- **Operational Amplifiers:** Dual LM358 powered from isolated +15V auxiliary rail.
  - `U1`: Voltage regulation error amplifier (Inverting terminal receives divider feedback; Non-inverting receives reference set voltage `V_set`).
  - `U2`: Current limit error amplifier (Monitors drop across current shunt resistor `R13`).
- **Diode-OR Auctioneering:** `D1` (1N5819 Schottky diode) joins the outputs of `U1` and `U2`. If the current limit threshold is exceeded, `U2` pulls down the drive node through `D1`, seamlessly overriding voltage control.
- **Pre-driver Stage:** `Q1` (BC337-40 NPN) in common-emitter configuration driving the base of `Q6`.
- **Driver Stage:** `Q6` (2SA2094 / BD912 PNP) providing high base drive current to the parallel output bank.
- **Output Power Pass Bank:** 4x `2N3055` NPN power transistors connected in parallel.
  - Base sharing with individual collector ties to unregulated DC rail (`VIN = +30V`).
  - **Ballast / Current-Sharing Resistors:** `R9`, `R10`, `R11`, `R12` ($0.1\,\Omega$, 5W each) in series with each 2N3055 emitter to prevent thermal runaway.
- **Current Shunt Sensor:** `R13` ($0.05\,\Omega$) placed in the return rail.
- **Feedback Divider:** `R1 = 47\text{ k}\Omega`, `R2 = 10\text{ k}\Omega` (attenuation factor $\beta = \frac{10}{57} \approx 0.175$).
- **Frequency Compensation Networks:**
  - `C2 = 1\text{ nF}` across voltage error amplifier.
  - `R8 = 5.6\text{ k}\Omega` and `C3 = 100\text{ nF}` pole-zero stabilization network.
  - `C4 = 100\text{ nF}` across current sense input.
  - Output Bulk Filter: `C1 = 10\,\mu\text{F}` with modeled ESR `R14 = 1\,\Omega`.

---

## 2. Haris Muneer Bridge Rectifier & Simscape Mathematical Modeling

### 2.1 Full-Wave Bridge Rectifier Topology
The primary model converts 120VAC / 60Hz mains down to low-voltage AC, then passes it through a 4-diode full-wave Graetz bridge (`D1`–`D4`) followed by a shunt capacitor filter.

```
       AC Input L1 ──┬──────┬───|>|─── (D1) ───┬─────── (+) Raw DC
                     │      │                  │
                     │      └───|<|─── (D3) ───┼──┐
                     │                         │  │
       AC Input L2 ──┴──────┬───|>|─── (D2) ───┘  │
                            │                     │
                            └───|<|─── (D4) ──────┴─── (-) Ground Return
```

- **Positive Half-Cycle ($0 \le \omega t < \pi$):** Line 1 is positive relative to Line 2. Current flows through `D1` $\rightarrow$ Load / Capacitor $\rightarrow$ `D4` $\rightarrow$ Line 2. Diodes `D2` and `D3` are reverse-biased.
- **Negative Half-Cycle ($\pi \le \omega t < 2\pi$):** Line 2 is positive relative to Line 1. Current flows through `D2` $\rightarrow$ Load / Capacitor $\rightarrow$ `D3` $\rightarrow$ Line 1. Diodes `D1` and `D4` are reverse-biased.

### 2.2 Mathematical Equations for 120VAC $\rightarrow$ 12VDC Design
For a nominal secondary output delivering $V_{out(DC)} = 12\text{ V}$ at maximum load current $I_{load} = 2.0\text{ A}$:

1. **Transformer Turns Ratio ($N_p / N_s$):**
   Given $V_{pri,RMS} = 120\text{ V}$ and required secondary RMS voltage $V_{sec,RMS}$:
   $$V_{pk} = \sqrt{2} \cdot V_{sec,RMS} - 2 V_D$$
   Allowing a $2 V_D = 1.6\text{ V}$ drop across standard silicon rectifiers (or $0.8\text{ V}$ for Schottky) and reserving $3.0\text{ V}$ headroom for regulator dropout and ripple troughs ($V_{min} \ge 15.0\text{ V}$ raw DC):
   $$V_{pk} = 15.0\text{ V} + V_{ripple(p-p)} \approx 18.0\text{ V}$$
   $$V_{sec,RMS} = \frac{18.0 + 1.6}{\sqrt{2}} = \frac{19.6}{1.414} \approx 13.86\text{ V}_{RMS}$$
   $$n = \frac{N_p}{N_s} = \frac{120}{13.86} \approx 8.66$$

2. **Filter Capacitor Sizing Formula:**
   Between replenishment peaks, the filter capacitor discharges into the load resistance $R_L = \frac{V_{DC}}{I_{load}}$.
   In a full-wave rectifier at mains frequency $f = 60\text{ Hz}$, the discharge period is $T_{dis} \approx \frac{1}{2f} = \frac{1}{120\text{ Hz}} = 8.33\text{ ms}$.
   $$\Delta V = V_{ripple(p-p)} = \frac{I_{load} \cdot \Delta t}{C} \approx \frac{I_{load}}{2 f C}$$
   Rearranging for required smoothing capacitance $C$:
   $$C = \frac{I_{load}}{2 \cdot f \cdot V_{ripple(p-p)}}$$
   For $I_{load} = 2.0\text{ A}$ and targeting a maximum ripple of $V_{ripple(p-p)} = 1.0\text{ V}$:
   $$C = \frac{2.0\text{ A}}{2 \cdot 60\text{ Hz} \cdot 1.0\text{ V}} = \frac{2.0}{120} = 16,667\,\mu\text{F}$$
   *(Selected standard value: $18,000\,\mu\text{F}$ or $2 \times 10,000\,\mu\text{F}$ in parallel, rated at $35\text{V}$)*.

3. **Diode Conduction Angle & Surge Current:**
   The diodes only conduct during the brief window $\Delta t_c$ when the sinusoidal input exceeds the capacitor voltage:
   $$\theta_c = \arccos\left(1 - \frac{V_{ripple}}{V_{pk}}\right) \approx \sqrt{\frac{2 V_{ripple}}{V_{pk}}}$$
   For $V_{ripple} = 1.0\text{ V}$, $V_{pk} = 18\text{ V}$:
   $$\theta_c \approx \sqrt{\frac{2}{18}} = 0.333\text{ rad} \approx 19.1^\circ$$
   The peak repetitive forward current $I_{FRM}$ through each diode is dramatically higher than the average load current:
   $$I_{peak} \approx I_{load} \cdot \left(1 + \pi \sqrt{\frac{2 V_{pk}}{V_{ripple}}}\right) = 2.0 \cdot (1 + \pi \cdot 6) \approx 39.7\text{ A}$$
   This demonstrates why rectifier diodes must be rated for high repetitive peak surges (e.g., `1N5408` or a 10A–25A integrated bridge module like `KBPC2504`).

---

## 3. Chester Simpson / TI AN-1148 & AN-1188: Linear Regulator Loop Stability

### 3.1 Linear Regulator Topologies Compared
In Application Report AN-1148 (`snva020.pdf`) and AN-1188 / Fundamentals Part 1 (`snva558.pdf`), Chester Simpson classifies linear regulators based on their pass element configuration:

| Topology | Pass Device Configuration | Minimum Dropout ($V_{drop}$) | Output Impedance | Quiescent Current ($I_q$) Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Standard NPN** | NPN Darlington Common-Collector | $2 V_{BE} + V_{CE(sat)} \approx 1.5\text{V} - 2.2\text{V}$ | Low ($Z_{out} \approx 1/g_m$) | Low; base current flows directly into load |
| **Quasi-LDO** | NPN driven by PNP | $V_{BE} + V_{CE(sat)} \approx 0.9\text{V} - 1.2\text{V}$ | Moderate | Low; driver current to ground is small |
| **True LDO** | PNP Common-Emitter | $V_{CE(sat)} \approx 0.1\text{V} - 0.4\text{V}$ | High ($Z_{out} \approx r_o \parallel R_L$) | Increases proportionally with load current |
| **CMOS LDO** | P-MOSFET Common-Source | $I_{load} \cdot R_{DS(on)} \approx 0.05\text{V} - 0.2\text{V}$ | High ($Z_{out} \approx r_{ds} \parallel R_L$) | Ultra-low; gate is voltage-driven |

### 3.2 Loop Transfer Function & Pole-Zero Formulations
A linear regulator's small-signal feedback loop consists of:
$$T(s) = A_{EA}(s) \cdot G_{pass}(s) \cdot \beta$$
where $\beta = \frac{R_2}{R_1 + R_2}$ is the feedback divider ratio.

The loop contains multiple critical poles and zeros that govern stability:

1. **Dominant Internal Amplifier Pole ($P_{int}$):**
   Established at the high-impedance output node of the internal error amplifier:
   $$P_{int} = \frac{1}{2 \pi \cdot R_{amp} \cdot C_{comp}}$$
   Typically set deliberately low ($10\text{ Hz} - 100\text{ Hz}$) to provide high DC gain and establish a single-pole $-20\text{ dB/decade}$ roll-off.

2. **Load-Dependent Output Pole ($P_L$):**
   Determined by the total output capacitance and effective load resistance:
   $$P_L = \frac{1}{2 \pi \cdot R_L \cdot C_{out}} = \frac{I_{load}}{2 \pi \cdot V_{out} \cdot C_{out}}$$
   *Crucial Stability Insight:* In a standard NPN regulator, because the pass transistor is an emitter follower (low output resistance), $P_L$ is pushed to very high frequencies outside the unity-gain bandwidth.  
   **However, in an LDO (PNP or PMOS), the output transistor operates in common-emitter mode with high output impedance.** Consequently, $P_L$ moves directly into the active loop bandwidth ($100\text{ Hz} - 100\text{ kHz}$) as $I_{load}$ varies!

3. **Parasitic Pass Element Pole ($P_{pass}$):**
   Formed by the base/gate input capacitance and driver stage impedance:
   $$P_{pass} = \frac{1}{2 \pi \cdot r_\pi \cdot C_{in(pass)}}$$
   Typically located between $500\text{ kHz}$ and $5\text{ MHz}$.

4. **Output Capacitor ESR Zero ($Z_{esr}$):**
   Introduced by the equivalent series resistance of the output bulk filtering capacitor:
   $$Z_{esr} = \frac{1}{2 \pi \cdot \text{ESR} \cdot C_{out}}$$

### 3.3 The ESR Zero Compensation Mechanism & "Tunnel of Stability"
In an LDO, the simultaneous presence of two low-frequency poles ($P_{int}$ and $P_L$) produces a $-40\text{ dB/decade}$ gain roll-off and a **$-180^\circ$ phase shift**. This reduces the phase margin to zero before the unity-gain ($0\text{ dB}$) crossover frequency ($f_{0dB}$), causing spontaneous oscillation.

The ESR zero ($Z_{esr}$) is the essential stabilizing element:
- It introduces a $+45^\circ$/decade phase lead starting one decade below $Z_{esr}$, contributing up to $+90^\circ$ of phase boost.
- It changes the loop gain slope from $-40\text{ dB/decade}$ back to a stable $-20\text{ dB/decade}$.

```
Gain (dB)
 ^
 |    \ -20 dB/dec (P_int)
 |      |      \           \ -40 dB/dec (P_L adds another pole)
 |       \            |        \           \           /-- -20 dB/dec (Z_esr cancels P_L!)
 |         \           \         /
 0 dB ------------------\-------x--------------------------> Frequency
                         \     /                           \   /   \ -40 dB/dec (P_pass)
                           \ /
```

#### The Stability Boundary Conditions:
1. **Upper ESR Limit ($	ext{ESR}_{max}$):**
   If ESR is excessively large, $Z_{esr}$ occurs at too low a frequency. The loop gain flattens out, extending the $0\text{ dB}$ crossover frequency $f_{0dB}$ beyond the parasitic pole $P_{pass}$. When $f_{0dB} > P_{pass}$, the phase drops precipitously and the circuit oscillates.
2. **Lower ESR Limit ($	ext{ESR}_{min}$):**
   If ESR is too small (e.g., substituting low-ESR ceramic capacitors for legacy tantalum or electrolytic capacitors), $Z_{esr}$ is pushed far above $f_{0dB}$. The loop crosses $0\text{ dB}$ with a $-40\text{ dB/decade}$ slope and $-180^\circ$ phase shift, resulting in sustained oscillations!
3. **The Stability Region:**
   Stable regulator operation requires operating strictly within the "Tunnel of Stability" where:
   $$\text{ESR}_{min} \le \text{ESR} \le \text{ESR}_{max}$$
   over the entire operating temperature range (accounting for the fact that electrolytic capacitor ESR increases by up to $10\times$ at $-40^\circ\text{C}$).

---

## 4. Synthesis for the Tatto Hardware Architecture

| Stage | Design Decision | Justification from Primary Sources |
| :--- | :--- | :--- |
| **AC Input & Rectifier** | 120VAC $\rightarrow$ 14VAC RMS Transformer with 25A Bridge & $18,000\,\mu\text{F}$ Filter | Ensures $V_{min} \ge 15\text{V}$ raw DC under full 2A load with $V_{ripple(p-p)} \le 1.0\text{V}$, satisfying Haris Muneer & Simscape models. |
| **Pass Driver Stage** | Discrete BJT Darlington / Complementary Driver (`BC337` + `BD912`) driving `2N3055` | Eliminates MOSFET capacitive gate pole instability as empirically verified by Dominik-Workshop. |
| **Ballast Resistors** | $0.1\,\Omega$ 5W emitter resistors on all parallel pass transistors | Enforces equal current sharing and eliminates thermal runaway across the pass bank. |
| **Output Stage Compensation** | $10\,\mu\text{F}$ Bulk Output Cap with deliberate $1.0\,\Omega$ series ESR resistor | Positions $Z_{esr} = \frac{1}{2\pi \cdot 1.0 \cdot 10\mu\text{F}} \approx 15.9\text{ kHz}$, precisely canceling the load pole and satisfying Chester Simpson's AN-1148 stability criterion. |
