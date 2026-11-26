# Plan: Guía de páramo offline

## Objetivo
Crear una app móvil en español que funcione sin internet en una zona de páramo acotada. El MVP debe mostrar un mapa descargado, la ubicación aproximada del excursionista y contenido ambiental revisado. No debe presentarse como servicio meteorológico ni de emergencias.

## Estado del proyecto
No encontré un repositorio existente para esta guía en el equipo local; planteo el trabajo como proyecto greenfield.

## Arquitectura recomendada
- **App:** React Native + Expo + TypeScript.
- **Cliente de desarrollo:** Expo development build (no Expo Go para la versión con mapas nativos). MapLibre React Native requiere configuración nativa y reconstruir el cliente.
- **Mapa:** MapLibre con un paquete offline pequeño y delimitado, descargable antes de la salida. Elegir proveedor/dataset con permiso explícito para uso offline; incluir atribución, tamaño, versión y fecha.
- **Ubicación y sensores:** Expo Location para ubicación en primer plano y rumbo; Expo Sensors solo si hace falta acceso directo a brújula/orientación. GPS funciona sin internet, pero precisión y primer fix varían según teléfono y terreno.
- **Datos guía:** paquete local versionado (JSON al inicio; SQLite si el volumen/búsqueda lo requiere) con fichas revisadas de flora, fauna, lugares, rutas, refugios, fuentes y fecha de verificación. Búsqueda local, no respuestas generativas sin fundamento.
- **Red cercana:** fuera del MVP. Evaluar como experimento optativo: Nearby Connections es una ruta basada en Google Play Services para Android; Apple Multipeer Connectivity es una ruta nativa Apple. No asumir una red interoperable/mallada entre móviles Android e iPhone sin prototipo. Si se requiere malla real en montaña, evaluar hardware LoRa compatible con Meshtastic como accesorio; el móvil por sí solo no incorpora radio LoRa.

## Alcance

### MVP
1. Pantalla de selección/estado del paquete offline para una sola zona.
2. Mapa disponible sin conexión, con GPS, marcador de posición y precisión/antigüedad del fix visibles.
3. Puntos cercanos con curiosidades del lugar y fichas locales de fauna y flora.
4. Preguntas frecuentes respondidas mediante contenido curado y buscable localmente, con fuente; indicar cuando no hay una respuesta verificada.
5. Registro manual de evento climático (p. ej., lluvia fuerte) y consulta de refugios verificados disponibles en el paquete local.
6. Recomendaciones prudentes y límites explícitos; sin localización en segundo plano ni difusión automática.

### Ideas para después o como demo secundaria
- Brújula visual, opcional, con calibración/indicador de rumbo.
- Distancia y ETA solo sobre una red de senderos confiable; sin rutas verificadas, mostrar distancia aproximada en línea recta y no llamarla tiempo de caminata.
- Reproducción de audio de las fichas como mejora de accesibilidad, manteniendo texto como modo principal.
- Reporte SOS/ubicación por conexión directa cercana, con aceptación explícita, indicador de destinatarios y prueba por plataforma.
- Intercambio/retransmisión de mensajes por varios dispositivos o LoRa/Meshtastic solo tras una prueba separada de alcance, compatibilidad, seguridad y batería.

## Clima y seguridad
- Sin conectividad ni pronóstico descargado reciente, la app no puede conocer el clima actual. Puede permitir ingresar el evento observado por la persona y explicar acciones generales previamente revisadas.
- Las recomendaciones de refugio solo pueden venir de ubicaciones verificadas, con acceso/condiciones y fecha de revisión. No inferir ni inventar una zona segura; si no hay datos suficientes, decirlo y recomendar seguir protocolos oficiales/emergencias.
- Cualquier ETA depende de senderos, desnivel y método de cálculo validados; no prometer tiempos de seguridad.
- Mostrar la incertidumbre GPS y aclarar que el mapa/guía es orientativo, no un sistema de rescate.
- Solicitar ubicación para funciones que la necesiten; nunca compartirla automáticamente. Mensajes/SOS optativos deben explicar exactamente quién los recibe y qué datos se transmiten.

## Fases de implementación
1. **Definir datos y zona:** elegir páramo/ruta piloto, proveedor de mapa con licencia adecuada, fuentes ambientales y autoridades/refugios verificables; acordar tamaño del área y alcance de demostración.
2. **Spike técnico de mapa offline:** crear el development build mínimo con MapLibre; descargar un área pequeña, cerrar/reabrir en modo avión y verificar render, almacenamiento, atribución y recuperación ante descarga incompleta. Resolver compatibilidad de versiones antes de avanzar.
3. **Modelo local de contenido:** definir esquema versionado para POI, especies, refugios, senderos, fuentes y fecha de revisión; añadir consultas por proximidad y búsqueda local.
4. **MVP móvil:** implementar navegación, estado del paquete, mapa, permisos, ubicación en primer plano, panel de curiosidades y fauna/flora, y FAQ sin conexión.
5. **Evento climático:** agregar ingreso manual del evento y recomendaciones generales validadas; mostrar refugios cercanos solo desde los datos comprobados. No conectar clima online como requisito del modo offline.
6. **Revisión y demostración:** probar con teléfonos Android y iPhone reales; demostrar el flujo en modo avión y presentar fuentes, fecha de datos y límites del sistema.
7. **Spike opcional de comunicación:** prototipo opt-in con dos dispositivos Android/iPhone disponibles. Medir descubrimiento, emparejamiento, mensajes/ubicación, desconexiones y permisos por plataforma. No incorporar como característica anunciada del MVP hasta comprobar soporte real; mantener opción LoRa/Meshtastic como hardware adicional.

## Verificación
- Instalar y ejecutar en dispositivos físicos de ambas plataformas con development build.
- Descargar la región con conectividad; activar modo avión; reiniciar la app y confirmar que mapa, POI, fichas y FAQ siguen disponibles.
- Probar GPS con permisos concedidos/denegados, precisión pobre, fix antiguo y ubicación desactivada; la UI debe comunicar claramente el estado.
- Confirmar que los POI cercanos se ordenan a partir de coordenadas y no requieren red.
- Simular evento climático sin red; verificar que solo se ofrecen recomendaciones y refugios incluidos en datos revisados, y que la app no presenta pronóstico actual ni seguridad garantizada.
- Probar descarga interrumpida, almacenamiento insuficiente, paquete de mapa/contenido ausente o desactualizado y fuentes/atribución visibles.
- Probar la comunicación opcional por separado en combinaciones reales de iOS/Android, con consentimiento, autenticación de pares, datos mínimos y sin asumir retransmisión mesh.

## Decisiones que necesito antes de implementar
- Zona/páramo piloto y teléfonos concretos disponibles.
- Fuente de mapas/datos con derechos adecuados para descarga offline.
- Fuentes verificables para especies, senderos y refugios; responsables de revisar/actualizar esos datos.
- Si la primera demo necesita ETA por sendero o basta con posición, distancia orientativa y puntos de interés.
