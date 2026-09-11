%% =========================================================================
%% TATTO PROJECT — MASTER INTEGRATED SYSTEM: BARE-METAL DISCRETE SILICON
%% File: simscape_integrated_system.m
%% Standard: 2026 Multi-Agent Standard (Parametric Agnosticism & Twin Modeling)
%% Solvers: ode23t (Differential-Algebraic Stiff Solver) & Bode Linearization
%% Biunivocal Fidelity with: figures/tikz/master_integrated_system.tex
%%                        simulations/spice/master_integrated_system.cir
%% =========================================================================

function simscape_integrated_system()
    close all; clc;
    fprintf('==================================================================\n');
    fprintf(' TATTO POWER SUPPLY — DIGITAL TWIN INTEGRATED SYSTEM SIMULATION   \n');
    fprintf(' Stage 1: Power & Bridge | Stage 2: Reference | Stage 3: Diff Pair\n');
    fprintf(' Stage 4: VAS & Miller   | Stage 5: Pass Element & Current Limit  \n');
    fprintf('==================================================================\n\n');

    %% ---------------------------------------------------------------------
    %% 1. SYSTEM PARAMETRIC DEFINITIONS (100% Parameterized Struct Architecture)
    %% ---------------------------------------------------------------------
    p = struct();

    % --- STAGE 1: AC MAINS, TRANSFORMER & FULL-WAVE BRIDGE ---
    p.V_pri_rms    = 120.0;              % Primary AC mains RMS voltage (V)
    p.f_line       = 60.0;               % Mains frequency (Hz)
    p.w_line       = 2 * pi * p.f_line;  % Angular line frequency (rad/s)
    p.k_T          = 0.15;               % Transformer turns ratio Ns / Np
    p.V_pri_pk     = p.V_pri_rms * sqrt(2.0); % Primary peak voltage (V)
    p.V_sec_pk     = p.V_pri_pk * p.k_T; % Secondary peak voltage (V) ~ 25.45 V
    p.R_sec_w      = 0.05;               % Secondary winding resistance (Ohms)
    p.V_D          = 0.75;               % Diode forward voltage drop (V)
    p.r_d          = 0.035;              % Diode dynamic bulk resistance (Ohms)
    p.V_bridge_drop= 2 * p.V_D;          % Bridge total forward drop (V) = 1.5 V
    p.R_bridge_fwd = 2 * p.r_d + p.R_sec_w; % Total conduction loop resistance (Ohms)
    p.C_filt       = 4700e-6;            % Bulk electrolytic filter capacitance (F)
    p.R_filt_esr   = 0.02;               % Bulk capacitor ESR (Ohms)
    p.R_bleed      = 1000.0;             % Bleeder discharge resistor (Ohms)

    % --- STAGE 2: VOLTAGE REFERENCE & BIAS ---
    p.R_bias       = 1500.0;             % Zener bias resistor (Ohms)
    p.V_Z_nom      = 5.1;                % Nominal Zener breakdown voltage (V)
    p.r_z          = 10.0;               % Dynamic Zener impedance (Ohms)

    % --- STAGE 3: ERROR AMPLIFIER (DIFF PAIR & ACTIVE MIRROR) ---
    p.I_tail       = 2.0e-3;             % Tail current sink (A) = 2.0 mA
    p.V_T          = 0.02586;            % Thermal voltage at 300 K (V)
    p.beta_npn     = 200.0;              % NPN current gain (2N3904)
    p.beta_pnp     = 180.0;              % PNP current gain (2N3906)
    p.V_A_pnp      = 100.0;              % PNP Early voltage (V)

    % --- STAGE 4: VOLTAGE AMPLIFIER STAGE (VAS) & COMPENSATION ---
    p.R_E          = 100.0;              % VAS emitter degeneration resistor (Ohms)
    p.R_C          = 2200.0;             % VAS collector pull-up resistor (Ohms)
    p.C_c          = 100e-12;            % Miller compensation capacitance (F) = 100 pF
    p.beta_vas     = 200.0;              % VAS NPN current gain (2N3904)
    p.V_BE_on      = 0.65;               % Small-signal BJT V_BE turn-on voltage (V)

    % --- STAGE 5: SERIES PASS, CURRENT LIMITING & CLOSED FEEDBACK ---
    % Enhanced Darlington Pass Stage (Q_drv 2N3904 + Q_pass TIP31C)
    p.beta_drv     = 200.0;              % Driver BJT current gain (2N3904)
    p.V_BE_drv     = 0.65;               % Driver BJT V_BE drop (V)
    p.beta_pass    = 60.0;               % Power pass NPN current gain (TIP31C)
    p.V_BE_pass    = 0.75;               % Power pass V_BE at nominal load (V)
    p.beta_darlington = p.beta_drv * p.beta_pass; % Combined Darlington current gain = 12,000
    p.V_BE_tot     = p.V_BE_drv + p.V_BE_pass;   % Total Darlington V_BE drop = 1.40 V
    p.R_sc         = 0.33;               % Current limit sense resistor (Ohms)
    p.V_BE_limit   = 0.65;               % Current limiter Q_limit threshold (V)
    p.g_m_lim      = 20.0;               % Limiter diversion transconductance (A/V)
    p.C_out        = 100e-6;             % Output smoothing capacitance (F) = 100 uF
    p.R_out_esr    = 0.05;               % Output capacitor ESR (Ohms)
    p.R1           = 4470.0;             % Upper feedback divider resistor (Ohms) (tuned for 12.0 V)
    p.R2           = 3300.0;             % Lower feedback divider resistor (Ohms)
    p.R_load_nom   = 10.0;               % Nominal load resistance (Ohms) (I_out = 1.20 A)
    p.R_load_step  = 7.0;                % Stepped load resistance (Ohms) (I_out ~ 1.71 A)
    p.t_step       = 0.030;              % Load step transition timestamp (s) = 30 ms

    %% ---------------------------------------------------------------------
    %% 2. THEORETICAL & ANALYTICAL DEDUCTIONS
    %% ---------------------------------------------------------------------
    beta_div       = p.R2 / (p.R1 + p.R2);
    V_out_target   = p.V_Z_nom / beta_div;
    I_out_nom      = V_out_target / p.R_load_nom;
    I_out_limit    = p.V_BE_limit / p.R_sc;
    V_raw_pk       = p.V_sec_pk - p.V_bridge_drop;
    
    % Haris Muneer / Schade Bulk Ripple Estimate
    T_dis          = 1.0 / (2.0 * p.f_line);
    R_raw_eq       = V_raw_pk / (I_out_nom + V_raw_pk / p.R_bleed);
    V_raw_rip_anal = V_raw_pk * (1.0 - exp(-T_dis / (R_raw_eq * p.C_filt)));
    V_raw_avg_anal = V_raw_pk - (V_raw_rip_anal / 2.0);

    fprintf('--- ANALYTICAL PREDICTIONS ---\n');
    fprintf('  Target Regulated Output (V_out):     %7.3f V\n', V_out_target);
    fprintf('  Feedback Factor (beta):               %7.4f\n', beta_div);
    fprintf('  Nominal Load Current (I_out_nom):     %7.3f A\n', I_out_nom);
    fprintf('  Current Limit Threshold (I_limit):    %7.3f A\n', I_out_limit);
    fprintf('  Peak Raw DC Rail (V_raw_pk):          %7.2f V\n', V_raw_pk);
    fprintf('  Analytical Raw DC Ripple (P-P):       %7.3f V\n', V_raw_rip_anal);
    fprintf('  Mean Raw DC Rail (V_raw_avg):         %7.2f V\n\n', V_raw_avg_anal);

    %% ---------------------------------------------------------------------
    %% 3. NUMERICAL INTEGRATION USING ode23t (Stiff Trapezoidal Solver)
    %% ---------------------------------------------------------------------
    % State Vector x = [v_filt; v_VAS; v_Cout]
    % State 1: v_filt  (Bulk Filter Capacitor Voltage, V)
    % State 2: v_VAS   (Voltage at Collector of Q5 / Base of Q_pass, V)
    % State 3: v_Cout  (Voltage across Output Filter Capacitor, V)
    t_span = [0, 0.050];
    x0     = [0.0; 0.0; 0.0]; % Initial Condition: Fully Discharged (UIC)

    options = odeset('RelTol', 1e-4, 'AbsTol', 1e-6, 'MaxStep', 1e-5);
    ode_sys = @(t, x) integrated_dynamics(t, x, p);

    fprintf('Executing ode23t stiff numerical integration [0 to 50 ms]...\n');
    [t_vec, x_vec] = ode23t(ode_sys, t_span, x0, options);
    fprintf('Integration completed successfully (%d time steps evaluated).\n\n', length(t_vec));

    % Reconstruct Algebraic Signals across Simulation Grid
    N_pts    = length(t_vec);
    v_sec    = p.V_sec_pk * sin(p.w_line * t_vec);
    v_raw    = x_vec(:, 1);
    v_VAS    = x_vec(:, 2);
    v_Cout   = x_vec(:, 3);
    
    v_ref    = zeros(N_pts, 1);
    v_out    = zeros(N_pts, 1);
    i_out    = zeros(N_pts, 1);
    v_fb     = zeros(N_pts, 1);

    for k = 1:N_pts
        t_k = t_vec(k);
        x_k = x_vec(k, :)';
        [~, alg_k] = integrated_dynamics(t_k, x_k, p);
        v_ref(k)   = alg_k.v_ref;
        v_out(k)   = alg_k.v_out;
        i_out(k)   = alg_k.i_out;
        v_fb(k)    = alg_k.v_fb;
    end

    %% ---------------------------------------------------------------------
    %% 4. NUMERICAL METRIC EXTRACTION (Steady-State & Transient)
    %% ---------------------------------------------------------------------
    % Window A: Steady-state under nominal load (20 ms <= t < 30 ms)
    idx_nom = (t_vec >= 0.020) & (t_vec < 0.030);
    v_raw_nom = v_raw(idx_nom);
    v_out_nom = v_out(idx_nom);

    V_raw_rip_num = max(v_raw_nom) - min(v_raw_nom);
    V_out_rip_num = max(v_out_nom) - min(v_out_nom);
    V_out_avg_nom = mean(v_out_nom);
    PSRR_dB       = 20 * log10(max(1e-6, V_raw_rip_num) / max(1e-6, V_out_rip_num));

    % Window B: Steady-state under stepped heavy load (40 ms <= t <= 50 ms)
    idx_step = (t_vec >= 0.040) & (t_vec <= 0.050);
    v_out_step = v_out(idx_step);
    i_out_step = i_out(idx_step);
    V_out_avg_step = mean(v_out_step);
    I_out_avg_step = mean(i_out_step);
    I_out_avg_nom  = mean(i_out(idx_nom));

    % Load Regulation in Linear Range
    delta_Vout = abs(V_out_avg_nom - V_out_avg_step);
    delta_Iout = abs(I_out_avg_step - I_out_avg_nom);
    load_reg_pct = (delta_Vout / V_out_avg_nom) * 100.0;
    R_out_closed = delta_Vout / max(1e-3, delta_Iout); % Dynamic output impedance (Ohms)

    fprintf('--- STEADY-STATE & TRANSIENT NUMERICAL RESULTS ---\n');
    fprintf('  Nominal Regulated Output (V_out):    %7.3f V\n', V_out_avg_nom);
    fprintf('  Raw DC Rail Ripple (Delta V_raw):    %7.4f V\n', V_raw_rip_num);
    fprintf('  Regulated Output Ripple (Delta V_o): %7.5f V (%6.2f mV)\n', V_out_rip_num, V_out_rip_num*1e3);
    fprintf('  Ripple Rejection Ratio (PSRR):       %7.2f dB\n', PSRR_dB);
    fprintf('  Load Step Output (8 Ohms):           %7.3f V\n', V_out_avg_step);
    fprintf('  Load Regulation (Delta V / V_nom):   %7.3f %%\n', load_reg_pct);
    fprintf('  Closed-Loop Output Impedance (Z_o):  %7.4f Ohms (%6.2f mOhms)\n\n', R_out_closed, R_out_closed*1e3);

    %% ---------------------------------------------------------------------
    %% 5. BODE LOOP ANALYSIS & PHASE MARGIN CALCULATION
    %% ---------------------------------------------------------------------
    % Small-Signal Linearization of the Complete Feedback Loop:
    % Forward Path: Differential Pair -> Degenerated VAS Miller -> Emitter Follower
    g_m_diff   = p.I_tail / (2.0 * p.V_T); % Differential pair transconductance = 38.67 mS
    g_m_vas    = 1.0 / (p.R_E + (p.V_T / (p.I_tail / 2.0))); % Degenerated VAS transconductance
    A_vas_dc   = g_m_vas * p.R_C;          % VAS voltage gain
    C_miller   = p.C_c * (1.0 + A_vas_dc); % Effective Miller input capacitance
    r_out_diff = 40.0e3;                   % Collector impedance of diff stage (Ohms)
    w_p1       = 1.0 / (r_out_diff * C_miller); % Dominant Miller pole (rad/s)
    
    % Small-signal Laplace variable s
    s = tf('s');
    
    % Output Stage Impedance with ESR zero and load pole
    Z_Cout = p.R_out_esr + 1.0 / (s * p.C_out);
    Z_load = (p.R_load_nom * Z_Cout) / (p.R_load_nom + Z_Cout);
    g_m_pass = I_out_nom / p.V_T;
    r_pass_out = p.R_sc + (1.0 / g_m_pass);
    A_pass = Z_load / (Z_load + r_pass_out);
    
    % VAS Transfer function with dominant pole
    H_vas  = A_vas_dc / (1.0 + s / w_p1);
    
    % Total Open-Loop Transfer Function: T(s) = beta * g_m_diff * r_out_diff * (H_vas / A_vas_dc) * A_pass
    T_loop = beta_div * g_m_diff * r_out_diff * (H_vas / A_vas_dc) * A_pass;
    
    [Gm, Pm, Wcg, Wcp] = margin(T_loop);
    Gm_dB = 20 * log10(max(1e-4, Gm));
    f_crossover = Wcp / (2 * pi);

    fprintf('--- FREQUENCY-DOMAIN STABILITY METRICS (BODE) ---\n');
    fprintf('  Gain Crossover Frequency (f_cg):     %7.2f kHz\n', f_crossover / 1e3);
    fprintf('  Phase Margin (PM):                   %7.2f deg\n', Pm);
    fprintf('  Gain Margin (GM):                    %7.2f dB\n', Gm_dB);
    fprintf('  Stability Status:                    %s\n', ternary(Pm >= 45.0, 'STABLE (IEEE Compliant)', 'MARGINAL'));
    fprintf('==================================================================\n\n');

    %% ---------------------------------------------------------------------
    %% 6. COMPREHENSIVE MULTI-PANEL VISUALIZATION (HIGH-CONTRAST WHITE THEME)
    %% ---------------------------------------------------------------------
    fig = figure('Name', 'Discrete Linear Regulator — Digital Twin Simulation', ...
                 'Color', 'w', 'Position', [80, 50, 1100, 850], 'Visible', 'off');
    set(gcf, 'Color', 'w');

    % Subplot 1: Stage 1 Raw DC Rail & Secondary AC
    subplot(3, 2, 1);
    plot(t_vec * 1e3, v_sec, 'Color', [0.0, 0.45, 0.9], 'LineWidth', 2.0); hold on;
    plot(t_vec * 1e3, v_raw, 'Color', [0.85, 0.1, 0.1], 'LineWidth', 2.0);
    grid on; box on;
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', 'GridAlpha', 0.35);
    title('{\bf Stage 1: Tensión Secundaria y Riel Raw DC } V_{RAW}(t)', 'Interpreter', 'tex', 'Color', 'k');
    xlabel('Tiempo [ms]', 'Interpreter', 'tex', 'Color', 'k');
    ylabel('Tensión [V]', 'Interpreter', 'tex', 'Color', 'k');
    legend('v_{sec}(t)', 'V_{RAW}(t)', 'Location', 'northeast', 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.5, 0.5, 0.5]);
    xlim([0, 50]);

    % Subplot 2: Stage 5 Regulated Output Voltage with Load Step
    subplot(3, 2, 2);
    plot(t_vec * 1e3, v_out, 'Color', [0.05, 0.65, 0.2], 'LineWidth', 2.0); hold on;
    xline(p.t_step * 1e3, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.3, ...
          'Label', 'Paso de Carga', 'LabelOrientation', 'horizontal', ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'bottom', 'Color', 'k');
    yline(V_out_target, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 1.3, ...
          'Label', sprintf('V_{target} = %.2f V', V_out_target), ...
          'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom', 'Color', 'k');
    grid on; box on;
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', 'GridAlpha', 0.35);
    title(sprintf('{\\bf Stage 5: Tensión Regulada de Salida } v_o(t) {\\bf [Rizado: %.2f mV]}', V_out_rip_num*1e3), ...
          'Interpreter', 'tex', 'Color', 'k');
    xlabel('Tiempo [ms]', 'Interpreter', 'tex', 'Color', 'k');
    ylabel('Tensión [V]', 'Interpreter', 'tex', 'Color', 'k');
    xlim([0, 50]);
    ylim([0, V_out_target * 1.25]);

    % Subplot 3: Stage 2 & 4 VAS Drive and Reference Node
    subplot(3, 2, 3);
    plot(t_vec * 1e3, v_VAS, 'Color', [0.6, 0.1, 0.75], 'LineWidth', 2.0); hold on;
    plot(t_vec * 1e3, v_ref, 'Color', [0.95, 0.45, 0.0], 'LineWidth', 2.0);
    plot(t_vec * 1e3, v_fb,  'Color', [0.0, 0.65, 0.85], 'LineStyle', '--', 'LineWidth', 1.8);
    grid on; box on;
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', 'GridAlpha', 0.35);
    title('{\bf Stages 2, 3, 4: Nodos Internos } (v_{VAS}, V_{ref}, v_{fb})', 'Interpreter', 'tex', 'Color', 'k');
    xlabel('Tiempo [ms]', 'Interpreter', 'tex', 'Color', 'k');
    ylabel('Tensión [V]', 'Interpreter', 'tex', 'Color', 'k');
    legend('v_{VAS} (Drive)', 'V_{ref} (Zener)', 'v_{fb} (Divisor)', 'Location', 'best', 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.5, 0.5, 0.5]);
    xlim([0, 50]);

    % Subplot 4: Output Current and Current Limit Protection
    subplot(3, 2, 4);
    plot(t_vec * 1e3, i_out, 'Color', [0.95, 0.4, 0.0], 'LineWidth', 2.0); hold on;
    yline(I_out_limit, 'Color', [0.85, 0.0, 0.0], 'LineStyle', '--', 'LineWidth', 1.5, ...
          'Label', sprintf('Límite I_{sc} = %.2f A', I_out_limit), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'bottom', 'Color', [0.85, 0.0, 0.0]);
    grid on; box on;
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', 'GridAlpha', 0.35);
    title('{\bf Corriente de Salida } i_{out}(t) {\bf y Protección Limitadora}', 'Interpreter', 'tex', 'Color', 'k');
    xlabel('Tiempo [ms]', 'Interpreter', 'tex', 'Color', 'k');
    ylabel('Corriente [A]', 'Interpreter', 'tex', 'Color', 'k');
    xlim([0, 50]);
    ylim([0, I_out_limit * 1.35]);

    % Subplot 5 & 6: Bode Magnitude & Phase Stability Analysis
    subplot(3, 2, [5, 6]);
    [mag, phase, w_bode] = bode(T_loop, {2*pi*1, 2*pi*1e7});
    mag_dB   = squeeze(20 * log10(mag));
    phase_deg= squeeze(phase);
    f_bode   = w_bode / (2 * pi);

    yyaxis left
    semilogx(f_bode, mag_dB, 'Color', [0.0, 0.3, 0.8], 'LineWidth', 2.0);
    ylabel('Magnitud de Lazo [dB]', 'Interpreter', 'tex', 'FontSize', 10);
    ylim([-40, 80]);
    yline(0, 'Color', [0.3, 0.3, 0.3], 'LineStyle', '--', 'LineWidth', 1.0);
    set(gca, 'YColor', [0.0, 0.3, 0.8]);

    yyaxis right
    semilogx(f_bode, phase_deg, 'Color', [0.85, 0.1, 0.1], 'LineWidth', 2.0);
    ylabel('Fase de Lazo [grados]', 'Interpreter', 'tex', 'FontSize', 10);
    ylim([-180, 0]);
    yline(-180, 'Color', [0.85, 0.1, 0.1], 'LineStyle', ':', 'LineWidth', 1.2);
    set(gca, 'YColor', [0.85, 0.1, 0.1]);

    grid on; box on;
    set(gca, 'Color', 'w', 'XColor', 'k', 'GridColor', 'k', 'GridAlpha', 0.35);
    title(sprintf('{\\bf Respuesta en Frecuencia a Lazo Abierto (Bode): Margen de Fase PM = %.1f^\\circ } [f_c = %.1f kHz, PSRR = %.1f dB]', ...
          Pm, f_crossover/1e3, PSRR_dB), 'Interpreter', 'tex', 'Color', 'k');
    xlabel('Frecuencia [Hz]', 'Interpreter', 'tex', 'Color', 'k');

    % Export High-Resolution Verification Figure to Absolute Workspace Path
    plot_out = '.simulations\matlab\integrated_system_response.png';
    exportgraphics(fig, plot_out, 'Resolution', 300);
    fprintf('Saved high-resolution simulation dashboard to: %s\n', plot_out);
    close(fig);
end

%% =========================================================================
%% DIFFERENTIAL-ALGEBRAIC DYNAMICS SUBFUNCTION
%% =========================================================================
function [dxdt, alg] = integrated_dynamics(t, x, p)
    % Unpack continuous states
    v_filt = max(0.0, x(1));
    v_VAS  = max(0.0, x(2));
    v_Cout = max(0.0, x(3));

    % --- 1. Secondary AC and Diode Bridge Rectification ---
    v_sec_instant = p.V_sec_pk * sin(p.w_line * t);
    v_rect_ideal  = abs(v_sec_instant);

    if v_rect_ideal > (v_filt + p.V_bridge_drop)
        i_rect = (v_rect_ideal - p.V_bridge_drop - v_filt) / p.R_bridge_fwd;
    else
        i_rect = 0.0;
    end
    i_bleed = v_filt / p.R_bleed;

    % Headroom modulation: active silicon circuits cannot draw current when V_RAW is unpowered
    headroom = min(1.0, max(0.0, v_filt / 3.0));
    i_tail_actual = p.I_tail * headroom;

    % --- 2. Zener Bias & Reference Voltage ---
    if v_filt > p.V_Z_nom
        i_bias = (v_filt - p.V_Z_nom) / (p.R_bias + p.r_z);
        v_ref  = p.V_Z_nom + i_bias * p.r_z;
    else
        i_bias = max(0.0, v_filt / p.R_bias);
        v_ref  = v_filt;
    end

    % --- 3. Output Stage, Series Pass & Load Dynamics ---
    % Dynamic load step evaluation
    if t >= p.t_step
        R_load = p.R_load_step;
    else
        R_load = p.R_load_nom;
    end

    G_div  = 1.0 / (p.R1 + p.R2);
    G_load = 1.0 / R_load;
    G_eq   = G_load + G_div;

    % Pass transistor emitter potential with Darlington V_BE drop
    v_emit = max(0.0, v_VAS - p.V_BE_tot);

    % Output node algebraic solution with ESR coupling
    G_sc = 1.0 / p.R_sc;
    if v_emit > v_Cout
        v_out = (v_Cout + p.R_out_esr * G_sc * v_emit) / (1.0 + p.R_out_esr * (G_sc + G_eq));
        i_pass = max(0.0, (v_emit - v_out) * G_sc);
    else
        v_out = v_Cout / (1.0 + p.R_out_esr * G_eq);
        i_pass = 0.0;
    end

    i_out  = i_pass;
    i_load = v_out * G_eq;
    i_Cout = i_pass - i_load;

    % --- 4. Current Limiting Transistor Action ---
    v_BE_lim = i_out * p.R_sc;
    if v_BE_lim > p.V_BE_limit
        i_limit = p.g_m_lim * (v_BE_lim - p.V_BE_limit);
    else
        i_limit = 0.0;
    end

    % --- 5. Error Amplifier & Active Mirror Transconductance ---
    v_fb   = v_out * (p.R2 / (p.R1 + p.R2));
    v_diff = v_ref - v_fb;
    
    % --- 6. VAS Integration (Miller Capacitor C_c) ---
    % Smooth pull-up from raw rail through R_C
    i_pullup = max(0.0, (v_filt - v_VAS) / p.R_C);
    
    % VAS sink current commanded by differential pair transconductance
    i_vas_sink = (i_tail_actual / 2.0) * (1.0 - tanh(v_diff / (2.0 * p.V_T)) * (p.beta_vas / 10.0));
    i_vas_sink = max(0.0, i_vas_sink);

    % Base current drawn by Darlington input driver Q_drv:
    i_base_drv = i_pass / p.beta_darlington;

    % Net current integrating into Miller compensation capacitor C_c
    i_VAS_net = i_pullup - i_vas_sink - i_limit - i_base_drv;
    
    % Physical saturation boundary handling
    if (v_VAS <= 0.0) && (i_VAS_net < 0.0)
        dv_VAS_dt = 0.0;
    else
        dv_VAS_dt = i_VAS_net / p.C_c;
    end

    % --- 7. Bulk Filter Capacitor Derivative ---
    i_raw_total = i_bleed + i_bias + i_tail_actual + i_pullup + i_pass;
    dv_filt_dt  = (i_rect - i_raw_total) / p.C_filt;

    % --- 8. Output Filter Capacitor Derivative ---
    dv_Cout_dt  = i_Cout / p.C_out;

    % Assemble state derivative vector
    dxdt = [dv_filt_dt; dv_VAS_dt; dv_Cout_dt];

    % Pack algebraic outputs if requested
    if nargout > 1
        alg.v_ref = v_ref;
        alg.v_out = v_out;
        alg.i_out = i_out;
        alg.v_fb  = v_fb;
    end
end

%% Helper ternary function
function val = ternary(cond, a, b)
    if cond
        val = a;
    else
        val = b;
    end
end
