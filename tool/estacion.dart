// Servidor HTTP de la estación: entrega la página de instalación, el APK y el modelo.
import 'dart:io';

/// Archivos que se pueden descargar, por su ruta. No se sirve nada más.
typedef Descargas = Map<String, File>;

String paginaInicio() =>
    '<!doctype html><html lang="es"><head><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width, initial-scale=1"><title>Nevados</title>'
    '<style>body{font-family:sans-serif;max-width:32rem;margin:auto;padding:1.5rem;line-height:1.5}'
    'a.boton{display:block;background:#1b5e4a;color:#fff;text-align:center;padding:1rem;'
    'border-radius:.5rem;text-decoration:none;font-size:1.2rem}</style></head><body>'
    '<h1>Instalar Nevados</h1>'
    '<p><a class="boton" href="/nevados.apk">Descargar la aplicación</a></p>'
    '<ol><li>Abre el archivo descargado.</li>'
    '<li>Si el teléfono lo pide, permite instalar aplicaciones de este origen.</li>'
    '<li>Abre Nevados y toca <b>Escanear pase</b> con el QR que te muestra el personal.</li>'
    '<li>Espera a que termine la descarga del modelo, sin salir de la red de la estación.</li></ol>'
    '</body></html>';

Future<HttpServer> iniciarServidor(
  Descargas descargas, {
  int puerto = 8000,
  void Function(String)? registro,
}) async {
  final servidor = await HttpServer.bind(InternetAddress.anyIPv4, puerto);
  servidor.listen((peticion) async {
    try {
      await _atender(peticion, descargas);
      registro?.call('${peticion.response.statusCode} ${peticion.method} ${peticion.uri.path}');
    } catch (e) {
      // El teléfono canceló la descarga o perdió la red.
      registro?.call('Descarga interrumpida: ${peticion.uri.path}');
    }
  });
  return servidor;
}

Future<void> _atender(HttpRequest peticion, Descargas descargas) async {
  final respuesta = peticion.response;
  if (peticion.method != 'GET' && peticion.method != 'HEAD') {
    respuesta.statusCode = HttpStatus.methodNotAllowed;
    return respuesta.close();
  }
  if (peticion.uri.path == '/') {
    respuesta.headers.contentType = ContentType.html;
    respuesta.write(paginaInicio());
    return respuesta.close();
  }
  final archivo = descargas[peticion.uri.path];
  if (archivo == null) {
    respuesta.statusCode = HttpStatus.notFound;
    return respuesta.close();
  }

  final total = await archivo.length();
  var inicio = 0;
  // Permite reanudar una descarga cortada ("Range: bytes=1000-").
  final rango = RegExp(r'^bytes=(\d+)-$').firstMatch(peticion.headers.value(HttpHeaders.rangeHeader) ?? '');
  if (rango != null) {
    inicio = int.parse(rango.group(1)!);
    if (inicio >= total) {
      respuesta.statusCode = HttpStatus.requestedRangeNotSatisfiable;
      return respuesta.close();
    }
    respuesta.statusCode = HttpStatus.partialContent;
    respuesta.headers.set(HttpHeaders.contentRangeHeader, 'bytes $inicio-${total - 1}/$total');
  }
  respuesta.headers
    ..contentType = peticion.uri.path.endsWith('.apk')
        ? ContentType('application', 'vnd.android.package-archive')
        : ContentType.binary
    ..set(HttpHeaders.acceptRangesHeader, 'bytes');
  respuesta.contentLength = total - inicio;
  if (peticion.method == 'GET') await respuesta.addStream(archivo.openRead(inicio));
  await respuesta.close();
}
