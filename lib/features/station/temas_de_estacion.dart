import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/content/seccion.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';

/// Temas del contenido que corresponden a una estación: el tema con su nombre en la sección Estaciones
/// y los temas de otras secciones que la nombran en `Estaciones:`.
List<(SeccionGuia, Tema)> temasDeEstacion(List<SeccionGuia> secciones, String estacion) {
  String clave(String s) => s.toLowerCase().trim();
  final nombre = clave(estacion);
  return [
    for (final s in secciones)
      for (final t in s.temas)
        if ((s.archivo == 'estaciones.md' && clave(t.titulo) == nombre) ||
            t.estaciones.any((e) => clave(e) == nombre))
          (s, t),
  ];
}

/// Bloque "En la guía" de la ficha de una estación. Sin pase vigente no hay contenido y no ocupa espacio.
class TemasDeEstacion extends StatelessWidget {
  const TemasDeEstacion({super.key, required this.estacion});

  final String estacion;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.maybeOf(context);
    final temas = temasDeEstacion(scope?.secciones ?? const [], estacion);
    if (temas.isEmpty) return const SizedBox.shrink();
    final sinVerificar = temas.any((t) => !t.$1.verificada);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text('En la guía', style: estiloTitulo(26)),
        if (sinVerificar) const Linea('Contenido en revisión: puede tener errores.', color: Colores.aviso),
        const SizedBox(height: 8),
        for (final (s, t) in temas) _TemaTarjeta(seccion: s, tema: t),
      ],
    );
  }
}

class _TemaTarjeta extends StatelessWidget {
  const _TemaTarjeta({required this.seccion, required this.tema});

  final SeccionGuia seccion;
  final Tema tema;

  @override
  Widget build(BuildContext context) => Caja(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(seccion.archivo == 'estaciones.md' ? 'Ficha técnica' : seccion.titulo.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colores.textoSuave)),
        TituloCaja(tema.titulo),
        if (tema.descripcion != null) Linea(tema.descripcion!, negrita: true),
        for (final a in tema.ficha) _ApartadoView(apartado: a),
        if (tema.detalle.isNotEmpty)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              // Clave propia: sin ella comparte el almacenamiento de la lista de la estación, que guarda
              // el desplazamiento (un número), y falla al leerlo como abierto o cerrado.
              key: PageStorageKey('ver-mas-${seccion.archivo}-${tema.titulo}'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('Ver más', style: TextStyle(fontWeight: FontWeight.w700)),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final a in tema.detalle) _ApartadoView(apartado: a)],
            ),
          ),
      ],
    ),
  );
}

class _ApartadoView extends StatelessWidget {
  const _ApartadoView({required this.apartado});
  final Apartado apartado;

  @override
  Widget build(BuildContext context) {
    // Las imágenes todavía no viajan con el contenido: se muestra su descripción.
    final texto = apartado.texto.replaceAllMapped(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), (m) => '[Imagen: ${m[1]}]');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          if (apartado.titulo != null)
            Text(apartado.titulo!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(texto, style: const TextStyle(fontSize: 15, height: 1.45, color: Colores.texto)),
          if (apartado.fuente != null)
            Text('Fuente: ${apartado.fuente}', style: const TextStyle(fontSize: 12, color: Colores.textoSuave)),
        ],
      ),
    );
  }
}
