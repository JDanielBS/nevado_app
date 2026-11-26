/// Pase de acceso firmado. Dart puro: lo usan la app y `tool/generar_pase.dart`.
///
/// Formato: `NEV1.<datos>.<firma>`, ambos en base64url. Los datos son un JSON con la
/// fecha de emisión y de vencimiento, y la firma es Ed25519 sobre `NEV1.<datos>`.
library;

import 'dart:convert';

import 'package:cryptography/cryptography.dart';

const _prefijo = 'NEV1';

class Pase {
  const Pase({required this.emitido, required this.vence, this.modelo});

  final DateTime emitido;
  final DateTime vence;

  /// Dirección desde la que descargar el modelo (servidor de la estación). Opcional.
  final Uri? modelo;
}

final _algoritmo = Ed25519();

String _codificar(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

List<int> _decodificar(String texto) => base64Url.decode(base64Url.normalize(texto));

/// Genera el código de un pase. Requiere la clave privada: solo se usa fuera de la app.
Future<String> firmarPase(Pase pase, SimpleKeyPair claves) async {
  final datos = _codificar(
    utf8.encode(
      jsonEncode({
        'iat': pase.emitido.millisecondsSinceEpoch ~/ 1000,
        'exp': pase.vence.millisecondsSinceEpoch ~/ 1000,
        if (pase.modelo != null) 'url': '${pase.modelo}',
      }),
    ),
  );
  final mensaje = '$_prefijo.$datos';
  final firma = await _algoritmo.sign(utf8.encode(mensaje), keyPair: claves);
  return '$mensaje.${_codificar(firma.bytes)}';
}

/// Devuelve el pase si la firma corresponde a [clavePublica] (base64url); si no, `null`.
///
/// No comprueba el vencimiento: eso depende del reloj y lo decide quien llama.
Future<Pase?> leerPase(String codigo, String clavePublica) async {
  try {
    final partes = codigo.trim().split('.');
    if (partes.length != 3 || partes[0] != _prefijo) return null;
    final valida = await _algoritmo.verify(
      utf8.encode('${partes[0]}.${partes[1]}'),
      signature: Signature(
        _decodificar(partes[2]),
        publicKey: SimplePublicKey(_decodificar(clavePublica), type: KeyPairType.ed25519),
      ),
    );
    if (!valida) return null;
    final datos = jsonDecode(utf8.decode(_decodificar(partes[1]))) as Map<String, dynamic>;
    DateTime fecha(String campo) => DateTime.fromMillisecondsSinceEpoch((datos[campo] as int) * 1000);
    final url = datos['url'] as String?;
    return Pase(emitido: fecha('iat'), vence: fecha('exp'), modelo: url == null ? null : Uri.parse(url));
  } catch (_) {
    // Cualquier código mal formado es simplemente un pase no válido.
    return null;
  }
}
