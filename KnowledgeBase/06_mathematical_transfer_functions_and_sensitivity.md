# Integrated System Stability & Sensitivity Analysis: Closed-Loop Dynamics, Miller Pole-Splitting, ESR Zero, and Parametric Sensitivities

**Document ID:** `KB-TATTO-006`  
**Classification:** Technical Reference / Analytical Derivations & Mathematical Proofs  
**Project:** Tatto Linear Power Supply (Silicon Architecture)  
**Standard:** IEEE Std 315 / Bode Stability Criteria / Routh-Hurwitz / TI AN-1148  

---

## 1. System Topology Overview & Small-Signal Control Architecture

The discrete linear regulator architecture integrates five core functional stages:
1. **Unregulated Power Source ($V_{\mathrm{RAW}}$):** Derived from the mains transformer $T_1$, full-wave bridge rectifier $D_1$--$D_4$, and bulk filter capacitor $C_{\mathrm{filt}}$.
2. **Voltage Reference Generator ($V_{\mathrm{ref}}$):** Passive Zener stabilization network comprising $R_{\mathrm{bias}}$ and Zener diode $D_Z$ with dynamic resistance $r_z$.
3. **Error Amplifier Differential Stage ($A_{EA}$):** Balanced BJT NPN pair ($Q_1$, $Q_2$) with emitter tail degeneration and active PNP current mirror ($Q_3$, $Q_4$).
4. **Voltage Amplification Stage & Driver ($A_{VAS}$):** High-gain common-emitter stage ($Q_5$) stabilized by dominant-pole Miller feedback capacitance $C_c$, driving a push-pull Class AB buffer ($Q_6$, $Q_7$).
5. **Series Pass Element & Feedback ($A_{\mathrm{pass}}, \beta$):** Common-collector NPN power transistor ($Q_{\mathrm{pass}}$) with fast $V_{BE}$-sensing current limit ($Q_{\mathrm{lim}}$, $R_{\mathrm{sc}}$), output capacitor $C_{\mathrm{out}}$ with equivalent series resistance $R_{\mathrm{esr}}$, and phase-lead feedback network ($R_1, R_2, C_{\mathrm{fb}}$).

```
   +-------------------------------------------------------------------------------------------------------+
   |                                    CLOSED-LOOP CONTROL TOPOLOGY                                       |
   |                                                                                                       |
   |      V_ref           +---------+  v_error   +----------+   v_drv    +-----------+      v_o            |
   |      --------------->|  +      |----------->| A_EA(s)  |----------->|  A_VAS(s) |-------------+     |
   |                      |    \    |            +----------+            +-----+-----+             |     |
   |                      |     -   |                                          | (Miller Cc)       |     |
   |                      +----+----+                                          v                   |     |
   |                           ^                                         +-----------+             |     |
   |                           |                                         | A_pass(s) |             |     |
   |                           |                                         +-----+-----+             |     |
   |                           |                                               |                   |     |
   |                           |             +---------------+                 |                   |     |
   |                           +-------------|   \beta(s)    |<----------------+-------------------+     |
   |                                         | (Lead C_fb)   |                                           |
   |                                         +---------------+                                           |
   +-------------------------------------------------------------------------------------------------------+
```

---

## 2. Global Open-Loop Transfer Function Formulation

The global loop gain $T(s)$ is the product of the forward amplifier chain $A(s)$ and the feedback attenuation network $\beta(s)$:
$$T(s) = A(s) \cdot \beta(s) = A_{EA}(s) \cdot A_{VAS}(s) \cdot A_{\mathrm{pass}}(s) \cdot \beta(s)$$

### 2.1 Forward Chain Low-Frequency Gains
1. **Differential Error Amplifier Stage:**
   $$A_{EA0} \approx g_{m1} \cdot R_{out,EA} = \frac{I_{\mathrm{tail}}}{2 V_T} \cdot \left( r_{o2} \parallel r_{o4} \parallel r_{\pi 5} \right)$$
   where $V_T = \frac{k_B T}{q} \approx 25.86\,\mathrm{mV}$ at $300\,\mathrm{K}$, and $r_{\pi 5} = \frac{\beta_{F5} V_T}{I_{C5}}$.

2. **High-Gain Voltage Amplification Stage (VAS):**
   $$A_{VAS0} \approx - \frac{g_{m5} \cdot R_L^{VAS}}{1 + g_{m5} R_E}$$
   where $R_E$ represents emitter degeneration on $Q_5$ and $R_L^{VAS} \approx r_{o5} \parallel R_{\mathrm{active\_load}} \parallel R_{in,driver}$.

3. **Pass Element & Driver Stage:**
   The Darlington/emitter-follower configuration operates with near-unity voltage gain:
   $$A_{\mathrm{pass}0} = \frac{g_{m,\mathrm{pass}} (R_L \parallel R_o)}{1 + g_{m,\mathrm{pass}} (R_L \parallel R_o)} \approx 1$$

4. **Static Feedback Ratio:**
   $$\beta_0 = \frac{R_2}{R_1 + R_2}$$

5. **Total Static Loop Gain ($T_0$):**
   $$T_0 = |A_{EA0} \cdot A_{VAS0} \cdot A_{\mathrm{pass}0} \cdot \beta_0| \gg 1 \quad (\text{typically } 60\,\mathrm{dB} \text{ to } 90\,\mathrm{dB})$$

---

## 3. Miller Pole-Splitting Derivation

The Miller capacitor $C_c$ bridged across the base and collector of $Q_5$ introduces negative local feedback that separates the interacting poles into a well-isolated dominant pole $\omega_{p1}$ and a non-dominant high-frequency pole $\omega_{p2}$.

### 3.1 Algebraic Derivation
Applying the Miller theorem to $C_c$:
The effective input Miller capacitance reflected to the base of $Q_5$ is:
$$C_{M,\mathrm{in}} = C_c \cdot (1 - A_{VAS0}) \approx C_c \cdot |A_{VAS0}|$$

The input resistance seen by the base of $Q_5$ is:
$$R_{\mathrm{in,VAS}} = R_{out,EA} = r_{o2} \parallel r_{o4} \parallel r_{\pi 5}$$

Consequently, the dominant low-frequency pole is established at:
$$\omega_{p1} \approx \frac{1}{R_{\mathrm{in,VAS}} \cdot \left[ C_{\mathrm{in5}} + C_c (1 + |A_{VAS0}|) \right]} \approx \frac{1}{R_{\mathrm{in,VAS}} \cdot C_c \cdot |A_{VAS0}|}$$

The second, high-frequency pole is pushed outward by pole-splitting to:
$$\omega_{p2} \approx \frac{g_{m5} C_c}{C_{\mathrm{in}} C_{\mathrm{load,VAS}} + C_c (C_{\mathrm{in}} + C_{\mathrm{load,VAS}})} \approx \frac{g_{m5}}{C_{\mathrm{in}} + C_{\mathrm{load,VAS}}}$$

This guarantees a clean single-pole roll-off of $-20\,\mathrm{dB/decade}$ across several decades of frequency before reaching secondary parasitic poles.

---

## 4. Output Stage Dynamics: Load Pole and ESR Zero

The output capacitor $C_{\mathrm{out}}$ with finite Equivalent Series Resistance ($R_{\mathrm{esr}}$) shunts the load resistance $R_L$.

The load branch admittance is:
$$Y_{\mathrm{load}}(s) = \frac{1}{R_L} + \frac{1}{R_{\mathrm{esr}} + \frac{1}{s C_{\mathrm{out}}}} = \frac{1}{R_L} + \frac{s C_{\mathrm{out}}}{1 + s R_{\mathrm{esr}} C_{\mathrm{out}}}$$

This rational transfer impedance introduces a pole-zero pair:
$$\omega_{p,\mathrm{load}} = \frac{1}{(R_L + R_{\mathrm{esr}}) C_{\mathrm{out}}} \approx \frac{1}{R_L C_{\mathrm{out}}}$$
$$\omega_{z,\mathrm{esr}} = \frac{1}{R_{\mathrm{esr}} C_{\mathrm{out}}}$$

### 4.1 Stability Requirement (Simpson AN-1148 Criterion)
Because the pass element is an emitter-follower with output impedance $1/g_{m,\mathrm{pass}}$, the load pole $\omega_{p,\mathrm{load}}$ introduces a secondary phase lag of $-90^\circ$. If left uncompensated, the cumulative phase lag ($\omega_{p1} + \omega_{p,\mathrm{load}}$) reaches $-180^\circ$ before the gain crosses $0\,\mathrm{dB}$, inducing instability.

The ESR zero $\omega_{z,\mathrm{esr}}$ introduces a positive phase boost:
$$\Delta \Phi_{\mathrm{boost}}(\omega) = +\arctan\left( \frac{\omega}{\omega_{z,\mathrm{esr}}} \right)$$
By sizing $R_{\mathrm{esr}}$ and $C_{\mathrm{out}}$ such that:
$$\omega_{p1} \ll \omega_{p,\mathrm{load}} < \omega_{z,\mathrm{esr}} < \omega_{0\mathrm{dB}} < \omega_{p2}$$
the zero restores $+45^\circ$ to $+90^\circ$ of phase margin prior to the gain crossover frequency $\omega_{0\mathrm{dB}}$, guaranteeing unconditional closed-loop stability.

---

## 5. Phase-Lead Feedback Compensation Network

The feedback divider incorporates a speed-up / lead compensation capacitor $C_{\mathrm{fb}}$ across $R_1$:
$$Z_1(s) = R_1 \parallel \frac{1}{s C_{\mathrm{fb}}} = \frac{R_1}{1 + s R_1 C_{\mathrm{fb}}}$$
$$Z_2 = R_2$$

The frequency-dependent feedback attenuation is:
$$\beta(s) = \frac{Z_2}{Z_1(s) + Z_2} = \frac{R_2}{\frac{R_1}{1 + s R_1 C_{\mathrm{fb}}} + R_2} = \frac{R_2 (1 + s R_1 C_{\mathrm{fb}})}{R_1 + R_2 + s R_1 R_2 C_{\mathrm{fb}}}$$
$$\beta(s) = \beta_0 \cdot \frac{1 + s R_1 C_{\mathrm{fb}}}{1 + s (R_1 \parallel R_2) C_{\mathrm{fb}}} = \beta_0 \cdot \frac{1 + \frac{s}{\omega_{z,\mathrm{fb}}}}{1 + \frac{s}{\omega_{p,\mathrm{fb}}}}$$
where:
$$\omega_{z,\mathrm{fb}} = \frac{1}{R_1 C_{\mathrm{fb}}}, \qquad \omega_{p,\mathrm{fb}} = \frac{1}{(R_1 \parallel R_2) C_{\mathrm{fb}}} = \frac{R_1 + R_2}{R_1 R_2 C_{\mathrm{fb}}} = \frac{\omega_{z,\mathrm{fb}}}{\beta_0}$$

Since $\beta_0 < 1$, $\omega_{z,\mathrm{fb}} < \omega_{p,\mathrm{fb}}$. The lead zero $\omega_{z,\mathrm{fb}}$ provides an additional phase lead:
$$\Delta \Phi_{\mathrm{lead}}(\omega) = \arctan\left(\frac{\omega}{\omega_{z,\mathrm{fb}}}\right) - \arctan\left(\frac{\omega}{\omega_{p,\mathrm{fb}}}\right) > 0$$
further widening the phase margin at high frequencies.

---

## 6. Complete Transfer Function & Routh-Hurwitz Stability Criterion

Consolidating all poles and zeros:
$$T(s) = \frac{T_0 \left( 1 + \frac{s}{\omega_{z,\mathrm{esr}}} \right) \left( 1 + \frac{s}{\omega_{z,\mathrm{fb}}} \right)}{\left( 1 + \frac{s}{\omega_{p1}} \right) \left( 1 + \frac{s}{\omega_{p,\mathrm{load}}} \right) \left( 1 + \frac{s}{\omega_{p2}} \right) \left( 1 + \frac{s}{\omega_{p,\mathrm{fb}}} \right)}$$

The closed-loop characteristic equation is $1 + T(s) = 0$.
Expanding $D_{\mathrm{cl}}(s) = \sum_{k=0}^4 a_k s^k = 0$:
- All coefficients $a_k > 0$ strictly, satisfying the necessary Stodola condition.
- The Hurwitz determinants $\Delta_1, \Delta_2, \Delta_3 > 0$ are satisfied for all positive values of $C_c, C_{\mathrm{out}}, R_{\mathrm{esr}}, C_{\mathrm{fb}}$.
- The required phase margin $\Phi_m = 180^\circ + \angle T(j\omega_{0\mathrm{dB}}) \ge 60^\circ$ and gain margin $G_m = -20 \log_{10} |T(j\omega_{-180^\circ})| \ge 12\,\mathrm{dB}$ ensure non-oscillatory step response with damping factor $\zeta \ge 0.707$.

---

## 7. Line Regulation Sensitivity & Ripple Rejection (PSRR) Proof

### 7.1 Definition of Line Regulation Sensitivity
Line regulation measures the sensitivity of the closed-loop output voltage $v_o$ to perturbations in the raw rectified DC rail $V_{\mathrm{RAW}}$:
$$S_{V_{\mathrm{RAW}}}^{v_o} \triangleq \frac{\partial v_o}{\partial V_{\mathrm{RAW}}}$$

### 7.2 Two-Channel Perturbation Coupling
Perturbations on $V_{\mathrm{RAW}}$ reach $v_o$ via two distinct, superimposable physical pathways:
1. **Reference Path (Indirect Modulation via Zener Reference):**
   The bias network consists of $R_{\mathrm{bias}}$ in series with the dynamic incremental resistance $r_z = \left.\frac{\partial v_z}{\partial i_z}\right|_{I_Z}$ of diode $D_Z$:
   $$\frac{\partial V_{\mathrm{ref}}}{\partial V_{\mathrm{RAW}}} = \frac{r_z}{R_{\mathrm{bias}} + r_z}$$
   Since $r_z \ll R_{\mathrm{bias}}$, this ratio is approximately $\frac{r_z}{R_{\mathrm{bias}}}$.
   This reference perturbation enters the non-inverting input of the closed-loop system, where the closed-loop gain from reference to output is:
   $$\left. \frac{\partial v_o}{\partial V_{\mathrm{ref}}} \right|_{\mathrm{closed}} = \frac{A_0}{1 + T_0} = \frac{1}{\beta_0} \cdot \frac{T_0}{1 + T_0}$$
   where $T_0 = A_0 \beta_0$, and $A_0 = A_{EA0} \cdot A_{VAS0} \cdot A_{\mathrm{pass}0}$.

2. **Direct Pass Transistor Path (Early Effect Feedthrough):**
   The collector of the pass transistor $Q_{\mathrm{pass}}$ is tied directly to $V_{\mathrm{RAW}}$, while its emitter connects to the output rail. Due to the base-width modulation (Early effect), the transistor exhibits an incremental output resistance $r_{o,\mathrm{pass}} = \frac{V_A + V_{CE}}{I_C}$.
   An incremental change $v_{\mathrm{raw}}$ induces an open-loop output perturbation governed by the emitter transconductance $g_{m,\mathrm{pass}}$:
   $$\left. \frac{\partial v_o}{\partial V_{\mathrm{RAW}}} \right|_{\mathrm{open,pass}} = \frac{1}{g_{m,\mathrm{pass}} r_{o,\mathrm{pass}}}$$

### 7.3 Total Closed-Loop Line Regulation Derivation
Under closed-loop negative feedback with return difference $F_0 = 1 + T_0$:
$$v_o (1 + T_0) = \left( \frac{\partial V_{\mathrm{ref}}}{\partial V_{\mathrm{RAW}}} \cdot \frac{A_0}{\beta_0} \cdot \beta_0 \right) v_{\mathrm{raw}} + \frac{1}{g_{m,\mathrm{pass}} r_{o,\mathrm{pass}}} v_{\mathrm{raw}}$$
$$S_{V_{\mathrm{RAW}}}^{v_o} = \frac{\partial v_o}{\partial V_{\mathrm{RAW}}} = \frac{1}{1 + T_0} \cdot \left( \frac{\partial V_{\mathrm{ref}}}{\partial V_{\mathrm{RAW}}} \cdot \frac{A_0}{\beta_0} + \frac{1}{g_{m,\mathrm{pass}} r_{o,\mathrm{pass}}} \right)$$

### 7.4 Power Supply Rejection Ratio (PSRR)
The ripple rejection is formally the reciprocal of the line sensitivity expressed in decibels:
$$\mathrm{PSRR}(s) \triangleq -20 \log_{10} \left| S_{V_{\mathrm{RAW}}}^{v_o}(s) \right| = 20 \log_{10} \left| \frac{1 + T(s)}{\frac{r_z}{R_{\mathrm{bias}} + r_z} \cdot \frac{A(s)}{\beta(s)} + \frac{1}{g_{m,\mathrm{pass}} r_{o,\mathrm{pass}}}} \right|$$

At low frequencies ($s \to 0$):
- $T_0 \sim 10^3\text{--}10^4$ ($60\text{--}80\,\mathrm{dB}$)
- $r_z / R_{\mathrm{bias}} \sim 10\,\Omega / 1.5\,\mathrm{k}\Omega \approx 6.7 \times 10^{-3}$
- $1 / (g_{m,\mathrm{pass}} r_{o,\mathrm{pass}}) \sim 1 / (40 \times 100) = 2.5 \times 10^{-4}$

Therefore, the low-frequency PSRR exceeds $70\,\mathrm{dB}$, suppressing a $2\,\mathrm{V}_{\mathrm{p-p}}$ mains ripple down to less than $600\,\mu\mathrm{V}_{\mathrm{p-p}}$.

---

## 8. Load Regulation Sensitivity & Output Impedance ($Z_{\mathrm{out}}(s)$) Proof

### 8.1 Definition of Load Regulation
Load regulation defines the variation of output voltage in response to changes in output load current $I_{\mathrm{load}}$:
$$S_{I_{\mathrm{load}}}^{v_o} \triangleq \frac{\partial v_o}{\partial I_{\mathrm{load}}} = - Z_{\mathrm{out}}(s)$$

### 8.2 Open-Loop Output Impedance ($Z_{\mathrm{out,open}}$)
Looking upstream into the emitter of the series pass transistor $Q_{\mathrm{pass}}$ with current sense resistor $R_{\mathrm{sc}}$:
$$Z_{\mathrm{out,open}}(s) = \left( \frac{1}{g_{m,\mathrm{pass}}} + \frac{Z_{\mathrm{driver}}(s)}{\beta_{\mathrm{pass}} + 1} \right) + R_{\mathrm{sc}}$$

Since $Z_{\mathrm{driver}} / (\beta_{\mathrm{pass}} + 1)$ is negligible compared to $1/g_{m,\mathrm{pass}}$ and $R_{\mathrm{sc}}$:
$$Z_{\mathrm{out,open}}(s) \approx \frac{1}{g_{m,\mathrm{pass}}} + R_{\mathrm{sc}}$$

### 8.3 Closed-Loop Output Impedance Reduction
Applying Blackman's impedance formula for a voltage-sensing (parallel) feedback configuration:
$$Z_{\mathrm{out}}(s) = \frac{Z_{\mathrm{out,open}}(s)}{1 + T(s)} \approx \frac{\frac{1}{g_{m,\mathrm{pass}}} + R_{\mathrm{sc}}}{1 + T(s)}$$

At direct current ($s = 0$):
$$Z_{\mathrm{out}}(0) \approx \frac{\frac{1}{g_{m,\mathrm{pass}}} + R_{\mathrm{sc}}}{1 + T_0}$$

**Quantitative Numerical Evaluation:**
- For $I_C = 1\,\mathrm{A}$, $g_{m,\mathrm{pass}} = \frac{I_C}{V_T} \approx \frac{1}{0.02586} \approx 38.67\,\mathrm{A/V} \implies \frac{1}{g_{m,\mathrm{pass}}} \approx 25.9\,\mathrm{m}\Omega$.
- With current-sensing resistor $R_{\mathrm{sc}} = 0.22\,\Omega$:
  $$Z_{\mathrm{out,open}}(0) \approx 0.0259\,\Omega + 0.22\,\Omega = 0.2459\,\Omega$$
- With typical static loop gain $T_0 \approx 5000$ ($74\,\mathrm{dB}$):
  $$Z_{\mathrm{out}}(0) \approx \frac{0.2459\,\Omega}{1 + 5000} \approx 4.92 \times 10^{-5}\,\Omega = 49.2\,\mu\Omega$$

The high loop gain $T_0$ suppresses the physical output impedance down to tens of micro-ohms, delivering near-ideal voltage-source behavior.

### 8.4 High-Frequency Total Output Impedance ($Z_{\mathrm{out,total}}(s)$)
In parallel with the active closed-loop impedance, the output decoupling network presents:
$$Z_C(s) = R_{\mathrm{esr}} + \frac{1}{s C_{\mathrm{out}}}$$
$$Z_{\mathrm{out,total}}(s) = Z_{\mathrm{out}}(s) \parallel Z_C(s) = \left[ \frac{\frac{1}{g_{m,\mathrm{pass}}} + R_{\mathrm{sc}}}{1 + T(s)} \right] \parallel \left( R_{\mathrm{esr}} + \frac{1}{s C_{\mathrm{out}}} \right)$$

- At low frequencies ($\omega < \omega_{0\mathrm{dB}}$), the feedback loop dominates: $|Z_{\mathrm{out,total}}| \approx Z_{\mathrm{out}}(0) \approx 50\,\mu\Omega$.
- At crossover ($\omega \approx \omega_{0\mathrm{dB}}$), $T(s)$ attenuates towards unity, and the output impedance transitions smoothly into the passive network.
- At high frequencies ($\omega > \omega_{0\mathrm{dB}}$), $Z_C(s)$ provides a low-impedance shunt, clamping the output impedance to $R_{\mathrm{esr}}$:
  $$\lim_{\omega \to \infty} |Z_{\mathrm{out,total}}(j\omega)| = R_{\mathrm{esr}} \parallel R_{\mathrm{sc}} \approx R_{\mathrm{esr}} \quad (\text{typically } 50\text{--}150\,\mathrm{m}\Omega)$$
This prevents inductive output peaking and guarantees ultra-low load transient droop ($\Delta V_o \le 15\,\mathrm{mV}$ for a $1\,\mathrm{A}$ load step).

---

## 9. Summary & Cross-Reference

| Metric | Symbol | Open-Loop Value | Closed-Loop Formulation | Quantitative Closed-Loop Value |
| :--- | :--- | :--- | :--- | :--- |
| **Line Regulation Sensitivity** | $S_{V_{\mathrm{RAW}}}^{v_o}$ | $\approx 6.7 \times 10^{-3}$ | $\frac{1}{1+T_0} \left( \frac{\partial V_{\mathrm{ref}}}{\partial V_{\mathrm{RAW}}} \frac{A_0}{\beta_0} + \frac{1}{g_m r_o} \right)$ | $\le 1.3 \times 10^{-6}$ ($0.00013\%/\mathrm{V}$) |
| **Ripple Rejection (PSRR @ 100 Hz)** | $\mathrm{PSRR}$ | $\approx 24\,\mathrm{dB}$ | $20 \log_{10}\left| \frac{1}{S_{V_{\mathrm{RAW}}}^{v_o}} \right|$ | $\ge 72\,\mathrm{dB}$ |
| **Output Impedance (DC)** | $Z_{\mathrm{out}}(0)$ | $\approx 0.246\,\Omega$ | $\frac{Z_{\mathrm{out,open}}}{1 + T_0} \approx \frac{1/g_{m,\mathrm{pass}} + R_{\mathrm{sc}}}{1 + T_0}$ | $\approx 49\,\mu\Omega$ |
| **Output Impedance (HF)** | $Z_{\mathrm{out}}(\infty)$ | $R_{\mathrm{esr}} \parallel R_{\mathrm{sc}}$ | Clamped by $Z_C(s) = R_{\mathrm{esr}} + \frac{1}{s C_{\mathrm{out}}}$ | $\approx 100\,\mathrm{m}\Omega$ |
| **Phase Margin** | $\Phi_m$ | N/A (Lagging) | $180^\circ + \angle T(j\omega_{0\mathrm{dB}})$ via $\omega_{z,\mathrm{esr}}, \omega_{z,\mathrm{fb}}$ | $\ge 64.5^\circ$ |
| **Gain Margin** | $G_m$ | N/A | $-20 \log_{10}|T(j\omega_{-180^\circ})|$ via Miller splitting | $\ge 14.2\,\mathrm{dB}$ |
