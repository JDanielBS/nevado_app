import 'package:flutter/material.dart';

import '../../core/route/estaciones.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import 'temas_de_estacion.dart';

/// Ficha de una estación: datos, "Estoy aquí" y contenido por pestañas.
class StationScreen extends StatelessWidget {
  const StationScreen({
    super.key,
    required this.estacion,
    required this.esActual,
    required this.pestana,
    required this.onPestana,
    required this.onEstoyAqui,
    required this.onVolver,
    this.anterior,
    this.siguiente,
  });

  final Estacion estacion;
  final bool esActual;
  final Pestana pestana;
  final ValueChanged<Pestana> onPestana;
  final VoidCallback onEstoyAqui;
  final VoidCallback onVolver;

  /// Estación anterior y siguiente de la ruta; nulas en los extremos.
  final ({String nombre, VoidCallback abrir})? anterior;
  final ({String nombre, VoidCallback abrir})? siguiente;

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    return ListView(
      // Al cambiar de estación la ficha vuelve arriba.
      key: PageStorageKey(estacion.nombre),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: BotonSecundario(texto: '← Volver a la ruta', onPressed: onVolver),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tema.navegacion,
            borderRadius: BorderRadius.circular(16),
            border: Border(bottom: BorderSide(color: tema.linea, width: 6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(estacion.nombre, style: estiloTitulo(32, color: Colors.white)),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Altitud: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: '${estacion.textoAltitud}\n'),
                  const TextSpan(text: 'Ecosistema: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: estacion.ecosistema),
                ]),
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BotonPrincipal(
          texto: esActual ? '✓ Marcada como tu estación actual' : 'Estoy aquí',
          onPressed: onEstoyAqui,
        ),
        const SizedBox(height: 12),
        _Pestanas(actual: pestana, onPestana: onPestana),
        const SizedBox(height: 12),
        for (final bloque in contenidoDe(estacion, pestana))
          switch (bloque) {
            BloqueFoto(:final ruta, :final pie) => FotoLocal(ruta: ruta, pie: pie),
            BloqueTexto(:final titulo, :final texto, :final pendiente) =>
              TarjetaTexto(titulo: titulo, texto: texto, borde: pendiente ? tema.linea : Colores.borde),
          },
        TemasDeEstacion(estacion: estacion.nombre),
        const SizedBox(height: 6),
        _NavegacionEstaciones(anterior: anterior, siguiente: siguiente),
      ],
    );
  }
}

class _Pestanas extends StatelessWidget {
  const _Pestanas({required this.actual, required this.onPestana});

  final Pestana actual;
  final ValueChanged<Pestana> onPestana;

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          for (final p in Pestana.values)
            Expanded(
              child: Semantics(
                selected: p == actual,
                child: TextButton(
                  onPressed: () => onPestana(p),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, altoMinimo),
                    padding: const EdgeInsets.all(2),
                    backgroundColor: p == actual ? tema.acento : Colores.superficie,
                    foregroundColor: p == actual ? Colors.white : Colores.tinta,
                    side: BorderSide(color: p == actual ? tema.acento : Colores.bordeFuerte, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontFamily: Fuentes.cuerpo, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: Text(p.etiqueta, textAlign: TextAlign.center),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Botones para pasar a la estación anterior o siguiente sin volver a la ruta.
class _NavegacionEstaciones extends StatelessWidget {
  const _NavegacionEstaciones({required this.anterior, required this.siguiente});

  final ({String nombre, VoidCallback abrir})? anterior;
  final ({String nombre, VoidCallback abrir})? siguiente;

  @override
  Widget build(BuildContext context) {
    final anterior = this.anterior;
    final siguiente = this.siguiente;
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: anterior == null
              ? const SizedBox.shrink()
              : BotonSecundario(texto: '‹ ${anterior.nombre}', onPressed: anterior.abrir),
        ),
        Expanded(
          child: siguiente == null
              ? const SizedBox.shrink()
              : BotonPrincipal(texto: '${siguiente.nombre} ›', onPressed: siguiente.abrir),
        ),
      ],
    );
  }
}
