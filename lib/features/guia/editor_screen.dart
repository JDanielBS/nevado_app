import 'package:flutter/material.dart';

import '../../core/content/seccion.dart';
import '../../core/route/estaciones.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import 'compartir_screen.dart';

/// Lista de secciones del guía. El guía no escribe Markdown: llena formularios y la app genera los archivos.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contenido = GuiaScope.maybeOf(context)!.contenido;
    return Scaffold(
      appBar: AppBar(title: const Text('Contenido de la guía')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva sección'),
        onPressed: () async {
          final datos = await _pedirTitulo(context, titulo: 'Nueva sección');
          if (datos == null) return;
          final archivo = contenido.crearSeccion(datos.$1, descripcion: datos.$2);
          if (context.mounted) _abrir(context, archivo);
        },
      ),
      body: ListenableBuilder(
        listenable: contenido,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (contenido.sinPublicar)
              const Linea('Hay cambios guardados en este teléfono. Publícalos en Compartir cuando tengas internet.',
                  color: Colores.aviso, negrita: true),
            for (final (i, s) in contenido.secciones.indexed)
              Card(
                child: ListTile(
                  title: Text(s.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${s.temas.length} temas${s.descripcion == null ? '' : ' · ${s.descripcion}'}'),
                  onTap: () => _abrir(context, s.archivo),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Subir',
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: i == 0 ? null : () => contenido.moverSeccion(s.archivo, -1),
                      ),
                      IconButton(
                        tooltip: 'Bajar',
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: i == contenido.secciones.length - 1
                            ? null
                            : () => contenido.moverSeccion(s.archivo, 1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _abrir(BuildContext context, String archivo) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => SeccionEditorScreen(archivo: archivo)),
  );
}

/// Pide título y descripción. Devuelve `null` si se cancela.
Future<(String, String?)?> _pedirTitulo(BuildContext context, {required String titulo, String? actual, String? descripcion}) {
  final t = TextEditingController(text: actual);
  final d = TextEditingController(text: descripcion);
  return showDialog<(String, String?)>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: t, autofocus: true, decoration: const InputDecoration(labelText: 'Título')),
          TextField(
            controller: d,
            decoration: const InputDecoration(labelText: 'Descripción (opcional, máx. 15 palabras)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            if (t.text.trim().isEmpty) return;
            Navigator.pop(context, (t.text.trim(), d.text.trim().isEmpty ? null : d.text.trim()));
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

/// Temas de una sección.
class SeccionEditorScreen extends StatelessWidget {
  const SeccionEditorScreen({super.key, required this.archivo});

  final String archivo;

  @override
  Widget build(BuildContext context) {
    final contenido = GuiaScope.maybeOf(context)!.contenido;
    return ListenableBuilder(
      listenable: contenido,
      builder: (context, _) {
        final s = contenido.secciones.where((x) => x.archivo == archivo).firstOrNull;
        if (s == null) return const Scaffold(body: Center(child: Text('La sección ya no existe.')));
        return Scaffold(
          appBar: AppBar(
            title: Text(s.titulo),
            actions: [
              IconButton(
                tooltip: 'Renombrar',
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final datos = await _pedirTitulo(
                    context,
                    titulo: 'Sección',
                    actual: s.titulo,
                    descripcion: s.descripcion,
                  );
                  if (datos != null) contenido.editarSeccion(archivo, titulo: datos.$1, descripcion: datos.$2);
                },
              ),
              if (contenido.sePuedeBorrar(archivo))
                IconButton(
                  tooltip: 'Borrar sección',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await _confirmar(context, '¿Borrar la sección "${s.titulo}" y todos sus temas?')) {
                      contenido.borrarSeccion(archivo);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Nuevo tema'),
            onPressed: () => _editar(context, Tema(titulo: '', ficha: [Apartado()]), null),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              if (s.temas.isEmpty) const Linea('Esta sección no tiene temas todavía.'),
              for (final (i, t) in s.temas.indexed)
                Card(
                  child: ListTile(
                    title: Text(t.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([
                      if (t.descripcion != null) t.descripcion!,
                      '${t.ficha.length + t.detalle.length} apartados',
                      if (_sinFuente(t)) 'hay apartados sin fuente',
                    ].join(' · ')),
                    onTap: () => _editar(context, t.copia(), i),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _editar(BuildContext context, Tema tema, int? posicion) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => TemaEditorScreen(archivo: archivo, tema: tema, posicion: posicion)),
  );
}

bool _sinFuente(Tema t) =>
    [...t.ficha, ...t.detalle].any((a) => a.texto.trim().isNotEmpty && (a.fuente ?? '').trim().isEmpty);

Future<bool> _confirmar(BuildContext context, String pregunta, {String si = 'Borrar'}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(pregunta),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(si)),
        ],
      ),
    ) ??
    false;

/// Formulario de un tema: ficha técnica y detalle juntos, para que no se contradigan.
class TemaEditorScreen extends StatefulWidget {
  const TemaEditorScreen({super.key, required this.archivo, required this.tema, this.posicion});

  final String archivo;

  /// Copia del tema: los cambios no se aplican hasta guardar.
  final Tema tema;

  /// Posición del tema en la sección; `null` si es nuevo.
  final int? posicion;

  @override
  State<TemaEditorScreen> createState() => _TemaEditorScreenState();
}

class _TemaEditorScreenState extends State<TemaEditorScreen> {
  late final Tema _tema = widget.tema;
  late final String _fichaInicial = _texto(_tema.ficha);
  late final String _detalleInicial = _texto(_tema.detalle);
  final _formulario = GlobalKey<FormState>();

  static String _texto(List<Apartado> a) =>
      a.map((x) => '${x.titulo}|${x.descripcion}|${x.texto}|${x.fuente}').join('\n');

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    _formulario.currentState!.save();
    for (final n in [_tema.ficha, _tema.detalle]) {
      n.removeWhere((a) => a.texto.trim().isEmpty && (a.titulo ?? '').trim().isEmpty);
    }
    final cambioDetalle = _texto(_tema.detalle) != _detalleInicial;
    final cambioFicha = _texto(_tema.ficha) != _fichaInicial;
    if (widget.posicion != null && cambioDetalle && !cambioFicha && _tema.ficha.isNotEmpty) {
      final guardar = await _confirmar(
        context,
        'Cambiaste el detalle. ¿La ficha técnica sigue de acuerdo con él?',
        si: 'Sí, guardar',
      );
      if (!guardar) return;
    }
    if (_sinFuente(_tema) && mounted) {
      final guardar = await _confirmar(
        context,
        'Hay apartados sin fuente. Se muestran en la app, pero el asistente no los usa. ¿Guardar igual?',
        si: 'Guardar',
      );
      if (!guardar) return;
    }
    if (!mounted) return;
    GuiaScope.maybeOf(context)!.contenido.guardarTema(widget.archivo, _tema, posicion: widget.posicion);
    Navigator.pop(context);
  }

  Future<void> _borrar() async {
    final posicion = widget.posicion;
    if (posicion == null) return Navigator.pop(context);
    if (await _confirmar(context, '¿Borrar el tema "${_tema.titulo}"?') && mounted) {
      GuiaScope.maybeOf(context)!.contenido.borrarTema(widget.archivo, posicion);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombres = [for (final e in estaciones) e.nombre];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.posicion == null ? 'Nuevo tema' : 'Editar tema'),
        actions: [IconButton(tooltip: 'Borrar tema', icon: const Icon(Icons.delete_outline), onPressed: _borrar)],
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextFormField(
              initialValue: _tema.titulo,
              decoration: const InputDecoration(labelText: 'Título del tema'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe un título' : null,
              onSaved: (v) => _tema.titulo = v!.trim(),
            ),
            TextFormField(
              initialValue: _tema.descripcion,
              decoration: const InputDecoration(labelText: 'Descripción de una línea (opcional)'),
              onSaved: (v) => _tema.descripcion = (v ?? '').trim().isEmpty ? null : v!.trim(),
            ),
            const SizedBox(height: Espacio.s),
            const Linea('Mostrar también en las estaciones:', negrita: true),
            Wrap(
              spacing: 8,
              children: [
                for (final n in nombres)
                  FilterChip(
                    label: Text(n),
                    selected: _tema.estaciones.contains(n),
                    onSelected: (si) => setState(() => si ? _tema.estaciones.add(n) : _tema.estaciones.remove(n)),
                  ),
              ],
            ),
            TextFormField(
              initialValue: _tema.vence,
              decoration: const InputDecoration(labelText: 'Vence (AAAA-MM-DD, solo para avisos)'),
              validator: (v) => (v ?? '').trim().isEmpty || RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v!.trim())
                  ? null
                  : 'Usa el formato 2026-11-30',
              onSaved: (v) => _tema.vence = (v ?? '').trim().isEmpty ? null : v!.trim(),
            ),
            _Nivel(
              titulo: 'Ficha técnica',
              ayuda: 'Resumen que el visitante ve al abrir el tema.',
              apartados: _tema.ficha,
              onCambio: () => setState(() {}),
            ),
            _Nivel(
              titulo: 'Detalle',
              ayuda: 'Información ampliada, en "Ver más". Opcional.',
              apartados: _tema.detalle,
              onCambio: () => setState(() {}),
            ),
            const SizedBox(height: Espacio.m),
            BotonPrincipal(texto: 'Guardar', onPressed: _guardar),
          ],
        ),
      ),
    );
  }
}

class _Nivel extends StatelessWidget {
  const _Nivel({required this.titulo, required this.ayuda, required this.apartados, required this.onCambio});

  final String titulo;
  final String ayuda;
  final List<Apartado> apartados;
  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Espacio.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titulo, style: estiloTitulo(22)),
        Linea(ayuda),
        for (final (i, a) in apartados.indexed)
          Card(
            key: ObjectKey(a),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Apartado ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      IconButton(
                        tooltip: 'Quitar apartado',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          apartados.removeAt(i);
                          onCambio();
                        },
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: a.titulo,
                    decoration: const InputDecoration(labelText: 'Subtítulo (opcional)'),
                    onSaved: (v) => a.titulo = (v ?? '').trim().isEmpty ? null : v!.trim(),
                  ),
                  TextFormField(
                    initialValue: a.descripcion,
                    decoration: const InputDecoration(labelText: 'Descripción de una línea (opcional)'),
                    onSaved: (v) => a.descripcion = (v ?? '').trim().isEmpty ? null : v!.trim(),
                  ),
                  TextFormField(
                    initialValue: a.texto,
                    minLines: 3,
                    maxLines: 10,
                    decoration: const InputDecoration(labelText: 'Texto (máx. 100 a 150 palabras)'),
                    onSaved: (v) => a.texto = (v ?? '').trim(),
                  ),
                  TextFormField(
                    initialValue: a.fuente,
                    decoration: const InputDecoration(
                      labelText: 'Fuente (ej.: Guion Ecoturístico UTON 2024, p. 5)',
                      helperText: 'Sin fuente, el asistente no usa este apartado.',
                    ),
                    onSaved: (v) => a.fuente = (v ?? '').trim().isEmpty ? null : v!.trim(),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Agregar apartado'),
          onPressed: () {
            apartados.add(Apartado());
            onCambio();
          },
        ),
      ],
    ),
  );
}
