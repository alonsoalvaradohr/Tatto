%% =========================================================================
%% TATTO PROJECT — ULTIMATE HOSTILE STRESS-TEST ORACLE (PHASE 7.3)
%% File: simulations/matlab/stress_testbench.m
%% Mission: Validate Discrete Silicon Topology against Extreme Line Perturbations
%% Stimuli: Pure Sine, Triangular, Sawtooth, and Chaotic Surges on V_ac(t)
%% Solver: ode23t (Differential-Algebraic Stiff Solver)
%% Biunivocal Fidelity with: simulations/spice/stress_testbench.cir
%%                        figures/tikz/master_integrated_system.tex
%% =========================================================================

function stress_testbench()
    close all; clc;
    fprintf('====================================================================\n');
    fprintf(' TATTO POWER SUPPLY — HOSTILE STRESS-TEST ORACLE (PHASE 7.3)        \n');
    fprintf(' Severe Input Stimuli: Dynamic Sine, Triangular, Sawtooth & Noise   \n');
    fprintf(' Goal: Verify Closed-Loop Rejection and Stable DC Output at v_o     \n');
    fprintf('====================================================================\n\n');

    %% ---------------------------------------------------------------------
    %% 1. SYSTEM PARAMETRIC DEFINITIONS
    %% ---------------------------------------------------------------------
    p = struct();

    % Transformer & Bridge
    p.k_T           = 0.15;       % Secondary/primary turns ratio
    p.R_sec_w       = 0.05;       % Winding resistance (Ohms)
    p.V_D           = 0.75;       % Diode forward drop (V)
    p.r_d           = 0.035;      % Diode bulk resistance (Ohms)
    p.V_bridge_drop = 2 * p.V_D;  % Total bridge forward drop (V) = 1.5 V
    p.R_bridge_fwd  = 2*p.r_d + p.R_sec_w;
    p.C_filt        = 4700e-6;    % Bulk filter capacitor (F)
    p.R_bleed       = 1000.0;     % Bleeder resistor (Ohms)

    % Reference & Bias
    p.R_bias        = 1500.0;     % Zener bias resistor (Ohms)
    p.V_Z_nom       = 5.1;        % Nominal Zener voltage (V)
    p.r_z           = 10.0;       % Zener dynamic impedance (Ohms)

    % Error Amplifier (Diff Pair & Active Mirror)
    p.I_tail        = 2.0e-3;     % Tail current (A)
    p.V_T           = 0.02586;    % Thermal voltage (V)
    p.beta_npn      = 200.0;      % NPN gain
    p.beta_pnp      = 180.0;      % PNP gain
    p.V_A_pnp       = 100.0;      % Early voltage (V)

    % VAS & Miller Compensation
    p.R_E           = 100.0;      % Degeneration resistor (Ohms)
    p.R_C           = 2200.0;     % Collector pull-up (Ohms)
    p.C_c           = 100e-12;    % Miller capacitor (F)
    p.beta_vas      = 200.0;

    % Darlington Pass Stage & Current Limiter
    p.beta_drv      = 200.0;      % Q_drv gain
    p.beta_pass     = 60.0;       % Q_pass gain (TIP31C)
    p.beta_darling  = p.beta_drv * p.beta_pass; % Composite beta ~ 12,000
    p.V_BE_drv      = 0.70;       % Driver V_BE
    p.V_BE_pass     = 0.75;       % Power pass V_BE
    p.V_BE_darling  = p.V_BE_drv + p.V_BE_pass; % 1.45 V total drop
    p.R_sc          = 0.33;       % Current sense resistor (Ohms)
    p.V_BE_limit    = 0.65;       % Q_limit activation threshold (V)
    p.C_out         = 100e-6;     % Output smoothing capacitor (F)
    p.R_esr         = 0.05;       % Output capacitor ESR (Ohms)

    % Feedback Divider (Target = 12.0 V with V_ref = 5.1 V)
    p.R2            = 3300.0;     % Bottom feedback resistor (Ohms)
    p.R1            = 4470.0;     % Top feedback resistor (Ohms)
    p.beta_fb       = p.R2 / (p.R1 + p.R2); % ~ 0.4247

    % Full Rated Load (10 Ohms -> 1.20 A nominal)
    p.R_load        = 10.0;

    %% ---------------------------------------------------------------------
    %% 2. HOSTILE INPUT EXCITATION FUNCTION v_ac(t)
    %% ---------------------------------------------------------------------
    % Multi-phase severe disturbance profile:
    % Phase A [0..30 ms]:   Over/under-voltage Sine (120V to 180V pk, 50 to 90 Hz)
    % Phase B [30..60 ms]:  Severe Triangular Wave (+/-165V pk, 75 Hz)
    % Phase C [60..90 ms]:  High-slew Sawtooth Wave (-150V to +185V pk, 100 Hz)
    % Phase D [90..120 ms]: Chaotic surges and multi-frequency line noise (up to 220V pk)

    function vac = hostile_vac(t)
        if t < 0.030
            % Frequency modulation & amplitude surges on sine wave
            f_inst = 60.0 + 30.0 * sin(2*pi*25*t);
            V_pk_inst = 150.0 + 35.0 * sin(2*pi*15*t);
            vac = V_pk_inst * sin(2*pi*f_inst*t);
        elseif t < 0.060
            % Triangular wave at 80 Hz with steep gradients
            t_rel = t - 0.030;
            T_tri = 1 / 80.0;
            phase = mod(t_rel, T_tri) / T_tri; % 0 to 1
            if phase < 0.5
                tri_norm = 4 * phase - 1; % -1 to +1
            else
                tri_norm = 3 - 4 * phase; % +1 to -1
            end
            vac = 165.0 * tri_norm;
        elseif t < 0.090
            % Sawtooth wave with rapid dV/dt fall-off
            t_rel = t - 0.060;
            T_saw = 1 / 100.0;
            phase = mod(t_rel, T_saw) / T_saw; % 0 to 1
            saw_norm = 2 * phase - 1; % -1 to +1
            vac = 175.0 * saw_norm + 15.0 * sin(2*pi*800*t); % Sawtooth + 800Hz ringing
        else
            % Chaotic surge pulses + high-amplitude harmonic distortion
            f_base = 60.0;
            harmonic_3 = 35.0 * sin(2*pi*180*t);
            harmonic_5 = 20.0 * sin(2*pi*300*t);
            surge = 50.0 * exp(-mod(t-0.090, 0.015)/0.003); % Recurrent surge spikes
            vac = 160.0 * sin(2*pi*f_base*t) + harmonic_3 + harmonic_5 + surge;
        end
    end

    %% ---------------------------------------------------------------------
    %% 3. STIFF NON-LINEAR STATE-SPACE SYSTEM
    %% State vector: x = [v_filt; v_vas; v_out]
    %% ---------------------------------------------------------------------
    function dxdt = state_derivatives(t, x)
        v_filt = x(1);
        v_vas  = x(2);
        v_out  = x(3);

        % Instantaneous hostile input and rectified secondary
        vac_t   = hostile_vac(t);
        v_sec_t = abs(vac_t) * p.k_T;

        % Full-Wave Diode Bridge Conduction
        if v_sec_t > (v_filt + p.V_bridge_drop)
            i_bridge = (v_sec_t - (v_filt + p.V_bridge_drop)) / p.R_bridge_fwd;
        else
            i_bridge = 0.0;
        end

        % Stage 2: Zener Reference
        v_raw = max(v_filt, 0.0);
        i_bias = max((v_raw - p.V_Z_nom) / (p.R_bias + p.r_z), 0.0);
        v_ref = p.V_Z_nom + i_bias * p.r_z;

        % Stage 3: Error Amplifier Transconductance
        v_fb = p.beta_fb * v_out;
        v_diff = v_ref - v_fb; % Positive when output is low
        g_m_diff = p.I_tail / (2 * p.V_T);
        i_diff_out = (p.I_tail / 2) * tanh(v_diff / (2 * p.V_T));

        % Stage 4: VAS Dynamics (Miller Integration)
        % dv_vas/dt = (i_diff_out + pullup - base_drive) / C_c
        i_pullup = max((v_raw - v_vas) / p.R_C, 0.0);
        
        % Stage 5: Darlington Pass Stage & Current Limiter
        i_load = v_out / p.R_load;
        v_sense_drop = i_load * p.R_sc;
        
        % Limit action: if v_sense_drop > 0.65 V, Q_limit steals base current
        if v_sense_drop > p.V_BE_limit
            i_steal = 1.0e-3 * exp((v_sense_drop - p.V_BE_limit) / 0.025);
        else
            i_steal = 0.0;
        end

        % Base current required by Darlington pair: i_b_drv = i_load / beta_darling
        i_b_darling = max(i_load / p.beta_darling, 0.0) + i_steal;

        % VAS voltage derivative
        dv_vas_dt = (i_diff_out - i_b_darling + 0.1 * (i_pullup - i_diff_out)) / p.C_c;
        % Clamping VAS to physical rail limits
        if v_vas > v_raw && dv_vas_dt > 0
            dv_vas_dt = 0;
        elseif v_vas < 0.5 && dv_vas_dt < 0
            dv_vas_dt = 0;
        end

        % Emitter follower output target from VAS:
        % v_target = v_vas - V_BE_darling - v_sense_drop
        v_target = max(v_vas - p.V_BE_darling - v_sense_drop, 0.0);

        % Output capacitor dynamics
        i_pass_out = max((v_target - v_out) / (p.R_sec_w + 0.02), 0.0);
        dv_out_dt = (i_pass_out - i_load) / p.C_out;

        % Filter capacitor current balance
        i_bleed = v_filt / p.R_bleed;
        i_raw_feed = i_bias + i_pullup + i_load;
        dv_filt_dt = (i_bridge - i_bleed - i_raw_feed) / p.C_filt;

        dxdt = [dv_filt_dt; dv_vas_dt; dv_out_dt];
    end

    %% ---------------------------------------------------------------------
    %% 4. NUMERICAL INTEGRATION VIA ode23t (Stiff Differential Solver)
    %% ---------------------------------------------------------------------
    fprintf('Executing stiff integration via ode23t (0 to 120 ms)...\n');
    t_span = [0.0, 0.120];
    x0 = [18.0; 13.5; 12.0]; % Initial conditions close to nominal operating point

    opts = odeset('RelTol', 1e-4, 'AbsTol', 1e-5, 'MaxStep', 50e-6);
    [t_sol, x_sol] = ode23t(@state_derivatives, t_span, x0, opts);

    v_filt_sol = x_sol(:, 1);
    v_vas_sol  = x_sol(:, 2);
    v_out_sol  = x_sol(:, 3);

    % Compute input waveforms over the solution grid
    vac_sol = zeros(size(t_sol));
    vsec_sol = zeros(size(t_sol));
    for k = 1:length(t_sol)
        vac_sol(k) = hostile_vac(t_sol(k));
        vsec_sol(k) = abs(vac_sol(k)) * p.k_T;
    end

    %% ---------------------------------------------------------------------
    %% 5. STATISTICAL METRICS & PERFORMANCE EVALUATION
    %% ---------------------------------------------------------------------
    % Evaluate in steady-state hostile phases (from t = 20 ms to 120 ms)
    mask = t_sol >= 0.020;
    t_eval = t_sol(mask);
    vac_eval = vac_sol(mask);
    vfilt_eval = v_filt_sol(mask);
    vout_eval = v_out_sol(mask);

    vac_max = max(vac_eval);
    vac_min = min(vac_eval);
    vac_pkpk = vac_max - vac_min;

    vfilt_avg = mean(vfilt_eval);
    vfilt_pkpk = max(vfilt_eval) - min(vfilt_eval);

    vout_avg = mean(vout_eval);
    vout_pkpk = max(vout_eval) - min(vout_eval);
    vout_std = std(vout_eval);

    % Dynamic Power Supply Rejection Ratio (PSRR) under stress:
    % PSRR = 20 * log10( Delta_V_raw / Delta_v_o )
    psrr_db = 20 * log10(vfilt_pkpk / max(vout_pkpk, 1e-6));

    fprintf('\n====================================================================\n');
    fprintf(' HOSTILE STRESS-TEST ORACLE VALIDATION RESULTS (PHASE 7.3)\n');
    fprintf('====================================================================\n');
    fprintf(' Input Stimulus Peak-to-Peak Excursion:  %8.2f V  ([-%.1f V .. +%.1f V])\n', vac_pkpk, abs(vac_min), vac_max);
    fprintf(' Unregulated Filter Rail (V_RAW):        %8.2f V  (Ripple: %.2f V p-p)\n', vfilt_avg, vfilt_pkpk);
    fprintf(' Regulated Output DC Voltage (v_o):      %8.3f V  (Nominal Target: 12.000 V)\n', vout_avg);
    fprintf(' Regulated Output Ripple under Stress:   %8.3f mV p-p\n', vout_pkpk * 1000);
    fprintf(' Output Standard Deviation (Noise):      %8.3f mV rms\n', vout_std * 1000);
    fprintf(' Hostile Dynamic PSRR (Rejection Ratio): %8.2f dB\n', psrr_db);
    fprintf(' Load Current Delivered:                 %8.2f A  (R_load = 10.0 Ohm)\n', vout_avg / p.R_load);
    fprintf('====================================================================\n\n');

    %% ---------------------------------------------------------------------
    %% 6. MULTI-PANEL DIAGNOSTIC VISUALIZATION
    %% ---------------------------------------------------------------------
    fig = figure('Name', 'Hostile Stress-Test Validation', ...
                 'Units', 'pixels', 'Position', [100, 100, 1280, 850], ...
                 'Color', 'w', 'Visible', 'off');

    % Subplot 1: Hostile Input Waveform vac(t)
    subplot(4, 1, 1);
    plot(t_sol * 1000, vac_sol, 'Color', [0.1, 0.1, 0.1], 'LineWidth', 1.2);
    grid on; box on;
    xlim([0, 120]); ylim([-240, 240]);
    title('\textbf{Panel 1: Hostile Multi-Phase Input Stimuli $v_{ac}(t)$ (Sine, Triangle, Sawtooth, Surges)}', ...
          'Interpreter', 'latex', 'FontSize', 11);
    ylabel('$v_{ac}(t)$ [V]', 'Interpreter', 'latex', 'FontSize', 10);
    % Stage annotations
    xline(30, '--k', {'Triangle'}, 'LabelVerticalAlignment', 'bottom');
    xline(60, '--k', {'Sawtooth'}, 'LabelVerticalAlignment', 'bottom');
    xline(90, '--k', {'Noise / Surges'}, 'LabelVerticalAlignment', 'bottom');

    % Subplot 2: Unregulated Filter Voltage V_RAW(t)
    subplot(4, 1, 2);
    plot(t_sol * 1000, v_filt_sol, 'Color', [0.2, 0.2, 0.2], 'LineWidth', 1.3);
    grid on; box on;
    xlim([0, 120]);
    title('\textbf{Panel 2: Unregulated Secondary DC Rail $V_{\mathrm{RAW}}(t)$ across Bulk Filter $C_{\mathrm{filt}}$}', ...
          'Interpreter', 'latex', 'FontSize', 11);
    ylabel('$V_{\mathrm{RAW}}(t)$ [V]', 'Interpreter', 'latex', 'FontSize', 10);

    % Subplot 3: Regulated Output Voltage v_o(t)
    subplot(4, 1, 3);
    plot(t_sol * 1000, v_out_sol, 'Color', [0.0, 0.0, 0.0], 'LineWidth', 1.5);
    yline(12.0, ':k', 'Target = 12.0V', 'LineWidth', 1.1);
    grid on; box on;
    xlim([0, 120]); ylim([10.0, 14.0]);
    title('\textbf{Panel 3: Stable Regulated Output Voltage $v_o(t)$ under Full 1.20\,A Load ($R_L = 10.0\,\Omega$)}', ...
          'Interpreter', 'latex', 'FontSize', 11);
    ylabel('$v_o(t)$ [V]', 'Interpreter', 'latex', 'FontSize', 10);

    % Subplot 4: High-Frequency Residual Error & Ripple Zoom
    subplot(4, 1, 4);
    delta_vo_mv = (vout_eval - 12.0) * 1000;
    plot(t_eval * 1000, delta_vo_mv, 'Color', [0.15, 0.15, 0.15], 'LineWidth', 1.2);
    grid on; box on;
    xlim([20, 120]);
    title('\textbf{Panel 4: Residual Output Perturbation $\Delta v_o(t) = v_o(t) - 12\,\mathrm{V}$ (Zoomed at mV scale)}', ...
          'Interpreter', 'latex', 'FontSize', 11);
    xlabel('Time [ms]', 'Interpreter', 'latex', 'FontSize', 10);
    ylabel('$\Delta v_o$ [mV]', 'Interpreter', 'latex', 'FontSize', 10);

    % Export high-resolution PNG artifact
    [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
    out_png = fullfile(this_dir, 'stress_testbench_response.png');
    exportgraphics(fig, out_png, 'Resolution', 300);
    fprintf('Saved high-resolution diagnostic plot: %s\n', out_png);
end
