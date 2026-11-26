import 'package:flutter/foundation.dart';

import '../search/search.dart';
import 'card.dart';
import 'seccion.dart';

/// De dónde salen las tarjetas fijas y las secciones que ve la app.
///
/// En el visitante, del paquete cifrado que entrega el guía ([ContentController]); en el guía, de sus
/// archivos editables.
abstract interface class FuenteGuia implements Listenable {
  /// Tarjetas de emergencia. Siempre disponibles, sin pase.
  List<Ficha> get emergencia;

  /// Secciones de la guía. Vacías si el visitante no tiene un pase vigente.
  List<SeccionGuia> get secciones;

  /// Índice de búsqueda de [secciones].
  IndiceGuia get indice;
}
