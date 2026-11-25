# Guía de Contribución al Proyecto Tatto

¡Gracias por tu interés en contribuir a **Proyecto Tatto: Arquitectura Unificada de Fuente Lineal**!

Este proyecto es hardware abierto bajo la licencia **CERN Open Hardware Licence Version 2 - Strongly Reciprocal (CERN-OHL-S-2.0)**. Para preservar la calidad editorial, rigor técnico y uniformidad visual de los esquemáticos y gemelos digitales, todas las contribuciones deben cumplir estrictamente con los lineamientos aquí descritos.

---

## 1. Normas Técnicas de Esquemáticos (CircuiTikZ y PGF/TikZ)

Todo diagrama esquemático en `figures/tikz/` y los capítulos de LaTeX debe respetar:

1. **Ortogonalidad Estricta a 90°:**
   - Todo ruteo de señales, buses, tierra y rieles de alimentación debe ser rigurosamente Manhattan (horizontal y vertical en ángulos rectos de 90°).
   - Quedan prohibidas las trazas diagonales o en ángulos arbitrarios, salvo que representen físicamente una conexión coaxial o componente angular estándar.
   - Las conexiones entre nodos deben usar la sintaxis `|-` o `-|` asegurando esquinas ortogonales limpias.

2. **Aislamiento y Separación de Símbolos:**
   - Ningún símbolo de componente (resistencias, transistores BJT, diodos, capacitores, fuentes) debe superponerse o solaparse con nodos de unión o etiquetas de texto.
   - Mantener distancias libres mínimas parametrizadas (`\coord...`) entre bloques funcionales (Transformador, Puente Rectificador, Etapa VAS, Elemento de Paso, Amplificador de Error).
   - Todos los cruces de líneas sin conexión eléctrica deben diferenciarse nítidamente de las uniones de nodo (`node[circ]{}`).

3. **Arquitectura de Capas (`\begin{pgfonlayer}{background}`):**
   - El cableado, buses de interconexión y fondos visuales deben aislarse en capas dedicadas de PGF/TikZ:
     - `background`: líneas de conexión, cajas de agrupación funcional y buses de retorno.
     - `main`: componentes electrónicos, símbolos y puertos.
     - `foreground`: etiquetas semánticas, anotaciones de medición y oscilogramas.
   - Todo uso de capas de fondo debe encapsularse explícitamente dentro de entornos `\begin{pgfonlayer}{background} ... \end{pgfonlayer}`.

4. **Normativa IEEE Americana:**
   - Cumplimiento de **IEEE Std 315 / ANSI Y32.2** para simbología de componentes electrónicos (resistencias en zigzag `resistors=american`, inductores americanos, fuentes de corriente/voltaje estilo IEEE).
   - Polaridades, flechas de polarización en semiconductores (BJT npn/pnp) y símbolos de tierra de chasis/analógica según las directrices vigentes en `preamble/circuitikz_styles.tex`.

---

## 2. Modelado Matemático y Gemelos Digitales (MATLAB / SPICE)

- Los scripts en `simulations/matlab/` (`simscape_*.m`, `stress_testbench.m`) y los netlists en `simulations/spice/` deben mantener coherencia paramétrica 1:1 con los valores etiquetados en los esquemáticos LaTeX.
- Todo script de simulación debe ser determinista, libre de rutas absolutas locales (`C:\`, `E:\`) y utilizar rutas relativas referenciadas a la raíz del repositorio.

---

## 3. Autoría y Licenciamiento SPDX

Todo archivo nuevo de código (`.tex`, `.m`, `.cir`, scripts) debe incluir en sus dos primeras líneas la cabecera oficial de licencia y copyright:

```latex
% SPDX-License-Identifier: CERN-OHL-S-2.0
% Copyright (C) 2024-2026 Alonso Alvarado Hernández <alonsoalvaradohr>
```

---

## 4. Flujo de Trabajo y Pull Requests

1. Haz un fork del repositorio y crea una rama descriptiva para tu cambio (`feat/nueva-etapa`, `fix/esquematico-ortogonal`).
2. Verifica que el documento compile limpiamente con `lualatex` sin warnings de solapamiento y que los scripts de MATLAB ejecuten sin errores.
3. Asegúrate de no introducir rutas privadas locales ni archivos temporales (`.aux`, `.log`, `.synctex.gz`).
4. Abre un Pull Request completando la plantilla `.github/PULL_REQUEST_TEMPLATE.md`.
