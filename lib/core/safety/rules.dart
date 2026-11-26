import '../search/normalize.dart';

/// Guardias de seguridad. Se evalúan ANTES de buscar en la guía y de usar el modelo.
/// Son deterministas y no dependen de ningún modelo.
class Regla {
  const Regla({required this.nombre, required this.respuesta, required this.coincide});

  final String nombre;

  /// Texto fijo que se entrega cuando la pregunta cae en esta regla.
  final String respuesta;
  final bool Function(String preguntaNormalizada) coincide;
}

bool Function(String) _tiene(String patron) {
  final re = RegExp(patron);
  return (p) => re.hasMatch(p);
}

const _parteDelCuerpo = r'(pierna|pie|tobillo|rodilla|cadera|brazo|codo|mano|muneca|dedo|hombro|clavicula|'
    r'costilla|espalda|columna|cuello|cabeza|nariz|hueso)s?';

/// Frases que indican una urgencia. Se comparan contra el texto normalizado (sin tildes, "ñ" como "n").
/// Ante la duda es preferible mostrar la tarjeta de emergencia: omitir una urgencia es el error grave.
const _patronesEmergencia = <String>[
  // Peticiones de ayuda y extravío.
  r'emergencia|auxilio|socorro|herid[oa]s?|accidente|rescate|me perdi|estoy perdid[oa]|perdid[oa]s?',
  // Lesiones. Los verbos de rotura exigen una parte del cuerpo, para no activar con objetos o ramas.
  '(me|se) (he |ha )?(rompi|rompio|roto|quebre|quebro|quebrado|torci|torcio|torcido|doble|doblo|zafe|zafo|disloque|disloco) '
      '([a-z]+ ){0,2}$_parteDelCuerpo',
  '$_parteDelCuerpo (rot[oa]s?|quebrad[oa]s?|torcid[oa]s?|dislocad[oa]s?)',
  r'fractur\w*|esguince|luxacion',
  r'me cai|me he caido|se cayo y|(sufri|sufrio|tuvo|tuve) una caida',
  '(me golpee|se golpeo|golpe en) ([a-z]+ ){0,2}$_parteDelCuerpo',
  r'sangr\w+|hemorragia|me corte|se corto (la|el|un|una)|quemadura|me queme|se quemo (la|el)',
  // Estado grave.
  r'inconsciente|desmay\w*|convulsion\w*|infarto|no despierta|no reacciona',
  r'no respira|no (puedo|puede) respirar|(me|le) cuesta respirar|me ahogo|se (esta )?ahoga(ndo)?',
  r'(dolor (fuerte )?(en el|de) pecho)|(me|le) duele (mucho )?el pecho',
  r'no (puedo|puede) (caminar|moverme|moverse|levantarme|levantarse)',
  // Animales.
  r'(me|lo|la) mordio|(me|le) pico (un|una)|mordedura|picadura',
];

final reglaEmergencia = Regla(
  nombre: 'emergencia',
  respuesta: '',
  coincide: _tiene('\\b(${_patronesEmergencia.join('|')})\\b'),
);

/// Límites fijos, que no pasan por el modelo. El clima actual, "¿es seguro?" y los tiempos de
/// caminata se piden en las instrucciones del modelo (`armarPrompt`).
final reglasLimite = <Regla>[
  Regla(
    nombre: 'medicamentos',
    respuesta: 'No puedo recomendar medicamentos ni dosis. Consulta a un profesional de salud. '
        'Si es una urgencia, toca EMERGENCIA.',
    coincide: _tiene(
      r'\b(pastillas?|medicamentos?|medicinas?|dosis|ibuprofeno|acetaminofen|paracetamol|aspirina|acetazolamida)\b',
    ),
  ),
];

bool esEmergencia(String pregunta) => reglaEmergencia.coincide(normalizar(pregunta));

Regla? reglaDeLimite(String pregunta) {
  final p = normalizar(pregunta);
  for (final regla in reglasLimite) {
    if (regla.coincide(p)) return regla;
  }
  return null;
}
