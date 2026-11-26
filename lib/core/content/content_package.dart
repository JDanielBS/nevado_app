/// Paquete cifrado de fichas. Dart puro: lo usan la app y las herramientas de la estación.
///
/// Formato: `NEVC1` + nonce (12 bytes) + texto cifrado + código de autenticación (16 bytes),
/// con AES-256-GCM. La llave viaja en el pase.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const bytesLlave = 32;
final _marca = ascii.encode('NEVC1');
final _cifrador = AesGcm.with256bits();

Future<Uint8List> cifrarPaquete(List<int> contenido, List<int> llave) async {
  final caja = await _cifrador.encrypt(contenido, secretKey: SecretKey(llave));
  return Uint8List.fromList([..._marca, ...caja.concatenation()]);
}

/// Lanza una excepción si el paquete está dañado, fue alterado o la llave no corresponde.
Future<List<int>> descifrarPaquete(List<int> paquete, List<int> llave) async {
  final inicio = _marca.length;
  if (paquete.length < inicio + 28 ||
      ascii.decode(paquete.sublist(0, inicio), allowInvalid: true) != 'NEVC1') {
    throw const FormatException('No es un paquete de contenido.');
  }
  final caja = SecretBox.fromConcatenation(paquete.sublist(inicio), nonceLength: 12, macLength: 16);
  return _cifrador.decrypt(caja, secretKey: SecretKey(llave));
}
