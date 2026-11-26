# Estado del proyecto

> Copia traída del proyecto previo. Las rutas `app_flutter/` y `docs/` corresponden a esa estructura anterior; en este repositorio ver el `README.md`.

Última actualización: 2026-11-26

## Actualización del 2026-11-26
- **Usuario:** la aplicación la usa solo el guía; no se distribuye a los visitantes. Falta confirmar con la organización que esto cumple el reto, que habla de orientar a cada visitante.
- Plataforma confirmada (2026-11-26): solo teléfono, sin internet y con recursos limitados. Se descartan Raspberry Pi y Arduino.
- **Pase de recorrido:** QR firmado con vencimiento (12 minutos por ahora, para pruebas). Sin pase solo abren Emergencias y Mi ubicación. Probado con pruebas automáticas; falta probar el escaneo en un teléfono.
- **Instalación:** sin tiendas. El computador de la estación reparte APK y modelo por red local; el QR del pase activa la app y descarga el modelo. Probado con pruebas automáticas; falta el flujo real con teléfono.
- **Reto UTON:** funcionar sin conexión, responder solo con los dos guiones citando guion y página, abstenerse cuando no haya respaldo, permitir actualizar fichas sin tocar código y ser viable en energía. Entregables: prototipo, código, ficha de una página y pitch de 3 minutos.
- **Falta crítica:** en `lib/features/chat/chat_controller.dart`, cuando no hay ficha, el modelo responde sin texto de apoyo.
- **Contenido:** las fichas siguen siendo de demostración; no hay contenido de los guiones.
- Las secciones siguientes describen la versión anterior (`app_flutter/`). Este repositorio usa `flutter_edge_ai` con Gemma 3 1B y no incluye la voz.

## Fase actual
App migrada a Flutter (`app_flutter/`) con mapa 3D offline del sector Nevado del Ruiz integrado. Versión de demostración: el contenido y el mapa no están verificados.

## Decisiones tomadas
- **Usuario (2026-11-26):** solo el guía.
- Plataforma: solo Android en esta etapa. iOS queda para después del MVP.
- **Framework: Flutter** (decidido el 2026-11-25). La app en Expo (`app/`) queda solo como referencia y no se sigue desarrollando.
- Plazo: llegar con avance visible el jueves 2026-11-26.
- Equipo de 3 personas; el reparto de tareas se define más adelante.
- Zona piloto del mapa: sector Nevado del Ruiz (oeste -75,45; sur 4,75; este -75,20; norte 5,10).
- Mapa: visor propio con MapLibre GL JS dentro de una vista web, servido desde el teléfono (`127.0.0.1`). Se eligió en vez del plugin nativo de MapLibre para Flutter porque el relieve 3D del plugin en Android no estaba confirmado.
- Mapa: estilo ilustrado (franjas de color por altitud, iconos dibujados) aprobado el 2026-11-25.
- Mapa: relieve 3D y mapa plano a elección; en modo ahorro abre en plano. Fuera de la zona delimitada no se muestra nada.
- Nombre de paquete Android: `co.edu.paramo.asistente`.

## Hecho
- Plan previo del equipo revisado (`guia-paramo-offline.md`).
- Configuración de Claude creada: CLAUDE.md, skills, subagentes y hooks (probados).
- **App Flutter** en `app_flutter/` (Flutter 3.50.1). Ver `app_flutter/README.md`.
  - Portado todo lo de la versión Expo: 5 secciones (Inicio, Mapa, Asistente, Fichas, Emergencia), botón EMERGENCIA en el encabezado, buscador local, asistente con guardias de seguridad, texto grande, GPS bajo demanda, modo ahorro con aviso global, controles de 48 px.
  - 60 pruebas pasan y `flutter analyze` sin observaciones (2026-11-25, tras ampliar las reglas de emergencia).
  - Revisada en el navegador: Inicio, Mapa 3D, Asistente y Emergencia.
  - Prueba del modelo de IA movida a Inicio > Herramientas de desarrollo (solo Android), con `llamadart`.
- **Mapa** en `maps/`: datos de OpenStreetMap (Geofabrik), límite del parque (WDPA), relieve Copernicus DEM GLO-30, imagen Sentinel-2 cloudless 2016 y mapa de amenaza volcánica del SGC (2015) para consulta. Generador `maps/scripts/generar_mapa.py` y visor `maps/visor/index.html`. El origen y la licencia de cada fuente están en el `ORIGEN.md` de su carpeta.
- Contenido: 9 fichas de **demostración sin verificar** (`app_flutter/assets/datos/fichas.demo.json`). Las fuentes están marcadas como PENDIENTE.

## Qué falta para que sea utilizable
- Contenido real con fuente y revisión (esto manda sobre todo lo demás).
- Contactos oficiales de emergencia.
- Verificar senderos y refugios del mapa: hoy salen de OpenStreetMap sin revisar, incluidas rutas de cumbre.
- Recorrer el resto de la app en el celular (ya instalada; falta probar pantallas, GPS, batería, modo avión y modelo).

## Pendientes
Ver `docs/PENDIENTES.md`.

## Notas
- Prueba en celular real (2026-11-25): APK release instalado por USB en un Samsung Galaxy A15 (SM-A155M, 6 GB de RAM, Android 16). La app abre y el mapa 3D carga en la vista web. Memoria observada con el mapa abierto: unos 450 MB (PSS) del proceso de la app, más el proceso de la vista web (unos 390 MB RSS). **Sin probar**: demás pantallas, GPS, batería, modo avión y modelo.
- Entorno instalado: Flutter en `~/herramientas/flutter` (no está en el `PATH` del sistema); herramientas de mapas en `~/herramientas/mapas-venv`.
- Los ajustes (tamaño de texto, modo ahorro manual) se pierden al cerrar la app.
- En Flutter 3.50, Material se importa desde `package:material_ui/material_ui.dart`; `package:flutter/material.dart` está obsoleto.
