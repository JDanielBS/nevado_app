import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/route/estaciones.dart';
import '../../core/ui/palette.dart';
import '../access/access_gate.dart';
import '../chat/model_provisioning.dart';
import '../map/map_screen.dart';
// Se mantiene el mapa actual (visor MapLibre offline).
import '../map/map_view_io.dart' if (dart.library.js_interop) '../map/map_view_web.dart';

/// Recorrido: mapa, perfil de elevación, estaciones y zona cerrada.
class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key, required this.actual, required this.onAbrir});

  /// Estación donde está el visitante.
  final int actual;
  final ValueChanged<int> onAbrir;

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    final plano = AppScope.maybeOf(context)?.settings.ahorroActivo ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        const AccessCard(),
        const ModelStatus(),
        _MarcoMapa(
          plano: plano,
          onAmpliar: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => TemaScope(tema: tema, child: const AccessGate(title: 'Mapa', child: MapScreen())),
          )),
        ),
        const SizedBox(height: 12),
        const _PerfilElevacion(),
        const SizedBox(height: 12),
        for (final (i, e) in estaciones.indexed)
          _BotonEstacion(numero: i + 1, estacion: e, esActual: i == actual, onTap: () => onAbrir(i)),
        const SizedBox(height: 6),
        Text('Fuera del recorrido habilitado', style: estiloTitulo(21)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colores.avisoFondo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colores.aviso, width: 2),
          ),
          child: const Text.rich(
            TextSpan(children: [
              TextSpan(
                text: 'Refugio · Mirador Cráter Arenas — CERRADOS\n',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: 'Acceso restringido por actividad volcánica. El recorrido termina en el Valle de las Tumbas.',
              ),
            ]),
            style: TextStyle(fontSize: 15, height: 1.45, color: Colores.texto),
          ),
        ),
      ],
    );
  }
}

class _MarcoMapa extends StatelessWidget {
  const _MarcoMapa({required this.plano, required this.onAmpliar});

  final bool plano;
  final VoidCallback onAmpliar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 286,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colores.tinta, width: 2),
        color: TemaScope.of(context).fondo,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(child: MapView(flat: plano)),
            Positioned(
              right: 8,
              top: 8,
              child: Material(
                color: Colores.superficie,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colores.tinta),
                ),
                child: InkWell(
                  onTap: onAmpliar,
                  borderRadius: BorderRadius.circular(8),
                  child: const SizedBox(
                    height: altoMinimo,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          Icon(Icons.open_in_full, size: 18, color: Colores.tinta),
                          Text('Ampliar mapa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerfilElevacion extends StatelessWidget {
  const _PerfilElevacion();

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    final conDato = [for (final e in estaciones) if (e.altitud != null) '${e.nombre} ${formatoMiles(e.altitud!)}'];
    final sinDato = [for (final e in estaciones) if (e.altitud == null) e.nombre];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colores.borde, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text('Perfil de elevación · m s. n. m. (aprox.)', style: estiloTitulo(19)),
          Semantics(
            label: 'Perfil: ${conDato.join(', ')}.'
                '${sinDato.isEmpty ? '' : ' ${sinDato.join(', ')} sin dato confirmado.'}',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 96,
                width: double.infinity,
                child: CustomPaint(painter: _PintorPerfil(acento: tema.acento, tinte: tema.tinte)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PintorPerfil extends CustomPainter {
  const _PintorPerfil({required this.acento, required this.tinte});

  final Color acento;
  final Color tinte;

  @override
  void paint(Canvas canvas, Size size) {
    const margen = 16.0;
    const base = 76.0;
    final ancho = size.width - 2 * margen;
    final alturas = [for (final e in estaciones) if (e.altitud != null) e.altitud!];
    final minimo = alturas.reduce((a, b) => a < b ? a : b) - 60;
    final maximo = alturas.reduce((a, b) => a > b ? a : b);

    double x(int i) => margen + ancho * i / (estaciones.length - 1);
    double y(int altitud) => base - 4 - (altitud - minimo) / (maximo - minimo) * (base - 24);

    final puntos = [
      for (final (i, e) in estaciones.indexed)
        if (e.altitud != null) (Offset(x(i), y(e.altitud!)), e.altitud!),
    ];

    final linea = Path()..moveTo(puntos.first.$1.dx, puntos.first.$1.dy);
    for (final (p, _) in puntos.skip(1)) {
      linea.lineTo(p.dx, p.dy);
    }
    final relleno = Path.from(linea)
      ..lineTo(puntos.last.$1.dx, base)
      ..lineTo(puntos.first.$1.dx, base)
      ..close();
    canvas.drawPath(relleno, Paint()..color = tinte);
    canvas.drawPath(
      linea,
      Paint()
        ..color = acento
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );

    final punto = Paint()..color = Colores.tinta;
    for (final (p, altitud) in puntos) {
      canvas.drawCircle(p, 4, punto);
      _texto(canvas, formatoMiles(altitud), Offset(p.dx, p.dy - 20), size.width);
    }
    for (var i = 0; i < estaciones.length; i++) {
      _texto(canvas, '${i + 1}', Offset(x(i), base + 4), size.width);
    }
  }

  void _texto(Canvas canvas, String texto, Offset centro, double ancho) {
    final pintor = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(fontFamily: Fuentes.cuerpo, fontSize: 12, fontWeight: FontWeight.w700, color: Colores.tinta),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final izquierda = (centro.dx - pintor.width / 2).clamp(0.0, ancho - pintor.width);
    pintor.paint(canvas, Offset(izquierda, centro.dy));
  }

  @override
  bool shouldRepaint(_PintorPerfil old) => old.acento != acento || old.tinte != tinte;
}

class _BotonEstacion extends StatelessWidget {
  const _BotonEstacion({required this.numero, required this.estacion, required this.esActual, required this.onTap});

  final int numero;
  final Estacion estacion;
  final bool esActual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: esActual ? tema.acento : Colores.borde, width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                spacing: 12,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 22),
                    child: Text('$numero', style: estiloTitulo(26)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(estacion.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(estacion.textoAltitud, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Text(
                    esActual ? '● Estás aquí' : '›',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tema.acento),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
