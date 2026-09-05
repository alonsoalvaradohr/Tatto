% =========================================================================
% Simscape_Regulador_FINAL_HANDLES.m
% Construye la fuente AC → DC regulada usando port handles (robusto)
% Compatible con MATLAB R2018b y superiores (Simscape Electrical)
% =========================================================================

clc; clear; close all;
modelName = 'Regulador_Serie_Final';

% Cerrar modelo si ya está abierto
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
new_system(modelName);
open_system(modelName);

% Configuración de simulación
set_param(modelName, 'SimulationMode', 'normal');
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'SolverName', 'ode23t');
set_param(modelName, 'StopTime', '0.2');  % 200 ms, suficiente para ver régimen

% Cargar librerías (con try/catch)
libs = {'fl_lib', 'ee_lib', 'nesl_utility'};
for k = 1:numel(libs)
    try
        load_system(libs{k});
    catch
        error('No se pudo cargar la librería "%s". Verifique la instalación de Simscape Electrical.', libs{k});
    end
end

% Rutas completas a los bloques
ac  = 'fl_lib/Electrical Sources/AC Voltage Source';
di  = 'fl_lib/Electrical Elements/Diode';
cap = 'fl_lib/Electrical Elements/Capacitor';
res = 'fl_lib/Electrical Elements/Resistor';
op  = 'fl_lib/Integrated Circuits/Op-Amp';
npn = 'ee_lib/Semiconductors/NPN Bipolar Transistor';
gnd = 'fl_lib/Electrical Elements/Electrical Reference';
solv= 'nesl_utility/Solver Configuration';
dc  = 'fl_lib/Electrical Sources/DC Voltage Source';

% Función para añadir bloque y devolver la ruta dentro del modelo
addB = @(src, name, pos, orient) add_block(src, [modelName '/' name], ...
            'Position', pos, 'Orientation', orient, 'ShowName', 'off');

% Insertar bloques (posiciones optimizadas para claridad)
addB(solv, 'Solver',     [30  30   90  90], 'right');
addB(gnd,  'GND_Main',   [30 180   90 240], 'up');
addB(ac,   'AC_Source',  [150 30  210 90], 'up');
addB(di,   'D1',         [300 10  360 70], 'down');
addB(di,   'D2',         [300 130 360 190], 'down');
addB(di,   'D3',         [460 10  520 70], 'down');
addB(di,   'D4',         [460 130 520 190], 'down');
addB(cap,  'C_Filter',   [600 60  660 120], 'down');
addB(dc,   'V_Ref',      [720 160 780 220], 'up');
addB(npn,  'NPN_Pass',   [900 40  960 100], 'right');
addB(op,   'ErrorAmp',   [900 160 960 220], 'right');
addB(res,  'R_F1',       [1080 30 1140 90], 'down');
addB(res,  'R_F2',       [1080 140 1140 200], 'down');
addB(gnd,  'GND_Out',    [1200 140 1260 200], 'up');
addB(res,  'R_Load',     [1020 250 1080 310], 'down');

% Ajustar parámetros esenciales
set_param([modelName '/V_Ref'], 'v0', '5.1');
set_param([modelName '/AC_Source'], 'V0', '12');   % 12 V amplitud
set_param([modelName '/AC_Source'], 'f', '60');    % 60 Hz
set_param([modelName '/R_F1'], 'R', '1e3');        % 1 kΩ
set_param([modelName '/R_F2'], 'R', '1e3');        % 1 kΩ (Vout ≈ 5.1*(R1+R2)/R2 = 10.2 V)
set_param([modelName '/R_Load'], 'R', '100');      % 100 Ω carga

% =========================================================================
% OBTENCIÓN DE PORT HANDLES (LConn = puertos de conservación físicos)
% =========================================================================
% Para cada bloque, extraemos los handles de los puertos de tipo 'LConn'.
% El orden en Simscape es fijo y documentado:
% - Resistor, Capacitor, Diode, AC/DC Voltage Source: [p, n]
% - Electrical Reference: [V]  (un solo puerto)
% - Solver Configuration: [f]   (un solo puerto)
% - NPN: [C, B, E]  (orden: colector, base, emisor)
% - Op-Amp: [+, -, out] (entrada no inversora, inversora, salida)
%
% NOTA: si alguna versión tuviera un orden distinto, se puede verificar
% inspeccionando 'PortConnectivity', pero la práctica muestra que el orden
% de LConn es estable en todas las release recientes.

function h = get_ports(blockPath)
    ph = get_param(blockPath, 'PortHandles');
    h = ph.LConn;   % vector de handles numéricos
end

% Obtener los handles de todos los bloques
hSolver   = get_ports([modelName '/Solver']);
hGND_Main = get_ports([modelName '/GND_Main']);
hAC       = get_ports([modelName '/AC_Source']);
hD1       = get_ports([modelName '/D1']);
hD2       = get_ports([modelName '/D2']);
hD3       = get_ports([modelName '/D3']);
hD4       = get_ports([modelName '/D4']);
hC        = get_ports([modelName '/C_Filter']);
hVRef     = get_ports([modelName '/V_Ref']);
hNPN      = get_ports([modelName '/NPN_Pass']);
hOpAmp    = get_ports([modelName '/ErrorAmp']);
hRF1      = get_ports([modelName '/R_F1']);
hRF2      = get_ports([modelName '/R_F2']);
hGND_Out  = get_ports([modelName '/GND_Out']);
hLoad     = get_ports([modelName '/R_Load']);

% =========================================================================
% CONSTRUCCIÓN DE CONEXIONES USANDO HANDLES (simscape.addConnection)
% =========================================================================
% La función acepta handles en lugar de strings de puerto.
con = @(h1, h2) simscape.addConnection(h1, h2, 'autorouting', 'on');

% 1. Solver a tierra (única referencia de simulación)
con(hSolver(1), hGND_Main(1));

% 2. Puente rectificador (4 diodos)
% AC + (p) → D1.anode(p) y D2.cathode(n)
con(hAC(1), hD1(1));      % p_AC → p_D1
con(hAC(1), hD2(2));      % p_AC → n_D2
% AC - (n) → D3.anode(p) y D4.cathode(n)
con(hAC(2), hD3(1));      % n_AC → p_D3
con(hAC(2), hD4(2));      % n_AC → n_D4
% Unión cátodos D1 y D3 → riel positivo
con(hD1(2), hD3(2));
% Unión ánodos D2 y D4 → riel negativo
con(hD2(1), hD4(1));

% 3. Rieles DC al filtro
con(hD1(2), hC(1));       % positivo al capacitor
con(hD2(1), hC(2));       % negativo al capacitor
con(hC(2), hGND_Main(1)); % negativo a tierra principal

% 4. Transistor de paso (colector al riel positivo)
con(hC(1), hNPN(1));      % C = primer puerto LConn

% 5. Referencia de voltaje (V_Ref) – negativa a tierra, positiva a Op-Amp
con(hC(2), hVRef(2));     % n (negativa) al riel negativo
con(hVRef(1), hOpAmp(1)); % p → entrada + del Op‑Amp

% 6. Lazo de control y realimentación
con(hOpAmp(3), hNPN(2));  % out Op‑Amp → base NPN (B = 2º puerto)
con(hNPN(3), hRF1(1));    % emisor (E = 3er puerto) → R_F1(p)
con(hRF1(2), hRF2(1));    % nudo de realimentación
con(hRF1(2), hOpAmp(2));  % realimentación a entrada - del Op‑Amp
con(hRF2(2), hGND_Out(1));% R_F2(n) → tierra

% 7. Carga
con(hNPN(3), hLoad(1));   % emisor → carga (p)
con(hLoad(2), hGND_Out(1));% retorno de carga a tierra

% 8. Unir las dos tierras (ya están conectadas a través del riel, pero así aseguramos un solo nodo si fuera necesario)
% Ambas tierras ya comparten el riel negativo, así que esta línea es redundante pero inofensiva.
% con(hGND_Main(1), hGND_Out(1));

% =========================================================================
% FINALIZACIÓN
% =========================================================================
set_param(modelName, 'ZoomFactor', 'FitSystem');
save_system(modelName);
disp(' ');
disp('===================================================');
disp(' MODELO CREADO EXITOSAMENTE CON PORT HANDLES ');
disp(' Puede simularlo con Run (botón verde) y añadir ');
disp(' sensores y scopes según necesite. ');
disp('===================================================');