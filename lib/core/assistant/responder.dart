import '../search/search.dart';
import '../content/card_repository.dart';
import '../content/card.dart';
import '../safety/rules.dart';

const mensajeSinInformacion =
    'No tengo información verificada sobre eso en esta guía. Pregunta a un funcionario o guía del parque. '
    'Si es una urgencia, toca el botón EMERGENCIA.';

/// Orden de decisión: emergencia, límites de diseño, búsqueda, y si no hay nada, se dice que no hay.
Respuesta responderPregunta(String pregunta, List<Ficha> fichas) {
  if (esEmergencia(pregunta)) {
    final tarjetas = fichasDeEmergencia(fichas);
    final texto = tarjetas.map((f) => f.texto).join('\n\n');
    return Respuesta(TipoRespuesta.emergencia, texto.isEmpty ? mensajeSinInformacion : texto, tarjetas);
  }

  final limite = reglaDeLimite(pregunta);
  if (limite != null) return Respuesta(TipoRespuesta.limite, limite.respuesta, const []);

  final coincidencias = buscar(pregunta, fichas);
  if (coincidencias.isEmpty) return const Respuesta(TipoRespuesta.sinInformacion, mensajeSinInformacion, []);

  return Respuesta(
    TipoRespuesta.respuesta,
    coincidencias.first.ficha.texto,
    [for (final c in coincidencias) c.ficha],
  );
}

/// Asistente actual: búsqueda local. Un modelo en el dispositivo implementaría la misma interfaz.
class AsistenteLocal implements Asistente {
  const AsistenteLocal(this.fichas);
  final List<Ficha> fichas;

  @override
  Future<Respuesta> responder(String pregunta) async => responderPregunta(pregunta, fichas);
}
