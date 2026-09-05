# GOAL.md

## 1. META PRINCIPAL (OVERALL GOAL)
**Objetivo Estratégico:** Sintetizar, enrutar, documentar y validar matemáticamente una topología electrónica de grado industrial para un circuito transformador/regulador lineal end-to-end. El diseño debe ser absolutamente agnóstico a los valores de tensión (escalable de 120V a 12V o de 1200V a 1.2V), utilizando simbología ortonormal paramétrica bajo el estándar IEEE. La entrega final será un dossier técnico modular en LaTeX compilado vía LuaLaTeX, acompañado de esquemáticos renderizados con precisión nanométrica en `circuitikz` y simulaciones emuladas verificables en SPICE/MATLAB.

## 2. CRITERIOS DE ÉXITO (VERIFIABLE END STATE)
El proyecto se considerará "DONE" única y exclusivamente cuando el Auditor Agente apruebe con un flag `[PASS]` las siguientes métricas:
- **Métrica 1 (Fase 0 - Base de Conocimiento):** Existencia verificable del directorio `KnowledgeBase` poblado con al menos 5 manuales de referencia técnica (TikZ, Circuitikz, PGFPlots, modelos de transformadores y directrices de SPICE) extraídos del almacenamiento local o de la web.
- **Métrica 2 (Precisión Topológica):** 100% de las rutas de circuito generadas en `circuitikz` respetan la regla de ortogonalidad absoluta (rutas `|-` o `-|`). Cero colisiones con los núcleos magnéticos o semiconductores. Todos los empalmes tienen nodos explícitos definidos.
- **Métrica 3 (Agnosticismo Paramétrico):** Ningún componente de hardware en el código fuente de los esquemáticos posee valores absolutos de voltaje, capacitancia o resistencia quemados en el código gráfico. Se utiliza álgebra simbólica.
- **Métrica 4 (Validación de Simulación):** Generación de al menos un archivo `.m` (MATLAB Simscape) o un netlist `.cir` (SPICE) que represente el modelo matemático exacto del circuito dibujado, capaz de compilar y ejecutarse sin errores sintácticos.
- **Métrica 5 (Arquitectura de Documento):** El dossier maestro compila correctamente en LuaLaTeX integrando múltiples subdirectorios (`/chapters`, `/figures/tikz` como `standalone`, `/attachments`), sin desbordamientos de memoria (*overfull/underfull* < 5%).

## 3. RESTRICCIONES RÍGIDAS (HARD CONSTRAINTS)
- **Aislamiento de Sistema de Archivos:** Lectura global habilitada para búsqueda de conocimiento empírico en el ordenador anfitrión. **ESCRITURA, MODIFICACIÓN, MOVIMIENTO O BORRADO EXCLUSIVAMENTE RESTRINGIDO AL ENTORNO DE SANDBOX:** `.`. Flag `[FAIL]` inmediato y terminación si se detecta un intento de escritura fuera de esta ruta.
- **Normativa de Código Electrónico:** Uso exclusivo del estándar IEEE (`logic ports=ieee`). Las capas de instrumentación analítica (osciloscopios) deben renderizarse estrictamente en la capa `background` del motor PGF.
- **Flujo Atómico por Capítulo:** Cada subcapítulo debe ejecutarse secuencialmente bajo el ciclo: `Investigación -> Documentación -> Ejecución TikZ -> Generación de Código -> Revisión del Código`.
- **Integridad Topológica:** Prohibidas las alucinaciones de componentes físicos. Toda unión debe ser demostrable eléctrica y lógicamente.

## 4. CONDICIONES DE PARADA Y PIVOTE (STOP & PIVOT CONDITIONS)
- **Stop (Success):** Todos los artefactos generados, y el Agente Auditor ha emitido el flag `[FINAL_PASS]`.
- **Pivot (Recovery):** Si la compilación de LuaLaTeX devuelve un "Fatal Error" o "Capacity Exceeded", el Agente Ejecutor debe detener la generación de nuevos nodos, aplicar `\usetikzlibrary{external}` para modularizar el gráfico problemático, y limpiar los archivos auxiliares antes de reintentar. Si el error persiste tras 3 intentos, elevar flag al Orchestrator para intervención humana.