// Worker de publicación del contenido de Nevados en Cloudflare R2.
//
// GET  /manifiesto.json   versión publicada (público)
// GET  /contenido.nev     paquete cifrado (público; sin la llave del pase no se puede leer)
// PUT  /contenido.nev     publica una versión nueva. Requiere "Authorization: Bearer <CLAVE_PUBLICAR>" y
//                         "x-version-base: <versión que el guía tenía>". Responde 409 si otro guía publicó antes.
//
// Enlaces del Worker (ver wrangler.toml): bucket R2 "CONTENIDO" y secreto "CLAVE_PUBLICAR".

const MAXIMO = 20 * 1024 * 1024;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const ruta = url.pathname.replace(/^\/+/, '');

    if (request.method === 'GET' && (ruta === 'manifiesto.json' || ruta === 'contenido.nev')) {
      const objeto = await env.CONTENIDO.get(ruta);
      if (!objeto) return new Response('No publicado', { status: 404 });
      return new Response(objeto.body, {
        headers: {
          'content-type': ruta.endsWith('.json') ? 'application/json' : 'application/octet-stream',
          'cache-control': 'no-store',
        },
      });
    }

    if (request.method === 'PUT' && ruta === 'contenido.nev') {
      if (!(await claveValida(request.headers.get('authorization'), env.CLAVE_PUBLICAR))) {
        return new Response('No autorizado', { status: 401 });
      }
      const base = Number.parseInt(request.headers.get('x-version-base') ?? '', 10);
      if (!Number.isInteger(base) || base < 0) return new Response('Falta x-version-base', { status: 400 });

      const anterior = await env.CONTENIDO.get('manifiesto.json');
      const actual = anterior ? (await anterior.json()).version : 0;
      if (actual !== base) return Response.json({ version: actual }, { status: 409 });

      const cuerpo = await request.arrayBuffer();
      const marca = new TextDecoder().decode(new Uint8Array(cuerpo.slice(0, 5)));
      if (cuerpo.byteLength > MAXIMO || marca !== 'NEVC1') {
        return new Response('Paquete no válido', { status: 400 });
      }
      const huella = [...new Uint8Array(await crypto.subtle.digest('SHA-256', cuerpo))]
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');
      const manifiesto = {
        version: actual + 1,
        publicado: new Date().toISOString(),
        bytes: cuerpo.byteLength,
        sha256: huella,
      };
      // Primero el paquete y al final el manifiesto: quien lea el manifiesto encuentra el paquete completo.
      await env.CONTENIDO.put('contenido.nev', cuerpo);
      await env.CONTENIDO.put('manifiesto.json', JSON.stringify(manifiesto));
      return Response.json(manifiesto);
    }

    return new Response('No encontrado', { status: 404 });
  },
};

// Comparación en tiempo constante, para no revelar la clave por la duración de la respuesta.
async function claveValida(cabecera, clave) {
  if (!clave || !cabecera?.startsWith('Bearer ')) return false;
  const codificar = (t) => crypto.subtle.digest('SHA-256', new TextEncoder().encode(t));
  const [a, b] = await Promise.all([codificar(cabecera.slice(7)), codificar(clave)]);
  return crypto.subtle.timingSafeEqual(a, b);
}
