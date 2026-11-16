# Primer uso de Strøm en staging

Guía para recorrer el flujo completo sin escribir ids. Cada dato se elige por su nombre. La sucursal activa es la del encabezado `X-Branch-ID`.

Entra a Strøm desde el menú **Operaciones**. El escritorio abre en **Proyectos**.

## 1. Proyecto

1. Pulsa **Crear**.
2. Elige el tipo (Proyecto, Instalación, Soporte o Mantención).
3. Escribe el nombre. El código y la OC son opcionales.
4. Las fechas se eligen en el calendario.
5. En **Responsable**, busca a la persona y tócala. Si el listado de líderes aún no está publicado, la app usa el directorio de la sucursal. No pide un número.
6. El ticket y la cotización de origen se eligen por su número o asunto. Si el listado no responde, queda el aviso y puedes guardar el proyecto igual.
7. **Guardar**. Quedas en la ficha del proyecto.

## 2. Alcance

1. En la ficha, **Importar alcance**.
2. Elige el punto de captación por su nombre (Pozo 1, por ejemplo).
3. Escribe la actividad y deja la especialidad en Hidráulica.
4. Confirma. El ítem queda pendiente. La ficha titula el punto con su nombre (Pozo 1), no con un texto genérico.
5. Pulsa **Confirmar** en ese ítem. Pasa a confirmado.

Hasta que el backend publique `GET /projects/{id}/scope/`, la ficha muestra el alcance que acabas de importar. Cuando ese GET responde, el nombre del punto viene en `device_name`. No hace falta recargarlo a mano.

## 3. Instalación

1. Desde la ficha, **Instalaciones**.
2. **Crear**. Marca uno o más puntos de captación y cierra con **Listo**.
3. Nombre, código, ubicación y cliente (por el nombre del cliente).
4. Confirma. La tarjeta dice cuántos puntos tiene, no sus números.

## 4. Orden de trabajo

1. Vuelve al proyecto y entra a **OT**. El listado ya viene filtrado a ese proyecto.
2. **Sugerir** y confirma. Aparece **OT Hidráulica**, en estado sugerida.
3. Ábrela y **Confirmar**. La referencia comercial es opcional.
4. Desde la OT puedes ir a visitas, actividades y RTS sin volver a elegirla.

## 5. Visita planificada y cuadrilla

1. **Nueva visita**. La OT queda fija. La primera visita nace planificada.
2. Elige la fecha en el calendario para dejarla programada, o déjala vacía y queda propuesta.
3. **Crear visita**.
4. Si quedó propuesta, **Programar** y elige el día.
5. **Sumar cuadrilla** y elige el integrante por su nombre. Si no hay integrantes, la app pide el nombre para crear uno, no un id.

## 6. Actividades, check y evidencia

1. En la visita, **Actividades**.
2. **Materializar** y confirma. Nace la actividad del alcance.
3. **Check de terreno** (también desde la visita). La visita queda fija.
4. Elige la actividad, el resultado y una observación. **Registrar** no cierra el proyecto.
5. Pestaña **Evidencias**, **Agregar**. Describe la foto.
6. Abre la evidencia y **Vincular Drive**. Pega el enlace (`https://drive.google.com/file/d/...`). La app guarda el archivo de Drive; no copia el archivo.

## 7. RTS

1. Desde la OT, **RTS**.
2. **Crear**. La OT queda fija. Elige el producto por su nombre y la cantidad.
3. La bodega es opcional. Si no eliges, la reserva usa la bodega por defecto de la sucursal. Puedes elegir otra bodega de la sucursal por su nombre. La ficha muestra ese nombre cuando el JSON lo trae.
4. **Vincular OC**. Busca la orden por número o proveedor y tócala. Se ve el número y el proveedor. Si el listado aún responde 404, queda el aviso y no se pide un id. Si hay recepciones de esa orden, puedes elegir una; si el listado no existe, se vincula igual.
5. Abre la RTS. **Reservar**: la reserva descuenta una sola vez de la bodega de la sucursal.
6. **Dar salida** no vuelve a descontar. Una bodega de otra sucursal se rechaza.

## 8. Informe

1. Desde el proyecto, **Informes**.
2. **Generar**. El proyecto queda fijo. La especialidad nace en Hidráulica. También puedes dejarla en **Sin especialidad**. Nace en borrador.
3. Ábrelo. **Enviar a revisión**.
4. **Aprobar**. Con especialidad lo aprueba Operaciones o el líder de esa especialidad. Sin especialidad, Operaciones o cualquier líder. El botón sigue disponible: el backend rechaza a quien no corresponde.
5. **Enviar**.

## 9. Costos

1. **Costos**, con el proyecto o la OT ya elegidos si entraste desde su ficha.
2. **Costo del proyecto** suma las OT. **Costo de la OT** usa el costo diario de cuadrilla más reciente.
3. **Registrar** un costo diario pide monto, vigencia (calendario) y especialidad. El vigente es el de fecha más nueva.

## 10. Indicadores

1. **Indicadores**.
2. KPI-9 se muestra como rango de puntos de captación, no como un número suelto.
3. **Nueva meta**: indicador KPI-9, puntos mínimos, puntos máximos y días corridos.
4. En **Plan a informe**, elige el proyecto por su nombre para ver los días entre hitos.

## Qué no se escribe

No hay campos de id de proyecto, OT, visita, actividad, punto, producto, cliente, usuario, ticket, cotización, orden de compra, recepción ni bodega. Si un listado nuevo aún responde 404 o 405, el selector avisa y sigue vacío. No aparece un campo para tipear el número.
