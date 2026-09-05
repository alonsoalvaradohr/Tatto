# Rol de ejecución y auditoría

## Rol del agente de diseño

El agente actúa como ingeniero principal de diseño electrónico y delineante de
esquemáticos. Su responsabilidad es transformar el netlist contractual de
`GOAL.md` en una lámina por etapa, manteniendo las etiquetas de red y la
orientación de cada terminal.

No puede cambiar una conexión del netlist para facilitar el dibujo. Si una
ruta no cabe, se modifica la grilla o se divide la lámina.

## Rol del auditor

El auditor es independiente del dibujante. Su resultado solo puede ser
`PASS` o `FAIL`. Un `FAIL` impide continuar a la siguiente lámina.

### Auditoría eléctrica

1. Comparar cada pin de cada componente contra `GOAL.md`.
2. Confirmar orientaciones de diodos, Zener, NPN y PNP.
3. Recorrer los caminos:
   - `VAC1/VAC2 → D1...D4 → VRAW/GND`.
   - `VRAW → Q8 → RSC → VOUT`.
   - `VOUT → R1 → FB → Q2 → N2 → Q5 → DRV → Q8`.
   - `SENSE/VOUT → Q9 → DRV`.
4. Rechazar terminales flotantes, cortocircuitos y rutas paralelas no
   declaradas.

### Auditoría geométrica

1. Cada símbolo, etiqueta y ruta tiene una reserva rectangular invisible.
2. Dos reservas no conectadas no pueden intersecarse.
3. Cada cable se descompone en segmentos H/V.
4. Se permiten puntos negros únicamente en uniones reales.
5. Cero cruces entre redes, incluso si no llevan punto.
6. Sin cajas, leyendas, explicaciones ni texto fuera de la nomenclatura.
7. Compilar y revisar el PDF renderizado a 150 dpi: sin recortes, textos
   sobre cables, símbolos superpuestos ni advertencias de sobreflujo.

## Secuencia obligatoria por archivo

1. Declarar los nodos y pines esperados.
2. Fijar una grilla con coordenadas enteras.
3. Dibujar símbolos sin cables.
4. Reservar corredores de red.
5. Añadir rutas ortogonales.
6. Ejecutar auditoría eléctrica.
7. Compilar, renderizar y ejecutar auditoría geométrica.
8. Registrar `PASS` antes de avanzar.
