# Transformer, Rectifier & Bulk Filter Theory: Parametric Modeling & Dynamics

**Document ID:** `KB-TATTO-003`  
**Classification:** Technical Reference / Mathematical Foundations  
**Project:** Tatto Linear Power Supply (Silicon Architecture)  
**Standard:** IEEE Std C57.12.00 / IEC 60076 / JEDEC Solid-State Standards  

---

## 1. Executive Overview & Parametric Agnosticism

The power input subsystem of the Tatto architecture provides galvanic isolation, voltage scaling, bidirectional rectification, and capacitive energy storage. In conformance with Project Tatto's **Parametric Agnosticism Requirement**, all mathematical formulations and schematic symbols are defined symbolically. 

Whether operating on a primary grid of $120\,\text{V}_{\text{RMS}}$ stepped down to $12\,\text{V}_{\text{DC}}$ or an industrial line of $1200\,\text{V}_{\text{RMS}}$ stepped down to $1.2\,\text{V}_{\text{DC}}$, the underlying equations of state, dimensionless ratios, and topology remain identical.

```
       +-----------------+     +---------------+     +----------------+
v_AC   |   Transformer   |     | Full-Wave     |     | Bulk & HF      |   V_RAW
------>|       T_1       |---->| Diode Bridge  |---->| Filter (C_bulk,|--------->
(Grid) | (Ratio 1:k_T)   |     | (D1 - D4)     |     |  C_in)         |   (Unreg)
       +-----------------+     +---------------+     +----------------+
```

---

## 2. Transformer Physics & Parametric Equivalent Circuit

### 2.1 Ideal vs. Non-Ideal Transformer Modeling
The transformer $T_1$ provides galvanic isolation and voltage conversion via magnetic flux coupling.

```
          R_p      L_lk,p                    L_lk,s     R_s
   o----/\/\/\----UUUU----+              +----UUUU----/\/\/\----o (B1)
                          |    |    |    |
                         ( )  ( )  ( )  ( )
                    R_c  ( )  ( )  ( )  ( )
               +---/\/\/-+ |  ( )  ( )  | +---o
               |         | |  ( )  ( )  |
               +---UUUU--+ |   Ideal    |
                    L_m    |   1 : n    |
   o----------------------+              +----------------------o (B2)
                          Primary      Secondary
```

#### Fundamental Relations:
1. **Turns Ratio ($n$):**
   $$n = \frac{N_s}{N_p} = \frac{v_{sec}(t)}{v_{pri}(t)} = \frac{i_{pri}(t)}{i_{sec}(t)}$$
2. **Normalized Voltage Scaling Factor ($k_T$):**
   $$k_T = \frac{\hat{V}_{sec}}{\hat{V}_{pri}} = n$$
3. **Primary-Referred Total Leakage Inductance ($L_{lk}$):**
   $$L_{lk,eq} = L_{lk,p} + \frac{L_{lk,s}}{n^2}$$
4. **Primary-Referred Winding Resistance ($R_{w}$):**
   $$R_{w,eq} = R_p + \frac{R_s}{n^2}$$

### 2.2 Core Magnetization & Saturation Limits
The magnetizing current $i_m(t)$ is governed by Faraday's law of induction:
$$v_{pri}(t) = N_p \frac{d\Phi(t)}{dt} = N_p A_c \frac{dB(t)}{dt}$$

Integrating over a steady-state half-cycle of frequency $f_{ac} = \frac{\omega}{2\pi}$:
$$\hat{B} = \frac{\hat{V}_{pri}}{2\pi f_{ac} N_p A_c} \le B_{sat}$$
where:
- $A_c$ is the effective magnetic cross-sectional core area ($\text{m}^2$).
- $B_{sat}$ is the core saturation flux density (typically $1.2\text{--}1.6\,\text{T}$ for silicon steel, $0.3\text{--}0.4\,\text{T}$ for ferrites).

---

## 3. Full-Wave Diode Bridge Rectification Dynamics

### 3.1 Conduction State Sequence
The planar diode bridge ($D_1, D_2, D_3, D_4$) alternates between two conduction pairs over each AC period $T = 1/f_{ac}$:

| AC Half-Cycle Condition | Active Diode Pair | Current Flow Path | Output State $v_{rect}(t)$ |
| :--- | :--- | :--- | :--- |
| $v_{sec}(t) > +2V_F$ (Positive) | $D_1$ and $D_4$ | $B_1 \to D_1 \to V_{\text{RAW}} \to \text{Load} \to \text{GND} \to D_4 \to B_2$ | $+v_{sec}(t) - 2V_F$ |
| $v_{sec}(t) < -2V_F$ (Negative) | $D_2$ and $D_3$ | $B_2 \to D_2 \to V_{\text{RAW}} \to \text{Load} \to \text{GND} \to D_3 \to B_1$ | $-v_{sec}(t) - 2V_F$ |
| $|v_{sec}(t)| < 2V_F$ (Deadband) | None (All OFF) | Open circuit (Filter capacitor discharges into load) | $v_C(t)$ (Floating source) |

### 3.2 Diode Physical Parameters & Stress Limits
1. **Shockley Diode Characteristic:**
   $$I_D = I_S \left( e^{\frac{V_D}{n_D V_T}} - 1 \right)$$
   where $V_T = \frac{k_B T_K}{q} \approx 25.86\,\text{mV}$ at $300\,\text{K}$, $I_S$ is the reverse saturation current, and $n_D$ is the ideality factor ($1 \le n_D \le 2$).
2. **Forward Voltage Drop ($V_F$):**
   $$V_F(I_D) \approx n_D V_T \ln\left(\frac{I_D}{I_S}\right) + I_D \cdot r_d$$
   where $r_d = \frac{dV_D}{dI_D}$ is the bulk semiconductor series resistance. Total bridge drop is $2V_F \approx 1.4\text{ V}$ for standard silicon, $0.7\text{--}0.8\text{ V}$ for Schottky.
3. **Peak Inverse Voltage (PIV / $V_{RRM}$):**
   When $D_1, D_4$ conduct, the reverse voltage across non-conducting diodes $D_2, D_3$ reaches:
   $$V_{\text{PIV}} = \hat{V}_{sec} - V_F \approx \hat{V}_{sec}$$
   A mandatory engineering safety margin enforces:
   $$V_{RRM,rated} \ge 1.5 \cdot \hat{V}_{sec}$$

---

## 4. Filter Capacitor Dynamics & Analytical Waveforms

### 4.1 Steady-State Conduction Angle & Ripple Sizing
The bulk capacitor $C_{\text{bulk}}$ charges to the peak rectified voltage $\hat{V}_{\text{RAW}} = \hat{V}_{sec} - 2V_F$ during the brief conduction interval $\Delta t_c = t_2 - t_1$.

```
 Voltage
   ^
   |        Peak: V_pk = V_sec,pk - 2*V_F
   |          /\                /\
   |         /  \  Ripple Delta /  \
   |        /    \----\_       /    \----\_
   |       /            \     /            \
   |      /   Charge     \   /   Discharge  \
   |_____/____(Delta t)___\_/________________\____> Time
        0      t1  t2        T/2
```

1. **Discharge Interval ($t_2 \to T/2 + t_1$):**
   During diode cutoff, the bulk capacitor discharges solely through the total load current $I_{\text{load}}$:
   $$v_{\text{RAW}}(t) = \hat{V}_{\text{RAW}} \cdot e^{-\frac{t - t_2}{R_L C_{\text{bulk}}}}$$
2. **Linear Small-Ripple Approximation ($\Delta V_{rip} \ll \hat{V}_{\text{RAW}}$):**
   Because the discharge time is approximately equal to the half-period $T_{rect} = \frac{1}{2 f_{ac}}$:
   $$\Delta V_{rip} \approx \frac{I_{\text{load}}}{2 f_{ac} C_{\text{bulk}}}$$
   Rearranging for minimal bulk capacitance:
   $$C_{\text{bulk}} \ge \frac{I_{\text{load,max}}}{2 f_{ac} \Delta V_{rip,max}}$$

### 4.2 Repetitive Peak Diode Surge Current ($I_{D,pk}$)
Because all energy consumed by the load over half-cycle $T/2$ must be replenished during the short conduction window $\Delta t_c$:
$$\Delta t_c \approx \frac{1}{\omega} \sqrt{\frac{2 \Delta V_{rip}}{\hat{V}_{\text{RAW}}}}$$
The average conduction angle is $\theta_c = \omega \Delta t_c$. By conservation of charge:
$$Q_{chg} = I_{D,avg} \cdot \Delta t_c = I_{\text{load}} \cdot \frac{T}{2}$$
Assuming a triangular/sinusoidal surge shape, the peak repetitive diode current is:
$$I_{D,pk} \approx I_{\text{load}} \left( 1 + \pi \sqrt{\frac{2 \hat{V}_{\text{RAW}}}{\Delta V_{rip}}} \right)$$
> [!IMPORTANT]
> A smaller ripple $\Delta V_{rip}$ requires a larger $C_{\text{bulk}}$, which sharpens the charging spike and dramatically increases $I_{D,pk}$ and capacitor RMS ripple current stress.

### 4.3 Capacitor Ripple Current Stress & Thermal Dissipation
The total RMS current flowing through $C_{\text{bulk}}$ produces ohmic heating across its internal Equivalent Series Resistance ($\text{ESR}$):
$$I_{C,rms} \approx I_{\text{load}} \sqrt{\frac{\pi}{2 \theta_c}} \approx I_{\text{load}} \sqrt{\frac{\pi}{\sqrt{8 \frac{\Delta V_{rip}}{\hat{V}_{\text{RAW}}}}}}$$
Internal thermal power dissipation:
$$P_{cap} = I_{C,rms}^2 \cdot \text{ESR}$$
To prevent thermal breakdown and electrolyte dry-out, $I_{C,rms}$ must not exceed the manufacturer's rated ripple current at operating ambient temperature.

### 4.4 High-Frequency Bypass Decoupling ($C_{\text{in}}$)
Electrolytic bulk capacitors exhibit significant parasitic inductance (Equivalent Series Inductance, $\text{ESL} \approx 10\text{--}50\,\text{nH}$) and high $\text{ESR}$ at radio frequencies. 

A high-frequency multi-layer ceramic capacitor (MLCC, $C_{\text{in}} \approx 100\,\text{nF} \to 1\,\mu\text{F}$) is placed in immediate parallel with $C_{\text{bulk}}$:
$$Z_{in}(s) = \left( \text{ESR}_{bulk} + s\text{ESL}_{bulk} + \frac{1}{s C_{bulk}} \right) \parallel \left( \text{ESR}_{in} + s\text{ESL}_{in} + \frac{1}{s C_{in}} \right)$$
This guarantees low impedance ($|Z| < 0.1\,\Omega$) across decades of frequency ($10\,\text{kHz} \to 100\,\text{MHz}$), absorbing diode snap-off reverse recovery spikes ($t_{rr}$).

---

## 5. Mathematical Formulations for CircuiTikZ Oscilloscope Plots

In the Tatto architecture, embedded oscilloscopes plot mathematically pure equations using TikZ `plot[domain=..., samples=...]`. The domain maps to normalized time $x \in [-1.1, 1.1]$:

### 5.1 Primary AC Waveform (Scope 1)
Pure sinusoidal voltage from the primary power grid:
$$y_1(x) = A_1 \sin\left( 2\pi \cdot \frac{x}{X_{scale}} \right)$$
- TikZ Implementation: `plot[domain=-1.1:1.1, samples=60] (\x, {0.65*sin(360*\x/1.1)})`

### 5.2 Secondary Scaled AC Waveform (Scope 2)
Stepped-down isolated AC voltage across transformer secondary terminals $B_1, B_2$:
$$y_2(x) = k_T \cdot A_1 \sin\left( 2\pi \cdot \frac{x}{X_{scale}} \right)$$
- TikZ Implementation: `plot[domain=-1.1:1.1, samples=60] (\x, {0.45*sin(360*\x/1.1)})`

### 5.3 Full-Wave Rectified Waveform (Scope 3)
Absolute value of the secondary voltage minus two diode forward drops ($2V_F$):
$$y_3(x) = |A_2 \sin(2\pi x / X_{scale})| - V_{drop}$$
- TikZ Implementation: `plot[domain=-1.1:1.1, samples=80] (\x, {0.70*abs(sin(360*\x/1.1)) - 0.25})`

### 5.4 Bulk Filtered DC Waveform with Ripple (Scope 4)
Piecewise combination of exponential/linear discharge and rapid sinusoidal recharge:
$$y_4(x) = V_{DC,avg} + \Delta V_{rip} \cdot \left[ 1 - \frac{\text{mod}(x + x_0, T_{half})}{T_{half}} \right]$$
- TikZ Implementation: `plot[domain=-1.1:1.1, samples=100] (\x, {0.35 + 0.18*(1 - mod(\x+1.1, 0.55)/0.55)})`

### 5.5 Final Regulated Constant DC (Scope 5)
Pure, ripple-free flat direct current:
$$y_5(x) = V_{OUT}$$
- TikZ Implementation: `\draw[scope_wave] (-1.1, 0.35) -- (1.1, 0.35);`

---

## 6. Parametric Scaling Matrix

| Parameter Description | Normalized Symbol | Low-Voltage Rail Design | Industrial Medium-Voltage |
| :--- | :--- | :--- | :--- |
| **Grid Input ($v_{\text{AC}}$)** | $V_{pri,\text{RMS}}$ | $120.0\,\text{V}_{\text{RMS}} \pm 10\%$ | $1200.0\,\text{V}_{\text{RMS}} \pm 10\%$ |
| **Turns Ratio ($n$)** | $k_T = N_s / N_p$ | $0.125$ ($8:1$ step-down) | $0.002$ ($500:1$ step-down) |
| **Secondary Peak ($\hat{V}_{sec}$)** | $\sqrt{2} \cdot n \cdot V_{pri}$ | $21.21\,\text{V}_{\text{pk}}$ | $3.39\,\text{V}_{\text{pk}}$ |
| **Bridge Drop ($2V_F$)** | $2 \cdot V_F$ | $1.40\,\text{V}$ (Silicon PN) | $0.70\,\text{V}$ (Schottky) |
| **Unregulated Rail ($\hat{V}_{\text{RAW}}$)**| $\hat{V}_{sec} - 2V_F$ | $19.81\,\text{V}$ | $2.69\,\text{V}$ |
| **Nominal Output ($V_{\text{OUT}}$)** | $V_{\text{OUT}}$ | $12.0\,\text{V}_{\text{DC}}$ | $1.20\,\text{V}_{\text{DC}}$ |
| **Maximum Load ($I_{\text{load}}$)** | $I_{L,max}$ | $1.50\,\text{A}$ | $10.0\,\text{A}$ |
| **Bulk Cap ($C_{\text{bulk}}$)** | $\frac{I_L}{2 f \Delta V_{rip}}$ | $2200\,\mu\text{F}$ ($\Delta V_{rip} \approx 2.8\,\text{V}$) | $47000\,\mu\text{F}$ ($\Delta V_{rip} \approx 0.88\,\text{V}$) |
| **HF Decoupling ($C_{\text{in}}$)** | $C_{\text{in}}$ | $100\,\text{nF} \pm 10\%$ X7R | $1.0\,\mu\text{F} \pm 10\%$ X7R |
