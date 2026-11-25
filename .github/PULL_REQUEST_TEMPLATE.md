## Descripción del Cambio
<!-- Proporciona un resumen conciso de los cambios incluidos en este PR -->

## Tipo de Contribución
- [ ] Corrección de error / bug fix en esquemático o cálculo
- [ ] Mejora en ruteo ortogonal 90° o aislamiento de componentes CircuiTikZ
- [ ] Actualización de documentación LaTeX o referencias técnicas IEEE
- [ ] Mejora en simulación / gemelo digital MATLAB (Simscape) o SPICE
- [ ] Infraestructura / gobernanza / CI

## Lista de Verificación de Calidad
- [ ] Cumplimiento estricto de **ortogonalidad 90°** en trazas CircuiTikZ (sin diagonales indebidas).
- [ ] Aislamiento de nodos y símbolos sin solapamiento de etiquetas.
- [ ] Uso correcto de capas `\begin{pgfonlayer}{background}` para cableado y fondos.
- [ ] Simbología conforme a **IEEE Std 315 / ANSI Y32.2** (resistores americanos, etc.).
- [ ] Cabeceras SPDX añadidas en las dos primeras líneas de nuevos archivos:
  `% SPDX-License-Identifier: CERN-OHL-S-2.0`
  `% Copyright (C) 2024-2026 Alonso Alvarado Hernández <alonsoalvaradohr>`
- [ ] Ausencia absoluta de rutas locales privadas (`C:\`, `E:\`).
- [ ] Compilación limpia con `lualatex` (o ejecución libre de errores en MATLAB).
