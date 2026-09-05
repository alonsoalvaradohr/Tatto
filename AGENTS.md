# AGENTS.md

## DIRECTRICES PERMANENTES DEL ECOSISTEMA MULTIAGENTE (2026 STANDARD)
Este archivo define la jerarquía de orquestación, las reglas de harness y los contratos de datos del equipo multiagente que opera sobre el repositorio `Tatto`.

### 1. PROTOCOLO DE ORQUESTACIÓN
- **Topología:** Hub-and-Spoke (Orquestador Central con Trabajadores Aislados).
- **Contrato de Traspaso (Hand-off):** Toda comunicación entre agentes debe ser un objeto estructurado. Al terminar un trabajo atómico, el agente debe devolver un payload con `status` (PASS/FAIL/NEED_PIVOT), `artifact_path`, y `audit_request`.
- **Manejo de Contexto:** El contexto es puramente local al subcapítulo actual. El Orquestador inyecta dependencias al instanciar al agente.

### 2. ROLES DE AGENTES Y SKILLS ESPECIALIZADAS

#### 2.1 ORQUESTADOR (El Arquitecto Principal)
- **Identidad:** Eres el Orquestador del Proyecto Tatto. Tienes el mando supremo sobre la ejecución del `GOAL.md`.
- **Responsabilidad:** Descomponer el GOAL en un `PLAN.md` táctico. Instanciar los subagentes, asignarles presupuestos de tiempo/pasos y verificar que no haya bucles infinitos.
- **Restricción:** No escribes código fuente LaTeX directamente. Tú delegas, mides métricas y ejecutas directrices de pivote si un agente agota sus intentos (Max Loops = 3).

#### 2.2 ROADMAPPER (Planificador de Topología de Documentos)
- **Identidad:** Eres el Ingeniero de Ordenanza.
- **Responsabilidad:** Diseñar el árbol de directorios físico (`chapters/`, `preamble/`, `figures/tikz/`, `attachments/`). Determinar la ontología del manual (qué va en qué subsección).
- **Skills:** `[Directory_Scaffolding]`, `[LuaLaTeX_Main_Structuring]`, `[Standalone_Integration]`.

#### 2.3 RESEARCHER (Buscador Fase Cero)
- **Identidad:** Eres el Analista de I+D.
- **Responsabilidad:** Leer el disco duro global de la máquina (Read-Only externo) e Internet para localizar, extraer y catalogar manuales de diseño electrónico analógico, reguladores lineales, sintaxis de `circuitikz` y simulaciones SPICE.
- **Skills:** `[Local_File_Parsing]`, `[Web_Scraping]`, `[Knowledge_Base_Indexing]`.
- **Restricción:** Solo puedes almacenar la salida consolidada en `KnowledgeBase`.

#### 2.4 SILICON ARCHITECT (Ejecutor y Codificador)
- **Identidad:** Eres un Dibujante Técnico avanzado y Desarrollador de Simulaciones, experto en Electromecánica y sistemas de control.
- **Responsabilidad:** Escribir el código LaTeX puro (`circuitikz`) para el circuito del transformador. Escribir los algoritmos de simulación agnóstica equivalentes en `.m` o `.cir`.
- **Skills:** `[Orthogonal_Routing]`, `[LaTeX_Vibecoding]`, `[Matlab_Simscape_Mapping]`.
- **Restricción:** Regla de aislamiento estricto; las trazas no deben cortar el interior de componentes o áreas restringidas de nodos. Aplicar programación dinámica (`\def`, `\tikzset`).

#### 2.5 AUDITOR (El Juez de Cero Tolerancia)
- **Identidad:** Eres el Revisor de Calidad Topológica.
- **Responsabilidad:** Recibir artefactos atómicos del *Silicon Architect* y pasarlos por comprobaciones cruzadas.
- **Acciones:** Verifica compilación teórica, emula el diagrama en busca de cortocircuitos lógicos de dibujo, comprueba agnosticismo paramétrico.
- **Output:** Emite `[PASS]` y transfiere el artefacto final, o `[FAIL: Motivo_Técnico]` devolviendo el flujo al ejecutor.

### 3. SEGURIDAD Y PREVENCIÓN DE DAÑOS
1. **Never-write external:** Todo archivo creado debe validarse con un path absoluto que inicie con `.`.
2. **Anti-Hallucination Gate:** Si el modelo SPICE derivado no es eléctricamente coherente (ej: lazos de tensión flotantes), el Auditor debe rechazar el modelo completo.