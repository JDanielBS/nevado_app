import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/compilacion.dart';
import '../../core/content/publicacion_r2.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/qr_view.dart';
import '../../core/ui/widgets.dart';
import '../access/access_gate.dart' show describirRestante;
import 'compartir_controller.dart';
import 'editor_screen.dart';
import 'guia_contenido.dart';

/// Controladores de la app del guía, disponibles en todas sus pantallas.
class GuiaScope extends InheritedWidget {
  const GuiaScope({super.key, required this.contenido, required this.compartir, required super.child});

  final GuiaContenido contenido;
  final CompartirController compartir;

  static GuiaScope? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<GuiaScope>();

  @override
  bool updateShouldNotify(GuiaScope old) => contenido != old.contenido || compartir != old.compartir;
}

/// Pantalla del guía: publicar en internet, compartir por su zona wifi y emitir el pase.
class CompartirScreen extends StatelessWidget {
  const CompartirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = GuiaScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([scope.compartir, scope.contenido]),
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text('Compartir', style: estiloTitulo(30)),
          const SizedBox(height: 12),
          _ContenidoCaja(contenido: scope.contenido),
          _ZonaWifiCaja(compartir: scope.compartir),
          if (scope.compartir.encendido) _PaseCaja(compartir: scope.compartir),
          if (scope.compartir.encendido && scope.compartir.hayApk && scope.compartir.base != null)
            _InstalarCaja(direccion: '${scope.compartir.base}'),
        ],
      ),
    );
  }
}

class _ContenidoCaja extends StatefulWidget {
  const _ContenidoCaja({required this.contenido});
  final GuiaContenido contenido;

  @override
  State<_ContenidoCaja> createState() => _ContenidoCajaState();
}

class _ContenidoCajaState extends State<_ContenidoCaja> {
  String? _mensaje;
  bool _ocupado = false;

  ClienteR2? _cliente() {
    final base = direccionContenido;
    return base == null ? null : ClienteR2(base, clave: clavePublicar.isEmpty ? null : clavePublicar);
  }

  Future<void> _hacer(Future<String> Function(ClienteR2 cliente) accion) async {
    final cliente = _cliente();
    final llave = llaveContenido;
    if (cliente == null || llave == null) {
      setState(() => _mensaje = 'La app se compiló sin CONTENIDO_URL o sin las claves del guía.');
      return;
    }
    setState(() {
      _ocupado = true;
      _mensaje = null;
    });
    try {
      final texto = await accion(cliente);
      if (mounted) setState(() => _mensaje = texto);
    } on ConflictoDeVersion catch (e) {
      if (mounted) {
        setState(() => _mensaje = 'Otro guía publicó la versión ${e.actual}. Descarga la última versión y vuelve a publicar.');
      }
    } catch (e) {
      if (mounted) setState(() => _mensaje = 'Sin conexión con el servidor de contenido ($e).');
    } finally {
      cliente.cerrar();
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _publicar() => _hacer((c) async {
    final m = await widget.contenido.publicar(c, llaveContenido!);
    return 'Publicada la versión ${m.version}. Los visitantes la descargan al abrir la app con internet.';
  });

  Future<void> _actualizar() async {
    if (widget.contenido.sinPublicar) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hay cambios sin publicar'),
          content: const Text('Si descargas la última versión, se reemplazan los cambios de este teléfono.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reemplazar')),
          ],
        ),
      );
      if (seguir != true) return;
    }
    await _hacer((c) async {
      final m = await widget.contenido.actualizar(c, llaveContenido!);
      return m == null ? 'Ya tienes la última versión.' : 'Descargada la versión ${m.version}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contenido;
    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Espacio.s,
        children: [
          const TituloCaja('Contenido de la guía'),
          Linea('${c.secciones.length} secciones · versión ${c.version == 0 ? 'sin publicar' : c.version}'
              '${c.sinPublicar ? ' · con cambios sin publicar' : ''}'),
          BotonPrincipal(
            texto: 'Editar contenido',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditorScreen())),
          ),
          const Linea('Con internet:', negrita: true),
          BotonSecundario(texto: _ocupado ? 'Espera…' : 'Publicar en internet', onPressed: _ocupado ? null : _publicar),
          BotonSecundario(
            texto: _ocupado ? 'Espera…' : 'Descargar la última versión',
            onPressed: _ocupado ? null : _actualizar,
          ),
          if (_mensaje != null) Linea(_mensaje!, negrita: true),
        ],
      ),
    );
  }
}

class _ZonaWifiCaja extends StatelessWidget {
  const _ZonaWifiCaja({required this.compartir});
  final CompartirController compartir;

  @override
  Widget build(BuildContext context) {
    final c = compartir;
    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Espacio.s,
        children: [
          const TituloCaja('Zona wifi del guía'),
          const Linea('Sin internet: activa la zona wifi del teléfono, pide a los visitantes que se conecten y '
              'enciende el servidor. Solo responde dentro de esa red.'),
          if (!c.configurado)
            const Linea('Esta app se compiló sin las claves del guía (secrets/guia.env): no puede emitir pases.',
                color: Colores.aviso, negrita: true),
          if (c.encendido) ...[
            Linea(c.ip == null ? 'Elige la red de la zona wifi:' : 'Servidor encendido en ${c.base}', negrita: true),
            for (final r in c.redes)
              RadioListTile<String>(
                value: r.ip,
                groupValue: c.ip,
                onChanged: (v) => v == null ? null : c.elegirRed(v),
                title: Text(r.ip),
                subtitle: Text(r.interfaz),
              ),
            if (c.redes.isEmpty) const Linea('No hay red local. Activa la zona wifi y toca Buscar redes.'),
            OutlinedButton(onPressed: c.actualizarRedes, child: const Text('Buscar redes')),
            Linea('Modelo de IA: ${c.hayModelo ? 'se comparte' : 'no está en este teléfono (descárgalo en Guía IA y '
                'vuelve a encender)'}'),
            Linea('App del visitante: ${c.hayApk ? 'se comparte' : 'no está en este teléfono (ver COMANDOS.md)'}'),
            BotonSecundario(texto: 'Apagar servidor', onPressed: c.apagar),
            if (c.registro.isNotEmpty) Linea('Última descarga: ${c.registro.first}', tamano: 13),
          ] else
            BotonPrincipal(texto: c.ocupado ? 'Encendiendo…' : 'Encender servidor', onPressed: c.ocupado ? null : c.encender),
          if (c.error != null) Linea(c.error!, color: Colores.aviso, negrita: true),
        ],
      ),
    );
  }
}

class _PaseCaja extends StatefulWidget {
  const _PaseCaja({required this.compartir});
  final CompartirController compartir;

  @override
  State<_PaseCaja> createState() => _PaseCajaState();
}

class _PaseCajaState extends State<_PaseCaja> {
  // Redibuja la cuenta regresiva.
  late final Timer _reloj = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void dispose() {
    _reloj.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.compartir;
    final codigo = c.codigoPase;
    final restante = c.vence?.difference(DateTime.now());
    final vencido = restante == null || restante.isNegative;
    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Espacio.s,
        children: [
          const TituloCaja('Pase del recorrido'),
          if (codigo == null)
            const Linea('Elige la red de la zona wifi para emitir el pase.')
          else ...[
            const Linea('El visitante abre Nevados, toca Escanear pase y apunta a este código.'),
            Center(child: QrView(datos: codigo, etiqueta: 'Pase del recorrido')),
            Linea(vencido ? 'Este pase venció: emite uno nuevo.' : 'Vence en ${describirRestante(restante)}.',
                negrita: true, color: vencido ? Colores.aviso : Colores.texto),
          ],
          BotonPrincipal(
            texto: 'Emitir pase nuevo ($minutosPase min)',
            onPressed: c.ip == null ? null : () => c.emitirPase(),
          ),
        ],
      ),
    );
  }
}

class _InstalarCaja extends StatelessWidget {
  const _InstalarCaja({required this.direccion});
  final String direccion;

  @override
  Widget build(BuildContext context) => Caja(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Espacio.s,
      children: [
        const TituloCaja('Instalar la app'),
        const Linea('Para quien no tiene la app: que escanee este código con la cámara del teléfono, conectado a '
            'tu zona wifi, y descargue la aplicación.'),
        Center(child: QrView(datos: direccion, lado: 200, etiqueta: 'Instalar Nevados')),
        Linea(direccion, tamano: 13),
      ],
    ),
  );
}
