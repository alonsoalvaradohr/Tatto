# Discrete Linear Voltage Regulator Topology: Silicon Architecture & Closed-Loop Stability

**Document ID:** `KB-TATTO-004`  
**Classification:** Technical Reference / Silicon Architecture Specification  
**Project:** Tatto Linear Power Supply (Silicon Architecture)  
**Standard:** IEEE Std 1451 / JEDEC Discrete Semiconductor Design / Bode Stability Criteria  

---

## 1. System Topology Overview & Functional Decomposition

The Tatto linear voltage regulator is a discrete, multi-stage, high-gain negative-feedback servo system implemented at the transistor level. Rather than treating the error amplifier as an idealized monolithic operational amplifier, the circuit exposes all internal silicon blocks:

```
  +---------------------------------------------------------------------------------------------------------+
  |                                        DISCRETE LINEAR REGULATOR                                        |
  |                                                                                                         |
  |  +----------------+        +--------------------+        +----------------+        +-----------------+  |
  |  | Reference Gen  |------->| Differential Pair  |------->| High-Gain VAS  |------->| Push-Pull       |  |
  |  | (R_bias, D_Z)  | V_ref  | (Q1-Q2, Mirror Q3-4| N2     | (Q5, Miller Cc)| DRV    | Driver (Q6-Q7)  |  |
  |  +----------------+        +---------^----------+        +----------------+        +--------+--------+  |
  |                                      |                                                      |           |
  |                                      | V_FB                                                 | I_base    |
  |                                      |                                                      v           |
  |      V_OUT    +----------------------+-----------+        +----------------+       +--------+--------+  |
  |  <------------| Resistive Feedback (R1, R2)      |<-------| Current Sense  |<------| Power Pass BJT  |  |
  |               +----------------------------------+        | & Limit (Qlim, |       | (Q_pass)        |  |
  |                                                           |  R_sc)         |       +-----------------+  |
  |                                                           +----------------+                            |
  +---------------------------------------------------------------------------------------------------------+
```

---

## 2. Stage-by-Stage Transistor Analysis & Symbolic Derivations

### 2.1 Voltage Reference Generator ($R_{\text{bias}}, D_Z$)
The reference generator establishes the stable DC baseline $V_{\text{ref}}$ against which the feedback voltage is compared.
- **Quiescent Zener Current ($I_Z$):**
  $$I_Z = \frac{V_{\text{RAW}} - V_Z}{R_{\text{bias}}}$$
- **Dynamic Line Regulation:**
  With Zener incremental dynamic resistance $r_z = \left.\frac{dV_Z}{dI_Z}\right|_{I_Z}$:
  $$\frac{\Delta V_{\text{ref}}}{\Delta V_{\text{RAW}}} = \frac{r_z}{R_{\text{bias}} + r_z} \approx \frac{r_z}{R_{\text{bias}}} \ll 1$$
- **Temperature Coefficient (TC):**
  Zener breakdown below $\approx 5.1\,\text{V}$ operates predominantly on quantum mechanical tunneling ($\text{TC} < 0$), whereas above $\approx 5.6\,\text{V}$ avalanche multiplication dominates ($\text{TC} > 0$). A $5.1\text{--}5.6\,\text{V}$ Zener exhibits near-zero temperature drift ($\text{TC} \approx 0$).

---

### 2.2 Differential Input Stage & Active Current Mirror ($Q_1 \to Q_4, I_{\text{tail}}$)

```
                       V_RAW (Y=9.0)
                        |         |
                     [Q3.E]     [Q4.E]
                       |           |
                  +--[Q3.B]--*---[Q4.B]
                  |    |     |     |
                  +--[Q3.C]  |   [Q4.C] ----> Output Node (N2)
                       |     |     |
                       *-----+     |
                       |           |
                     [Q1.C]      [Q2.C]
                       |           |
     V_ref ------> [Q1.B]        [Q2.B] <---- V_FB
                       |           |
                     [Q1.E]      [Q2.E]
                        \         /
                         *---*---* (TAIL)
                             |
                           [I_tail]
                             |
                            GND (Y=0.0)
```

1. **Emitter Bias Allocation:**
   The tail current source $I_{\text{tail}}$ splits equally under balanced differential conditions:
   $$I_{C1} = I_{C2} = \frac{I_{\text{tail}}}{2}$$
2. **Small-Signal Transconductance ($g_{m1,2}$):**
   $$g_{m1} = g_{m2} = \frac{I_{C}}{V_T} = \frac{I_{\text{tail}}}{2 V_T}$$
   where $V_T = \frac{k_B T}{q} \approx 25.86\,\text{mV}$ at room temperature.
3. **Active Current Mirror Action ($Q_3, Q_4$):**
   $Q_3$ is diode-connected ($V_{CB3} = 0$). Current changes in $Q_1$ modulate $V_{BE3}$, mirroring an identical current change into the collector of $Q_4$:
   $$\Delta i_{C4} \approx \Delta i_{C3} = -\Delta i_{C1}$$
   At output node $N_2$, the net small-signal current delivered to the subsequent stage is:
   $$i_{out,diff} = \Delta i_{C4} - \Delta i_{C2} = -\Delta i_{C1} - \Delta i_{C2} = 2 g_{m1} \cdot \frac{v_d}{2} = g_{m1} (v_{\text{ref}} - v_{\text{FB}})$$
   The active load doubles the transconductance compared to a single-ended passive resistive load.
4. **Differential Stage Output Impedance ($r_{out1}$):**
   $$r_{out1} = r_{o2} \parallel r_{o4} = \left( \frac{V_{A,NPN}}{I_{C2}} \right) \parallel \left( \frac{V_{A,PNP}}{I_{C4}} \right)$$
   where $V_A$ is the Early voltage. Open-loop voltage gain of the first stage:
   $$A_{v1} = \frac{v_{N2}}{v_{\text{ref}} - v_{\text{FB}}} = g_{m1} (r_{o2} \parallel r_{o4})$$

---

### 2.3 Voltage Amplification Stage (VAS) & Miller Compensation ($Q_5, C_c, R_5$)
The VAS is the core high-gain amplifier of the system.
- **Transconductance of $Q_5$ with Emitter Degeneration $R_5$:**
  $$G_{m5} = \frac{g_{m5}}{1 + g_{m5} R_5} \approx \frac{1}{R_5} \quad (\text{for } g_{m5} R_5 \gg 1)$$
  Emitter degeneration linearizes the VAS, elevates its input impedance, and stabilizes quiescent current against thermal drift.
- **Total VAS Voltage Gain ($A_{VAS}$):**
  $$A_{VAS} = -G_{m5} \cdot r_{out,VAS}$$
  where $r_{out,VAS} = r_{o5} (1 + g_{m5} R_5) \parallel R_4$.
- **Miller Compensation Dynamics ($C_c$):**
  The capacitor $C_c$ connected between collector and base of $Q_5$ experiences the Miller effect:
  $$C_{M} = C_c (1 + |A_{VAS}|)$$
  This establishes the **dominant pole** $p_1$ of the overall regulator loop, rolling off loop gain at $-20\,\text{dB/decade}$:
  $$f_{p1} \approx \frac{1}{2\pi \cdot r_{out1} \cdot C_c |A_{VAS}|}$$
- **Slew Rate ($SR$):**
  Under large-signal transients (e.g. step load release), $I_{\text{tail}}$ charges/discharges $C_c$, setting the hard physical slew-rate ceiling:
  $$SR = \left.\frac{dV_{\text{out}}}{dt}\right|_{\max} = \frac{I_{\text{tail}}}{C_c}$$

---

### 2.4 Class AB Push-Pull Driver Stage ($Q_6, Q_7, D_5, D_6, R_{e1}, R_{e2}$)
To prevent the high-impedance VAS colector from being loaded down by the varying base current of power transistor $Q_{\text{pass}}$, a complementary push-pull emitter follower isolates the stages:
1. **Bias Voltage Spread:**
   Two series diodes $D_5, D_6$ maintain a constant voltage between the bases of $Q_6$ (NPN) and $Q_7$ (PNP):
   $$\Delta V_{bias} = V_{F,D5} + V_{F,D6} \approx 2 V_{BE} \approx 1.3\text{--}1.4\,\text{V}$$
2. **Crossover Distortion Elimination:**
   This bias keeps both driver transistors slightly conducting under quiescent conditions:
   $$I_{Q,driver} \approx \frac{\Delta V_{bias} - (V_{BE6} + V_{EB7})}{R_{e1} + R_{e2}}$$
3. **Current Sinking & Sourcing:**
   - **Sourcing:** $Q_6$ pulls node $\text{DRV}$ up toward $V_{\text{RAW}}$, supplying base current to $Q_{\text{pass}}$ during high load demand.
   - **Sinking:** $Q_7$ pulls node $\text{DRV}$ down toward ground, rapidly sweeping stored minority carriers out of $Q_{\text{pass}}$ base during sudden load cutoff.

---

### 2.5 Series Pass Power Transistor ($Q_{\text{pass}}$) & Dropout Voltage
The pass transistor $Q_{\text{pass}}$ acts as a variable series resistor controlled by its base current:
$$I_L \approx I_E = (\beta_{pass} + 1) I_B \approx \beta_{pass} I_B$$
- **Minimum Dropout Voltage ($V_{DO}$):**
  $$V_{DO} = V_{\text{RAW},\min} - V_{\text{OUT}} = V_{CE,sat(pass)} + I_L R_{sc}$$
  Typically $1.5\text{--}2.5\,\text{V}$ for standard NPN Darlington or high-current BJTs.
- **Power Dissipation ($P_{D,pass}$):**
  $$P_{D,pass} = (V_{\text{RAW}} - V_{\text{OUT}} - I_L R_{sc}) I_L \approx (V_{\text{RAW}} - V_{\text{OUT}}) I_L$$
  This power must be continuously dissipated via a heatsink with thermal resistance:
  $$\theta_{JA} \le \frac{T_{J,\max} - T_{A,\max}}{P_{D,pass}}$$

---

### 2.6 Overcurrent Sense & Active Limiter ($R_{sc}, Q_{\text{limit}}$)
Short-circuit protection is achieved by monitoring the voltage drop across series resistor $R_{sc}$:
$$V_{BE(Qlim)} = I_L \cdot R_{sc}$$
- **Threshold Condition:**
  When $I_L \cdot R_{sc} \ge V_{BE,on} \approx 0.65\,\text{V}$, transistor $Q_{\text{limit}}$ enters the forward-active region.
- **Negative Feedback Shunt Action:**
  The collector of $Q_{\text{limit}}$ is tied directly to the base of $Q_{\text{pass}}$ (node $\text{DRV}$). As $Q_{\text{limit}}$ turns on, it shunts drive current away from the pass transistor into the output rail:
  $$I_{\max} = \frac{V_{BE(Qlim)}}{R_{sc}}$$
  This clamps maximum load current to $I_{\max}$ regardless of load impedance, preventing thermal destruction of $Q_{\text{pass}}$.

---

### 2.7 Closed-Loop Feedback Network ($R_1, R_2$)
The output voltage is sampled via a precision resistive divider:
$$\beta = \frac{V_{\text{FB}}}{V_{\text{OUT}}} = \frac{R_2}{R_1 + R_2}$$
In steady-state closed-loop equilibrium, the differential error amplifier forces $V_{\text{FB}} \to V_{\text{ref}}$:
$$V_{\text{OUT}} = V_{\text{ref}} \left( 1 + \frac{R_1}{R_2} \right)$$

---

## 3. Small-Signal Loop Dynamics, Poles & Stability Criteria

```
               a(s) : Forward Amplifier Gain
  V_ref (+) +   +------------------------------+       V_OUT
  --------->(X)-->| Differential -> VAS -> Drivers|----+----->
             -  |   |  -> Pass Transistor          |    |
             ^  +------------------------------+    |
             |                                      |
             |        +-------------------+         |
             +--------| Feedback Factor   |<--------+
                V_FB  | beta = R2/(R1+R2) |
                      +-------------------+
```

### 3.1 Loop Gain & System Poles
The closed-loop transfer function is:
$$A_{CL}(s) = \frac{V_{\text{OUT}}(s)}{V_{\text{ref}}(s)} = \frac{a(s)}{1 + T(s)} = \frac{a(s)}{1 + a(s)\beta}$$
where the open-loop transmission is $T(s) = a(s)\beta$.

The loop exhibits three major physical poles and one stabilizing zero:
1. **Dominant Miller Pole ($p_1$):**
   $$p_1 \approx -\frac{1}{R_{out1} \cdot C_c |A_{VAS}|} \quad (\approx 10\,\text{Hz} \to 1\,\text{kHz})$$
2. **Output Filter Pole ($p_2$):**
   Formed by the total output capacitance and effective load resistance:
   $$p_2 \approx -\frac{1}{(R_L \parallel r_{out,pass}) \cdot C_{\text{out}}} \quad (\approx 10\,\text{kHz} \to 100\,\text{kHz})$$
3. **High-Frequency Parasitic Pole ($p_3$):**
   Associated with the transition frequency $f_T$ and input capacitance of $Q_{\text{pass}}$:
   $$p_3 \approx -2\pi f_T \quad (> 10\,\text{MHz})$$
4. **ESR Zero of Output Capacitor ($z_{ESR}$):**
   $$z_{ESR} = -\frac{1}{R_{ESR} \cdot C_{\text{out}}}$$

### 3.2 Stability Criteria (Phase Margin & Gain Margin)
At the unity loop-gain crossover frequency $f_c$ where $|T(j 2\pi f_c)| = 1$ ($0\,\text{dB}$):
- **Phase Margin ($\Phi_M$):**
  $$\Phi_M = 180^\circ + \arg T(j 2\pi f_c) \ge 45^\circ \quad (\text{Target: } 60^\circ)$$
- **Gain Margin ($G_M$):**
  $$G_M = -20 \log_{10} |T(j 2\pi f_{\pi})| \ge 10\,\text{dB}$$
  where $\arg T(j 2\pi f_{\pi}) = -180^\circ$.

> [!CAUTION]
> If an ultra-low ESR ceramic capacitor is used for $C_{\text{out}}$ without series resistance, the ESR zero moves to ultra-high frequencies ($>10\,\text{MHz}$), removing its phase boost. At the crossover frequency, both $p_1$ and $p_2$ contribute $-180^\circ$ phase lag, degrading $\Phi_M$ to $<10^\circ$ and causing sustained high-frequency oscillations. A controlled ESR capacitor or damping resistor is mandatory.

---

## 4. Symbolic Component Sizing Formulae

| Component | Symbolic Function | Analytical Formula |
| :--- | :--- | :--- |
| **$R_{\text{bias}}$** | Zener Bias Resistor | $\displaystyle R_{\text{bias}} = \frac{V_{\text{RAW},\min} - V_Z}{I_Z}$ |
| **$R_1$** | Feedback Upper Resistor | $\displaystyle R_1 = R_2 \left( \frac{V_{\text{OUT}}}{V_{\text{ref}}} - 1 \right)$ |
| **$R_2$** | Feedback Lower Resistor | Chosen to ensure divider current $\gg I_{B2}$: $\displaystyle R_2 \le \frac{V_{\text{ref}}}{50 \cdot I_{B2}}$ |
| **$R_{sc}$** | Short-Circuit Current Limit | $\displaystyle R_{sc} = \frac{V_{BE(Qlim)}}{I_{\max}} \approx \frac{0.65\,\text{V}}{I_{\max}}$ |
| **$R_4$** | VAS Pull-up Load Resistor | $\displaystyle R_4 \approx \frac{V_{\text{RAW},\min} - (V_{\text{OUT}} + V_{BE6} + V_{BE,pass})}{I_{C5,quiescent}}$ |
| **$R_5$** | VAS Emitter Degeneration | $\displaystyle R_5 \approx \frac{0.1 \cdot V_{\text{RAW}}}{I_{C5}}$ |
| **$C_c$** | Miller Dominant Pole Cap | $\displaystyle C_c \ge \frac{I_{\text{tail}}}{2\pi \cdot f_c \cdot (V_T / I_{C1}) \cdot \beta}$ |
| **$C_{\text{out}}$** | Output Transient Decoupling| $\displaystyle C_{\text{out}} \ge \frac{\Delta I_L \cdot \Delta t_{trans}}{\Delta V_{\text{OUT},allowed}}$ |
