***

# 📘 PROYECTO TATTO: Arquitectura Unificada de Fuente Lineal (LaTeX / CircuiTikZ)
**DOCUMENTO MAESTRO DE INSTRUCCIONES Y ROADMAP PARA IA**

## 🎯 1. OBJETIVO PRINCIPAL (El "Qué")
El objetivo del Proyecto Tatto es renderizar un único esquemático electrónico en LaTeX utilizando la librería `circuitikz` que represente una **Fuente de Alimentación Lineal**. 

El diferenciador absoluto de este proyecto es su **profundidad de abstracción anidada (Zoom-In Topológico)** y su **análisis de señal integrado**. El circuito no es una colección de "cajas negras", sino un diagrama continuo en un solo plano que fusiona tres niveles jerárquicos:
1.  **Nivel Macro:** Circuito de potencia (Transformador, Rectificador, Filtros).
2.  **Nivel Silicio (Regulador):** Desglose del regulador lineal (Transistor de paso, protección de sobrecorriente, divisor resistivo).
3.  **Nivel Transistor (Amplificador):** Desglose del Amplificador de Error dentro del regulador (Par diferencial, espejo de corriente, VAS, Push-Pull).
4.  **Capa Analítica:** Osciloscopios matemáticos reales superpuestos en el fondo (Background layer) mostrando la evolución temporal de la señal en nodos críticos.

## 🚧 2. ESTÁNDARES Y RESTRICCIONES NORMATIVAS (Obligatorio)
Actúas como un Arquitecto de Silicio Senior. No se permiten atajos visuales.
* **Normativa IEEE:** Uso estricto de convención americana (`american`, `logic ports=ieee`).
* **Ortogonalidad Estricta:** Las conexiones electrónicas *deben* viajar en ángulos de 90 grados (`|-` o `-|`). Queda terminantemente prohibido el trazado de líneas diagonales ("espagueti") entre componentes.
* **Aislamiento Físico de Símbolos:** Las líneas de enrutamiento jamás deben atravesar el interior del símbolo de un transistor (NPN/PNP) o núcleo de transformador. Deben rodearlos.
* **Identidad de Nodos:** Diferenciación visual impecable entre cruces de cables sin conexión y empalmes eléctricos reales (usando `*-*` o nodos circulares rellenos).
* **Superposición de Capas (Layers):** Los osciloscopios deben existir físicamente en las mismas coordenadas espaciales que el circuito, pero enviados al fondo usando `\begin{pgfonlayer}{background}`. Está prohibido "simular" el fondo enviándolos a coordenadas en `Y` aisladas.

## 🗺️ 3. ROADMAP Y MILESTONES (Hitos de Desarrollo)

### Hito 1: Preparación del Lienzo y Espacio de Trabajo (Grid)
* **Meta:** Definir una cuadrícula de coordenadas maestro (ej. `Vcc` interno en Y=Alto, `GND` en Y=Bajo) para garantizar que los 3 niveles coexistan sin chocar.
* **Resultado:** Plantilla `standalone` con carga limpia de librerías, orden correcto para evitar conflictos (ej. `xcolor` antes de `tikz`) y definición de estilos de fuente para etiquetas.

### Hito 2: Capa Analítica (El Sistema Oscope)
* **Meta:** Diseñar una macro `\oscope` robusta que trace funciones matemáticas puras (seno, valor absoluto, exponenciales de carga/descarga).
* **Resultado:** 5 pantallas distribuidas estratégicamente en el fondo que graficarán: 1) Red AC, 2) Secundario, 3) Rectificación completa, 4) Ripple/Rizado, 5) Salida DC.

### Hito 3: Enrutamiento del Nivel 1 (Potencia) y Nivel 2 (Regulación)
* **Meta:** Construir el esqueleto exterior e intermedio.
* **Resultado:** Un transformador conectado a un puente de diodos discreto. Rieles extendidos que alimentan al transistor de paso de potencia ($Q_{pass}$), integrando la resistencia de sensado ($R_{sc}$), la topología limitadora ($Q_{limit}$) y la referencia Zener de voltaje.

### Hito 4: Inserción Quirúrgica del Nivel 3 (Amplificador de Error)
* **Meta:** Diseñar la topología a nivel transistor y enrutarla al Nivel 2.
* **Resultado:** Par diferencial NPN alimentado por una fuente de cola, con carga activa de espejo PNP. Salida conectada a un transistor VAS (con capacitor de compensación Miller real), terminando en una etapa Push-Pull Clase AB polarizada con diodos. Todo conectado a la base de $Q_{pass}$ y al divisor de retroalimentación.

### Hito 5: Interconexión Sondas-Circuito (Test Probes)
* **Meta:** Conectar la pantalla de los osciloscopios (Hito 2) a los nodos físicos del circuito (Hitos 3 y 4).
* **Resultado:** Líneas punteadas ortogonales que bajan/suben desde los nodos eléctricos críticos hasta los instrumentos de medición en el fondo.

## ⚠️ 4. HISTORIAL DE ERRORES CRÍTICOS (Lecciones Aprendidas a Evitar)
La IA a cargo debe leer esto y ajustar su código preventivamente:
1.  **Fallo de Puntas de Flecha (Unknown arrow tip kind '*'):** En `circuitikz`, usar el modificador `*-` en un `\draw` simple de TikZ puro para simular una sonda causa error de compilación. **Solución obligatoria:** Separar el trazo de la sonda y el nodo visual. Dibujar la línea punteada pura (`--`) y explícitamente dibujar un `\fill` circular en la coordenada final.
2.  **Ruteo de Nodos con Coordenadas Dinámicas:** Trazar de nodo A a nodo B directamente `(A) -- (B)` a menudo corta a través de otros componentes. **Solución obligatoria:** Forzar cálculos de intersección matemática ortogonal (`(A) |- (B)`).
3.  **Polaridad de Capacitores Ambigua:** El capacitor estándar `pC` puede renderizarse de cabeza dependiendo de la dirección de trazado. **Solución obligatoria:** Usar componentes estrictos como `eC` y dibujarlos siempre de arriba hacia abajo (del riel positivo al negativo) para anclar el "+" arriba.

## 🚀 5. INSTRUCCIÓN DE EJECUCIÓN PARA LA IA
> "He leído y comprendido el **Proyecto Tatto**. Asumo mi rol como Arquitecto de Silicio. No generaré explicaciones teóricas innecesarias. Me tomaré el tiempo de computación que sea necesario (ciclos de razonamiento profundo) para visualizar la cuadrícula geométrica en mi espacio latente. Mi única salida será un bloque de código LaTeX impecable, estructurado por hitos, comentado y garantizado para compilar sin errores, cumpliendo estrictamente con la abstracción multinivel y las leyes de diseño ortogonal de la IEEE. Procede."