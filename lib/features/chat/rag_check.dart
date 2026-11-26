import 'package:flutter/foundation.dart';

import '../../core/ai/knowledge_base.dart';
import '../../core/search/search.dart';

/// Autoprueba del buscador dentro de la app: escribir `/prueba` en el chat.
/// Pregunta -> textos aceptables en la ruta del fragmento. Lista vacía: fuera de tema.
const _casos = <String, List<String>>{
  '¿Por qué se rompen las rocas en Valle Lunar?': ['Por qué se rompen', 'Rompimiento en bloques'],
  '¿Qué hace que las piedras se vean coloradas?': ['rocas son rojizas', 'Rompimiento en bloques'],
  '¿Qué papel cumple el frailejón?': ['Frailejón >'],
  '¿Cómo aguantan las plantas peludas el frío?': ['Cómo resiste el frío', 'Función con el agua', 'Radiación solar'],
  '¿Puedo caminar sobre la arena de los montículos?': ['No pises las dunas', 'Dunas de arena'],
  '¿Qué significa Kumanday?': ['Kumanday >'],
  '¿A qué hora puedo entrar al parque?': ['Horario'],
  '¿Es obligatorio ir con alguien que me guíe?': ['Guianza obligatoria'],
  '¿Desde qué edad pueden entrar los niños?': ['Edades'],
  'Tengo ganas de vomitar por la altura': ['Mal agudo de montaña'],
  '¿Qué pasó en Armero?': ['Armero', 'Erupciones históricas', 'Lahares'],
  '¿Antes se esquiaba aquí?': ['Esquí', 'Cabaña de Arenales'],
  '¿El volcán está apagado?': ['Volcán activo'],
  '¿Qué pájaros grandes vuelan por aquí?': ['Aves', 'Fauna'],
  '¿Se está derritiendo el hielo?': ['Glaciar'],
  '¿Cuánta ropa debo llevar?': ['Ropa y calzado'],
  '¿Cómo se prepara una arepa?': [],
  '¿Quién ganó el último mundial de fútbol?': [],
  '¿Me ayudas a resolver una ecuación?': [],
  '¿Cuál es la capital de Francia?': [],
};

Future<String> autoprueba(KnowledgeBase base, IndiceGuia indice) async {
  var primero = 0, enTop = 0, abstenciones = 0, ms = 0;
  final fallos = <String>[];
  for (final caso in _casos.entries) {
    final reloj = Stopwatch()..start();
    final r = await base.buscar(indice, caso.key);
    ms += reloj.elapsedMilliseconds;
    if (caso.value.isEmpty) {
      r.isEmpty ? abstenciones++ : fallos.add('${caso.key} (devolvió ${r.length})');
      continue;
    }
    final pos = r.indexWhere((f) => caso.value.any(f.ruta.contains));
    if (pos == 0) primero++;
    pos >= 0 ? enTop++ : fallos.add(caso.key);
  }
  final dentro = _casos.values.where((v) => v.isNotEmpty).length;
  final texto =
      'Prueba RAG: primero $primero/$dentro, en los $fragmentosPorPregunta primeros $enTop/$dentro, '
      'abstención $abstenciones/${_casos.length - dentro}, ${ms ~/ _casos.length} ms por consulta.\n'
      'Fallos: ${fallos.isEmpty ? 'ninguno' : fallos.join(' · ')}';
  debugPrint('RAG RESUMEN $texto');
  return texto;
}
