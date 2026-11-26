import 'package:flutter/material.dart';

import '../core/route/estaciones.dart';
import '../core/ui/palette.dart';
import '../core/ui/widgets.dart';
import '../features/about/about_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/route/route_screen.dart';
import '../features/safety/safety_screen.dart';
import '../features/station/station_screen.dart';
import 'app_scope.dart';

enum Seccion { ruta, ficha, guia, seguridad, acerca }

/// Estructura del mockup: encabezado, contenido y navegación inferior.
/// La paleta y la marca de agua cambian según la estación que se está viendo en la ficha;
/// en el resto de secciones siguen a la estación marcada como "Estoy aquí".
class KumandayShell extends StatefulWidget {
  const KumandayShell({super.key});

  @override
  State<KumandayShell> createState() => _KumandayShellState();
}

class _KumandayShellState extends State<KumandayShell> {
  Seccion _seccion = Seccion.ruta;

  /// Estación abierta en la ficha.
  int _seleccionada = 0;

  /// Estación donde dice estar el visitante.
  int _actual = 0;
  Pestana _pestana = Pestana.geologia;

  void _ir(Seccion seccion) => setState(() => _seccion = seccion);

  void _abrirEstacion(int indice) => setState(() {
        _seleccionada = indice;
        _pestana = Pestana.geologia;
        _seccion = Seccion.ficha;
      });

  ({String nombre, VoidCallback abrir})? _vecina(int indice) => indice < 0 || indice >= estaciones.length
      ? null
      : (nombre: estaciones[indice].nombre, abrir: () => _abrirEstacion(indice));

  /// Estación cuyos colores se muestran: la abierta en la ficha o, si no, la actual.
  int get _indiceTema => _seccion == Seccion.ficha ? _seleccionada : _actual;

  @override
  Widget build(BuildContext context) {
    final indice = _indiceTema;
    return TweenAnimationBuilder<TemaEstacion>(
      tween: TemaEstacionTween(end: temasEstacion[indice]),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      builder: (context, tema, _) => _construir(context, tema, indice),
    );
  }

  Widget _construir(BuildContext context, TemaEstacion tema, int indice) {
    final ajustes = AppScope.maybeOf(context)?.settings;

    return TemaScope(
      tema: tema,
      // Atrás del teléfono: desde cualquier sección vuelve a la ruta antes de cerrar la app.
      child: PopScope(
        canPop: _seccion == Seccion.ruta,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _ir(Seccion.ruta);
        },
        child: Scaffold(
          backgroundColor: tema.fondo,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                top: MediaQuery.sizeOf(context).height * 0.4,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  child: MarcaDeAgua(
                    key: ValueKey(indice),
                    ruta: estaciones[indice].fotoPaisaje,
                    color: tema.marcaDeAgua,
                  ),
                ),
              ),
              Column(
                children: [
                  _Cromo(child: _Encabezado(onAcerca: () => _ir(Seccion.acerca))),
                  if (ajustes != null) AvisoAhorro(ajustes: ajustes),
                  Expanded(
                    child: SafeArea(top: false, bottom: false, child: _contenido()),
                  ),
                  _Cromo(child: _Navegacion(seccion: _seccion, onIr: _ir)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido() => switch (_seccion) {
        Seccion.ruta => RouteScreen(actual: _actual, onAbrir: _abrirEstacion),
        Seccion.ficha => StationScreen(
            estacion: estaciones[_seleccionada],
            esActual: _actual == _seleccionada,
            pestana: _pestana,
            onPestana: (p) => setState(() => _pestana = p),
            onEstoyAqui: () => setState(() => _actual = _seleccionada),
            onVolver: () => _ir(Seccion.ruta),
            anterior: _vecina(_seleccionada - 1),
            siguiente: _vecina(_seleccionada + 1),
          ),
        Seccion.guia => const ChatScreen(),
        Seccion.seguridad => const SafetyScreen(),
        Seccion.acerca => const AboutScreen(),
      };
}

/// Pantallas bajas (teléfono en horizontal): las barras fijas se compactan.
bool _pantallaBaja(BuildContext context) => MediaQuery.sizeOf(context).height < 420;

/// Limita el crecimiento del texto en las barras fijas para que el contenido siga visible
/// con el texto del sistema muy grande. El contenido sí escala sin límite.
class _Cromo extends StatelessWidget {
  const _Cromo({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.withClampedTextScaling(maxScaleFactor: _pantallaBaja(context) ? 1 : 1.3, child: child);
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.onAcerca});
  final VoidCallback onAcerca;

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tema.encabezado,
        border: Border(bottom: BorderSide(color: tema.linea, width: 4)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            spacing: 10,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colores.tinta,
                    shape: BoxShape.circle,
                    border: Border.all(color: tema.linea, width: 2),
                  ),
                  child: const CustomPaint(painter: _Emblema()),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kumanday', style: estiloTitulo(24, color: tema.encabezadoTexto)),
                    Text(tema.nombre, style: TextStyle(fontSize: 13, color: tema.encabezadoTexto)),
                  ],
                ),
              ),
              SizedBox(
                width: altoMinimo,
                height: altoMinimo,
                child: OutlinedButton(
                  onPressed: onAcerca,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colores.superficie,
                    foregroundColor: Colores.tinta,
                    side: const BorderSide(color: Colores.tinta, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('i',
                      semanticsLabel: 'Acerca del parque',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Montaña blanca del emblema del parque.
class _Emblema extends CustomPainter {
  const _Emblema();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;
    final o = Offset(9 * s, 9 * s);
    final p = Path()
      ..moveTo(o.dx + 2 * s, o.dy + 24 * s)
      ..lineTo(o.dx + 12 * s, o.dy + 8 * s)
      ..lineTo(o.dx + 16 * s, o.dy + 13 * s)
      ..lineTo(o.dx + 19 * s, o.dy + 10 * s)
      ..lineTo(o.dx + 28 * s, o.dy + 24 * s)
      ..close();
    canvas.drawPath(p, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_Emblema oldDelegate) => false;
}

class _Navegacion extends StatelessWidget {
  const _Navegacion({required this.seccion, required this.onIr});

  final Seccion seccion;
  final ValueChanged<Seccion> onIr;

  static const _entradas = [
    (Seccion.ruta, 'Ruta'),
    (Seccion.guia, 'Guía IA'),
    (Seccion.seguridad, 'Seguridad'),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    return ColoredBox(
      color: tema.navegacion,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            spacing: 6,
            children: [
              for (final (destino, etiqueta) in _entradas)
                Expanded(
                  child: _BotonNavegacion(
                    etiqueta: etiqueta,
                    // La ficha de una estación es parte de la ruta.
                    activo: seccion == destino || (destino == Seccion.ruta && seccion == Seccion.ficha),
                    onTap: () => onIr(destino),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonNavegacion extends StatelessWidget {
  const _BotonNavegacion({required this.etiqueta, required this.activo, required this.onTap});

  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    return Semantics(
      selected: activo,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          backgroundColor: activo ? Colores.superficie : Colors.transparent,
          foregroundColor: activo ? tema.navegacion : Colors.white,
          side: const BorderSide(color: Colores.borde, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontFamily: Fuentes.cuerpo, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(etiqueta, textAlign: TextAlign.center),
      ),
    );
  }
}
