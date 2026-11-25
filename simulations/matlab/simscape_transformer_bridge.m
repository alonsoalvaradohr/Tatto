% SPDX-License-Identifier: CERN-OHL-S-2.0
% Copyright (C) 2024-2026 Alonso Alvarado Hernández <alonsoalvaradohr>
%% =========================================================================
%% TATTO PROJECT — STAGE 1: TRANSFORMER & FULL-WAVE BRIDGE RECTIFIER
%% File: simscape_transformer_bridge.m
%% Standard: 2026 Multi-Agent Standard (Parametric Agnosticism & Twin Modeling)
%% Solvers: ode23t (Differential-Algebraic Stiff Solver) & Analytical Model
%% Test Points: TP_1 (Secondary AC) and TP_2 (Raw DC Rail with Ripple)
%% =========================================================================

function simscape_transformer_bridge()
    close all; clc;
    fprintf('==================================================================\n');
    fprintf(' TATTO POWER SUPPLY — STAGE 1 SIMULATION (TRANSFORMER & BRIDGE)  \n');
    fprintf('==================================================================\n\n');

    %% ---------------------------------------------------------------------
    %% 1. SYSTEM PARAMETRIC DEFINITIONS (100% Parameterized)
    %% ---------------------------------------------------------------------
    V_pri_rms   = 120.0;             % Primary AC mains RMS voltage (V)
    f_line      = 60.0;              % Mains frequency (Hz)
    w_line      = 2 * pi * f_line;   % Angular frequency (rad/s)
    T_line      = 1 / f_line;        % Line period (s) = ~16.67 ms
    
    N_ratio     = 8.66;              % Turns ratio Np / Ns
    k_T         = 1.0 / N_ratio;     % Step-down factor Ns / Np
    
    % Secondary & Parasitic Winding Parameters
    R_sec_w     = 0.05;              % Secondary winding resistance (Ohms)
    
    % Diode Bridge Parameters (Silicon Rectifier D1N4007 / KBPC)
    V_D         = 0.75;              % Diode forward threshold voltage (V)
    r_d         = 0.035;             % Diode dynamic bulk resistance (Ohms)
    V_bridge_drop = 2 * V_D;         % Total bridge forward drop (two conducting diodes)
    R_bridge_fwd  = 2 * r_d + R_sec_w;% Total forward conduction loop resistance
    
    % Bulk Filter & Bleeder Stage
    C_filt      = 18000e-6;          % Bulk smoothing capacitor (Farads = 18 mF)
    R_bleed     = 470.0;             % Bleeder discharge resistor (Ohms)
    R_load_nom  = 12.0;              % Nominal DC load resistance (Ohms)
    R_eq        = (R_bleed * R_load_nom) / (R_bleed + R_load_nom); % Total equivalent DC load
    
    %% ---------------------------------------------------------------------
    %% 2. THEORETICAL & ANALYTICAL DEDUCTIONS
    %% ---------------------------------------------------------------------
    V_pri_pk    = V_pri_rms * sqrt(2.0);
    V_sec_pk    = V_pri_pk * k_T;
    V_raw_pk    = V_sec_pk - V_bridge_drop;
    I_load_nom  = V_raw_pk / R_eq;
    
    % Classical Approximation for Ripple (Haris Muneer & Schade Model)
    % Discharge period between replenishment peaks in full-wave rectification:
    % T_discharge ~ 1 / (2 * f_line) = 8.33 ms
    T_dis_approx = 1.0 / (2.0 * f_line);
    
    % Exponential decay formula: V_min = V_pk * exp(-T_dis / (R * C))
    V_raw_min_analytical = V_raw_pk * exp(-T_dis_approx / (R_eq * C_filt));
    V_ripple_analytical  = V_raw_pk - V_raw_min_analytical;
    
    % Linearized first-order ripple approximation: delta_V ~ I_load / (2 * f * C)
    V_ripple_linear      = I_load_nom / (2.0 * f_line * C_filt);
    
    % Diode Conduction Angle (theta_c in radians)
    theta_c = acos(max(-1.0, min(1.0, 1.0 - (V_ripple_analytical / V_sec_pk))));
    t_conduction = theta_c / w_line;
    
    % Repetitive Peak Diode Current (Surge calculation)
    I_peak_diode = I_load_nom * (1.0 + pi * sqrt((2.0 * V_sec_pk) / max(1e-3, V_ripple_analytical)));
    
    V_dc_avg_analytical  = V_raw_pk - (V_ripple_analytical / 2.0);

    fprintf('--- ANALYTICAL PREDICTIONS ---\n');
    fprintf('  Primary Peak Voltage (V_pri_pk):     %7.2f V\n', V_pri_pk);
    fprintf('  Secondary Peak Voltage (V_sec_pk):   %7.2f V\n', V_sec_pk);
    fprintf('  Peak Raw DC Rail (V_raw_pk):         %7.2f V\n', V_raw_pk);
    fprintf('  Analytical P-P Ripple (Exponential): %7.4f V\n', V_ripple_analytical);
    fprintf('  Analytical P-P Ripple (Linearized):  %7.4f V\n', V_ripple_linear);
    fprintf('  Mean Raw DC Level (V_dc_avg):        %7.2f V\n', V_dc_avg_analytical);
    fprintf('  Nominal Load Current (I_load):       %7.3f A\n', I_load_nom);
    fprintf('  Diode Conduction Angle (theta_c):    %7.2f deg (%6.3f ms)\n', rad2deg(theta_c), t_conduction*1e3);
    fprintf('  Repetitive Peak Diode Surge (I_pk):  %7.2f A\n\n', I_peak_diode);

    %% ---------------------------------------------------------------------
    %% 3. NUMERICAL INTEGRATION USING ode23t (Stiff Trapezoidal Solver)
    %% ---------------------------------------------------------------------
    % Time span: 0 to 50 ms (~3 full AC cycles)
    t_span = [0, 0.050];
    v0     = 0.0; % Initial condition: capacitor fully discharged (UIC)
    
    % Solver options enforcing Gear/Trapezoidal precision
    options = odeset('RelTol', 1e-4, 'AbsTol', 1e-6, 'MaxStep', 1e-5);
    
    % State equation: C * dV_C/dt = i_rect(t) - i_load(t)
    ode_fun = @(t, vC) rectifier_dynamics(t, vC, V_sec_pk, w_line, V_bridge_drop, R_bridge_fwd, R_eq, C_filt);
    
    [t_vec, vC_vec] = ode23t(ode_fun, t_span, v0, options);
    
    % Secondary AC Waveform at TP_1
    v_TP1 = V_sec_pk * sin(w_line * t_vec);
    % Raw DC Voltage at TP_2
    v_TP2 = vC_vec;

    %% ---------------------------------------------------------------------
    %% 4. NUMERICAL METRIC EXTRACTION IN STEADY-STATE
    %% ---------------------------------------------------------------------
    % Analyze steady-state window: last 1.5 cycles (t in [25 ms, 50 ms])
    ss_idx = t_vec >= 0.025;
    t_ss   = t_vec(ss_idx);
    v_ss   = v_TP2(ss_idx);
    
    V_raw_max_num   = max(v_ss);
    V_raw_min_num   = min(v_ss);
    V_ripple_num    = V_raw_max_num - V_raw_min_num;
    V_dc_avg_num    = mean(v_ss);
    ripple_error_pct= abs(V_ripple_num - V_ripple_analytical) / V_ripple_num * 100.0;

    fprintf('--- NUMERICAL ode23t SIMULATION RESULTS ---\n');
    fprintf('  Maximum Raw DC Voltage (V_raw_max):  %7.3f V\n', V_raw_max_num);
    fprintf('  Minimum Raw DC Voltage (V_raw_min):  %7.3f V\n', V_raw_min_num);
    fprintf('  Simulated Peak-to-Peak Ripple:       %7.4f V\n', V_ripple_num);
    fprintf('  Simulated Average DC Voltage:        %7.3f V\n', V_dc_avg_num);
    fprintf('  Discrepancy (Analytical vs ODE):     %7.2f %%\n', ripple_error_pct);
    fprintf('==================================================================\n\n');

    %% ---------------------------------------------------------------------
    %% 5. DUAL-CHANNEL OSCILLOSCOPE VISUALIZATION (Matching TikZ Scopes)
    %% ---------------------------------------------------------------------
    fig = figure('Name', 'Stage 1: Transformer & Bridge Rectifier Simulation', ...
                 'Color', 'w', 'Position', [100, 100, 950, 650], 'Visible', 'off');
    set(gcf, 'Color', 'w');

    % Channel 1: Secondary AC Voltage v_TP1(t)
    subplot(2, 1, 1);
    plot(t_vec * 1e3, v_TP1, 'Color', [0.0, 0.45, 0.9], 'LineWidth', 2.0);
    hold on; grid on; box on;
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', 'GridAlpha', 0.35);
    yline(0, 'Color', [0.4, 0.4, 0.4], 'LineStyle', '--', 'LineWidth', 0.8);
    yline(V_sec_pk, 'Color', [0.2, 0.5, 0.8], 'LineStyle', ':', 'LineWidth', 1.2, ...
          'Label', sprintf('+V_{sec,pk} = +%.2f V', V_sec_pk), 'LabelHorizontalAlignment', 'left', 'Color', 'k');
    yline(-V_sec_pk, 'Color', [0.2, 0.5, 0.8], 'LineStyle', ':', 'LineWidth', 1.2, ...
          'Label', sprintf('-V_{sec,pk} = -%.2f V', -V_sec_pk), 'LabelHorizontalAlignment', 'left', 'Color', 'k');
    title('{\bf CH1: Tensión Alterna del Secundario } v_{sec}(t) {\bf [Punto de Prueba TP_1]}', 'Interpreter', 'tex', 'Color', 'k');
    xlabel('Tiempo [ms]', 'Interpreter', 'tex', 'FontSize', 10, 'Color', 'k');
    ylabel('Tensión [V]', 'Interpreter', 'tex', 'FontSize', 10, 'Color', 'k');
    xlim([0, 50]);
    ylim([-V_sec_pk * 1.25, V_sec_pk * 1.25]);

    % Channel 2: Raw DC Rail v_TP2(t) with Ripple
    subplot(2, 1, 2);
    plot(t_vec * 1e3, v_TP2, 'Color', [0.85, 0.1, 0.1], 'LineWidth', 2.0);
    hold on; grid on; box on;
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', 'GridAlpha', 0.35);
    yline(V_raw_max_num, 'Color', [0.8, 0.2, 0.2], 'LineStyle', ':', 'LineWidth', 1.2, ...
          'Label', sprintf('V_{RAW,max} = %.2f V', V_raw_max_num), 'LabelHorizontalAlignment', 'left', 'Color', 'k');
    yline(V_raw_min_num, 'Color', [0.8, 0.2, 0.2], 'LineStyle', ':', 'LineWidth', 1.2, ...
          'Label', sprintf('V_{RAW,min} = %.2f V', V_raw_min_num), 'LabelHorizontalAlignment', 'left', 'Color', 'k');
    yline(V_dc_avg_num, 'Color', [0.3, 0.3, 0.3], 'LineStyle', '--', 'LineWidth', 1.2, ...
          'Label', sprintf('V_{RAW,avg} = %.2f V', V_dc_avg_num), 'LabelHorizontalAlignment', 'right', 'Color', 'k');
    title(sprintf('{\\bf CH2: Riel DC No Regulado } V_{RAW}(t) {\\bf [TP_2]  (Rizado } \\Delta V_{ripple} = %.3f V {\\bf )}', V_ripple_num), ...
          'Interpreter', 'tex', 'Color', 'k');
    xlabel('Tiempo [ms]', 'Interpreter', 'tex', 'FontSize', 10, 'Color', 'k');
    ylabel('Tensión [V]', 'Interpreter', 'tex', 'FontSize', 10, 'Color', 'k');
    xlim([0, 50]);
    ylim([0, V_sec_pk * 1.15]);

    % Export High-Resolution Plot Image
    plot_out = fullfile(fileparts(mfilename('fullpath')), 'stage1_simulation_response.png');
    exportgraphics(fig, plot_out, 'Resolution', 300);
    fprintf('Saved simulation response figure to: %s\n', plot_out);
    close(fig);
end

%% =========================================================================
%% DIFFERENTIAL-ALGEBRAIC DYNAMICS SUBFUNCTION
%% =========================================================================
function dvC_dt = rectifier_dynamics(t, vC, V_sec_pk, w_line, V_bridge_drop, R_fwd, R_load, C)
    % Instantaneous secondary open-circuit voltage
    v_sec_instant = V_sec_pk * sin(w_line * t);
    
    % Full-wave rectified instantaneous voltage before diode threshold
    v_rect_ideal = abs(v_sec_instant);
    
    % Conduction check: Diodes only conduct when instantaneous rectified AC
    % exceeds the capacitor voltage by the double-diode forward drop 2*V_D
    if v_rect_ideal > (vC + V_bridge_drop)
        % Conduction phase: current delivered from secondary into cap + load
        i_diode = (v_rect_ideal - V_bridge_drop - vC) / R_fwd;
    else
        % Reverse-biased phase: diodes blocked
        i_diode = 0.0;
    end
    
    % Capacitor current: i_C = i_diode - i_load
    i_load  = vC / R_load;
    dvC_dt  = (i_diode - i_load) / C;
end
