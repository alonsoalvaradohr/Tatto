# Objetivo: regulador lineal discreto

## Resultado exigido

Producir un conjunto de láminas LaTeX/CircuitikZ que describa una fuente lineal
regulada, enteramente discreta, sin circuitos integrados. La entrega final será
un PDF vectorial sin solapamientos, cruces ambiguos, texto descriptivo, cajas
funcionales ni trazados no ortogonales.

Cada archivo será compilable de forma independiente. Las interconexiones entre
láminas se realizarán exclusivamente mediante etiquetas de red.

## Restricción visual

Texto permitido únicamente:

`VAC`, `VAC1`, `VAC2`, `VRAW`, `VOUT`, `GND`, `REF`, `FB`,
`N2`, `VAS`, `DRV`, `SENSE`, `TAIL`, `T1`, `D1...D6`, `DZ`,
`Q1...Q9`, `R1...RSC`, `C1`, `CC`, `I1`, `CH1...CH5`.

Todo conductor será horizontal o vertical. Los cruces de redes están
prohibidos. Las uniones de tres o más ramas llevarán punto sólido. Los nodos
internos como `M1` se pueden usar en la netlist, pero nunca se muestran como
texto en una lámina.

## Contrato de osciloscopios

| Canal | Nodo | Forma exigida |
|---|---|---|
| `CH1` | `VAC` | seno completo |
| `CH2` | `VAC1` | seno completo aislado |
| `CH3` | `VRAW` antes de `C1` | seno rectificado de onda completa, sin tramo negativo |
| `CH4` | `VRAW` después de `C1` | descarga exponencial entre recargas, no sierra triangular |
| `CH5` | `VOUT` | nivel DC plano |

La relación canal--nodo se indicará solo mediante `CHn` y la etiqueta de red
permitida. No se dibujarán marcos de osciloscopio, grillas ni textos
descriptivos.

## Netlist contractual

### A. Entrada, aislamiento, rectificación y depósito

| Elemento | Terminales / nodos |
|---|---|
| `VAC` | primario de `T1` |
| `T1` secundario | `VAC1`, `VAC2`; aislado del primario |
| `D1` | ánodo `VAC1`, cátodo `VRAW` |
| `D2` | ánodo `VAC2`, cátodo `VRAW` |
| `D3` | ánodo `GND`, cátodo `VAC1` |
| `D4` | ánodo `GND`, cátodo `VAC2` |
| `C1` | `VRAW` a `GND` |

No se permite ninguna otra conexión a `VAC1` o `VAC2`. Esta tabla define
un puente rectificador completo positivo: los terminales AC nunca se unen entre
sí ni directamente a `VRAW` o `GND`.

### B. Referencia y amplificador de error

| Elemento | Terminales / nodos |
|---|---|
| `R3` | `VRAW` a `REF` |
| `DZ` | cátodo `REF`, ánodo `GND` |
| `Q1` NPN | base `REF`; emisor `TAIL`; colector `M1` |
| `Q2` NPN | base `FB`; emisor `TAIL`; colector `N2` |
| `I1` | `TAIL` a `GND` |
| `Q3` PNP | emisor `VRAW`; base y colector `M1` |
| `Q4` PNP | emisor `VRAW`; base `M1`; colector `N2` |

### C. VAS, compensación, driver y paso

| Elemento | Terminales / nodos |
|---|---|
| `Q5` NPN | base `N2`; emisor a `GND` mediante `R5`; colector `VAS` |
| `R4` | `VRAW` a `VAS` |
| `CC` | `VAS` a `N2` |
| `D5,D6` | cadena de sesgo entre `VAS` y bases de driver |
| `Q6` PNP | emisor `VRAW`; colector `DRV` |
| `Q7` NPN | emisor `GND`; colector `DRV` |
| `Q8` NPN | colector `VRAW`; base `DRV`; emisor `SENSE` |
| `RSC` | `SENSE` a `VOUT` |
| `Q9` NPN | base `SENSE`; emisor `VOUT`; colector `DRV` |

### D. Realimentación

| Elemento | Terminales / nodos |
|---|---|
| `R1` | `VOUT` a `FB` |
| `R2` | `FB` a `GND` |

## Láminas previstas

1. `01_scopes.tex`: cinco gráficos independientes de osciloscopio.
2. `02_transformer_bridge.tex`: `VAC`, `T1`, `D1...D4`, `C1`.
3. `03_reference_error.tex`: `R3`, `DZ`, `Q1...Q4`, `I1`.
4. `04_vas_driver.tex`: `Q5...Q7`, `R4`, `R5`, `CC`, `D5`, `D6`.
5. `05_pass_feedback.tex`: `Q8`, `Q9`, `RSC`, `R1`, `R2`.
6. `06_assembly.tex`: composición de PDFs aprobados, sin redibujar ni
   compactar las etapas.

No se crea el siguiente archivo hasta que el anterior tenga aprobación de
topología y geometría.
