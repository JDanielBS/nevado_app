# Manejo de la información y estrategia

Fecha: 2026-11-26. Estado: diseño acordado, **sin implementar**.

## 1. Resumen

- Habrá **dos aplicaciones**: la del **guía**, que edita toda la información, y la del **visitante**, que la lee y consulta con el chatbot.
- La información se guarda en **un archivo `.md` por sección**. Las fotos y videos van aparte.
- El contenido se publica en **Cloudflare R2**.
- El visitante descarga el contenido cuando tiene conexión (por ejemplo, con Starlink) y lo usa sin señal.
- La aplicación es propia de la visita: el contenido se elimina pasado cierto tiempo.
- Se mantiene Flutter en el celular. Un Arduino no puede ejecutar la aplicación ni el modelo. Una Raspberry Pi exigiría cambios.

## 2. Secciones iniciales

| Archivo | Sección | Contenido |
|---|---|---|
| `avisos.md` | Avisos vigentes | Cierres, volcán, estado de senderos, alertas de clima |
| `estaciones.md` | Estaciones | Brisas, Aguacerales, Arenales, Valle Lunar y Valle de las Tumbas |
| `emergencias.md` | Emergencias | Contactos, qué hacer, puestos de ayuda |
| `salud.md` | Salud y seguridad | Mal de altura, hipotermia, tormenta, ceniza, extravío, abrigo |
| `normas.md` | Normas y restricciones | Permitido, prohibido, residuos, horarios |
| `lugares.md` | Lugares y refugios | Puntos de interés, refugios, puestos de control |
| `naturaleza.md` | Naturaleza | Flora, fauna, ecosistemas |
| `geologia.md` | Geología, glaciares y clima | Volcán, rocas, glaciar, clima del páramo |
| `cultura.md` | Memoria y cultura | Nombres, relatos, erupción de 1985, historia del esquí |
| `glosario.md` | Glosario | Términos y definiciones |

El guía puede crear secciones nuevas, y modificar, renombrar, ordenar y borrar las existentes. `avisos.md`, `estaciones.md` y `emergencias.md` no se borran.

## 3. Formato de los archivos

Cada tema tiene dos niveles en el mismo archivo: una **ficha técnica** resumida, que el visitante ve al abrirlo, y un **detalle** ampliado.

```markdown
# Naturaleza

## Frailejón
> Planta emblemática del páramo.
Estaciones: Aguacerales

### Ficha técnica
![Frailejón en Aguacerales](media/imagenes/frailejon-a1b2.webp)

#### Qué es
> Su papel en el páramo.

Planta que capta agua de la niebla.

#### Datos
- Nombre científico: Espeletia hartwegiana
- Dónde verlo: Aguacerales

Fuente: Guion Ecoturístico UTON 2024, p. 5

### Detalle

#### Adaptaciones
> Cómo resiste el frío.

Tiene hojas gruesas y vellosas. Las hojas muertas lo protegen del frío.

![Detalle de hoja](media/imagenes/hoja-7c3d.webp)
[Video: adaptaciones del frailejón](media/videos/frailejon-e5f6.mp4)

Fuente: Guion Ecoturístico UTON 2024, p. 5

#### Especies
> Cuántas especies existen y cuál vive en el parque.

Existen más de 100 especies. En el parque está reportada Espeletia hartwegiana.

Fuente: Guion Ecoturístico UTON 2024, p. 5
```

| Elemento | Regla |
|---|---|
| `#` | Nombre de la sección. Uno por archivo |
| `##` | Tema: una estación, una especie, una norma |
| `### Ficha técnica` | Nombre fijo. Resumen visible al abrir el tema |
| `### Detalle` | Nombre fijo, opcional. Información ampliada, plegada en "Ver más" |
| `####` | Apartado con título libre. Recomendado: máximo 100 a 150 palabras |
| `>` | Descripción de una línea bajo `##` o `####`. Máximo 15 palabras, opcional |
| `Estaciones:` | Opcional. Muestra el tema también dentro de esas estaciones |
| `Fuente:` | Cita que muestra el chatbot. Sin fuente, el chatbot no usa el apartado |
| `Vence:` | Opcional, para avisos |

- La descripción orienta sobre el contenido; no agrega datos nuevos.
- Un tema puede tener solo ficha técnica, por ejemplo una emergencia.
- La información abundante se divide en varios apartados `####` cortos.
- Los avisos y las emergencias que no vienen de un guion se citan así: `Fuente: UTON, 2026-11-26`.
- Cada tema se escribe una sola vez. Por ejemplo, el frailejón vive en `naturaleza.md` y aparece en Aguacerales gracias a `Estaciones:`.
- Las fotos pueden ir en una sección, un tema o un apartado, una o varias.
- El guía no escribe Markdown: llena un formulario y la app genera el archivo. Puede editar tanto la ficha técnica como el detalle.
- El formulario muestra ambos niveles juntos y, al guardar un cambio en el detalle, pregunta si también se actualizó la ficha técnica. Así se evita que se contradigan.

### Cómo se muestra en la aplicación

La app lee el `.md` y lo convierte en niveles.

```
1. Inicio            2. Sección             3. Tema
┌──────────────┐     ┌────────────────┐     ┌──────────────────┐
│ Avisos       │     │ [foto]         │     │ [foto]           │
│ Estaciones   │ ──▶ │ Frailejón      │ ──▶ │ Ficha técnica    │
│ Emergencias  │     │ Planta del…    │     │ ▸ Ver más        │
│ Naturaleza   │     │ [foto]         │     │   Adaptaciones   │
│ ...          │     │ Cóndor         │     │   Especies       │
└──────────────┘     └────────────────┘     └──────────────────┘
```

| En el archivo | En la app |
|---|---|
| `#` | Botón en el inicio |
| `##` | Tarjeta con título, descripción y foto |
| `### Ficha técnica` | Contenido visible del tema |
| `### Detalle` | Bloque "Ver más" |
| `####` | Subtítulo con su descripción; en el detalle, desplegable |

Una sección nueva creada por el guía aparece sola, sin actualizar la app.

## 4. Almacenamiento y publicación

```
contenido/
├── manifiesto.json
├── secciones/
│   ├── estaciones.md
│   └── naturaleza.md
└── media/
    ├── imagenes/
    └── videos/
```

El manifiesto lo genera la app. El orden de la lista es el orden en pantalla.

```json
{
  "version": 12,
  "publicado": "2026-11-26T14:30:00-05:00",
  "archivos": [
    { "ruta": "secciones/naturaleza.md", "bytes": 4100, "sha256": "…" },
    { "ruta": "media/videos/frailejon-e5f6.mp4", "bytes": 6200000, "sha256": "…", "opcional": true }
  ]
}
```

### Por qué Cloudflare R2

- Nivel gratuito mensual: 10 GB de almacenamiento, 1 millón de escrituras y 10 millones de lecturas. La descarga no tiene costo. Fuente: [precios de R2](https://developers.cloudflare.com/r2/pricing/), consultada el 2026-11-26.
- Pendiente de verificar: si pide tarjeta o PayPal para activarlo.
- Requiere un Worker pequeño que valide la contraseña del guía antes de publicar. El visitante descarga sin cuenta.

### Flujo

1. El guía abre su app y descarga la última versión.
2. Edita y toca **Publicar**. Por ahora, cualquier guía publica directamente, sin aprobación.
3. La app sube primero los archivos nuevos y al final el manifiesto.
4. La app del visitante, con conexión, compara la versión.
5. Descarga solo lo nuevo o cambiado, verifica el `sha256` y activa la versión. Si algo falla, conserva la anterior.

Si dos guías publican al mismo tiempo, el segundo recibe un aviso, recarga y repite.

Un cambio publicado durante el recorrido solo llega al visitante si vuelve a conectarse. La app muestra la fecha y hora del contenido, y el guía comunica en persona los cambios urgentes.

### Imágenes y videos

- Imágenes: la app del guía las convierte a WebP, de unos 300 KB como máximo.
- Videos: 720p, cortos, máximo 15 MB. Descarga opcional: "Texto e imágenes" o "Todo".

## 5. Chatbot (RAG)

El archivo se fragmenta por títulos. Cada `####` es un fragmento, tanto de la ficha técnica como del detalle. Si un `###` o un `##` no tiene subtítulos, él es el fragmento.

```
Ruta: Naturaleza > Frailejón > Detalle > Especies
Descripción: Planta emblemática del páramo. Cuántas especies existen y cuál vive en el parque.
Estaciones: Aguacerales
Texto: Existen más de 100 especies...
Fuente: Guion Ecoturístico UTON 2024, p. 5
```

- La aplicación y la búsqueda leen el archivo completo. El visitante puede ver la ficha técnica y el detalle.
- El modelo nunca recibe el archivo completo: solo 5 fragmentos relevantes a la pregunta, de cualquier sección y nivel.
- Cada fragmento hereda las descripciones de sus títulos superiores. Sirven para encontrarlo; el chatbot responde con el texto.
- La ruta evita confundir, por ejemplo, la flora de una estación con la de otra.
- Se indexan el texto y la descripción de cada foto o video, no el archivo. La respuesta muestra la imagen del apartado.
- Se empieza con la búsqueda por palabras clave que ya existe. Los embeddings se agregan solo si no alcanza.

## 6. Requisitos del reto que afectan el contenido

Detalle en `Docs/requisitos_tecnicos/`.

- Cada respuesta indica el guion y la página que la respaldan.
- Si no hay respaldo, las fuentes se contradicen o se pide un dato actual, el asistente lo dice y remite al personal.
- Ante síntomas o emergencias, no diagnostica ni receta.
- No se incluyen los medicamentos (Guion UTON 2024, p. 54) ni la "Alerta Amarilla" como dato actual.
- No se recogen datos personales de los visitantes.

### Contradicciones entre los guiones

| Tema | Diferencia |
|---|---|
| Víctimas de 1985 | Más de 23.000 o más de 25.000 |
| Kumanday | Un guion afirma traducciones; el otro indica que falta investigación |
| Edad de Nereidas | Cerca de 66.000 años o más de 80.000 |
| La Olleta | Figura "107,3 Ma"; por el contexto serían miles de años |
| Mitos | Un guion pide evitarlos; el otro incluye el de la niña fantasma |

## 7. Riesgos

- **Publicación sin revisión:** un error llega a todos. El reto pide contenido revisado por UTON. Conviene agregar aprobación más adelante.
- **Contenido oficial:** el reto prohíbe usarlo para otros fines. Confirmar con UTON antes de alojarlo en un servicio externo y de que sea accesible sin cuenta.
- **Vacíos:** los guiones no traen contactos de emergencia, refugios ni el reglamento completo. UTON debe entregarlos.
- **Borrado del contenido:** si ocurre con el visitante en la montaña, queda sin ayuda. Se recomienda no borrar nunca las emergencias ni la ubicación GPS.

## 8. Pendientes

- [ ] Definir cuándo vence el contenido. Opciones: fecha que fija el guía (recomendada), plazo fijo desde la descarga o salida del parque según GPS.
- [ ] Confirmar el enfoque con la organización: `plan-reto.md` dice que solo el guía usa la app; este diseño tiene guía y visitante.
- [ ] Escribir la especificación técnica y el plan de implementación.
- [ ] Adaptar el código: hoy el contenido es un JSON incluido en la app (`assets/content/fichas.demo.json`).
