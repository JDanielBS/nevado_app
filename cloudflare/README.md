# Publicación del contenido en Cloudflare R2

El guía publica el contenido desde su app cuando tiene internet. El visitante lo descarga antes de subir y lo
abre con la llave que trae el pase. Si no lo descargó, lo recibe por la zona wifi del guía.

| Archivo | Para qué |
|---|---|
| `worker.js` | Recibe la publicación (con clave) y entrega el paquete y el manifiesto |
| `wrangler.toml` | Nombre del Worker y del bucket |

## Qué guarda R2

| Objeto | Contenido |
|---|---|
| `contenido.nev` | Todas las secciones, cifradas con AES-256-GCM. R2 no ve el texto |
| `manifiesto.json` | Versión, fecha, tamaño y SHA-256 del paquete |

Se sube primero el paquete y después el manifiesto. Si dos guías publican a la vez, el segundo recibe un aviso
(409), descarga la versión nueva y repite.

## Crear el Worker (una vez, con la cuenta del equipo)

Requiere una cuenta de Cloudflare con R2 activado y Node.js. Desde esta carpeta:

```sh
npx wrangler login
npx wrangler r2 bucket create nevados-contenido
npx wrangler secret put CLAVE_PUBLICAR      # pegar la clave que genera tool/preparar_guia.dart
npx wrangler deploy
```

`wrangler deploy` imprime la dirección del Worker (`https://nevados-contenido.<cuenta>.workers.dev`). Esa
dirección va en `CONTENIDO_URL` (ver `COMANDOS.md`).

Pendiente de verificar: si activar R2 pide tarjeta o PayPal.

## Límites

- Quien tenga el APK del guía tiene la clave de publicación y la llave del contenido. Si se pierde un teléfono
  del guía, cambiar ambas con `tool/preparar_guia.dart --nuevas` y volver a compilar las dos apps.
- Cualquier guía publica directamente, sin revisión. El reto pide contenido revisado por UTON.
- Confirmar con UTON antes de alojar su contenido en un servicio externo.
