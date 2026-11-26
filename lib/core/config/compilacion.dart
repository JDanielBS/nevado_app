/// Valores que se fijan al compilar con `--dart-define-from-file` (ver `COMANDOS.md`).
///
/// La app del visitante usa `.env` (token del modelo y dirección del contenido). La del guía usa además
/// `secrets/guia.env`, con las claves para emitir pases, abrir el contenido y publicar. Nunca se compila
/// el visitante con `secrets/guia.env`.
library;

import 'dart:convert';

/// Dirección del Worker de R2 desde la que se descarga el contenido. Vacía: sin descarga por internet.
const contenidoUrl = String.fromEnvironment('CONTENIDO_URL');

/// Solo app del guía: semilla Ed25519 (base64url) con la que firma los pases.
const clavePrivadaPases = String.fromEnvironment('PASE_PRIVADA');

/// Solo app del guía: llave AES-256 (base64url) del contenido. Viaja al visitante dentro del pase.
const llaveContenidoTexto = String.fromEnvironment('LLAVE_CONTENIDO');

/// Solo app del guía: clave del Worker para publicar en R2.
const clavePublicar = String.fromEnvironment('PUBLICAR_CLAVE');

Uri? get direccionContenido => contenidoUrl.isEmpty ? null : Uri.parse(contenidoUrl.endsWith('/') ? contenidoUrl : '$contenidoUrl/');

List<int>? get llaveContenido =>
    llaveContenidoTexto.isEmpty ? null : base64Url.decode(base64Url.normalize(llaveContenidoTexto));
