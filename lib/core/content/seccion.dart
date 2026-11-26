/// Contenido de la guía en Markdown, según `Docs/estrategia-informacion.md`. Dart puro: lo usan las
/// dos apps y las herramientas.
///
/// ```markdown
/// # Sección
/// > Descripción opcional.
/// ## Tema
/// > Descripción opcional.
/// Estaciones: Aguacerales
/// ### Ficha técnica
/// #### Apartado
/// > Descripción opcional.
/// Texto.
/// Fuente: Guion Ecoturístico UTON 2024, p. 5
/// ### Detalle
/// ...
/// ```
library;

/// Bloque de texto con título opcional. Es la unidad que recupera el asistente.
class Apartado {
  Apartado({this.titulo, this.descripcion, this.texto = '', this.fuente});

  /// `null` cuando el texto va directo bajo `###` o `##`, sin `####`.
  String? titulo;
  String? descripcion;
  String texto;

  /// Sin fuente, el asistente no usa el apartado.
  String? fuente;

  Apartado copia() => Apartado(titulo: titulo, descripcion: descripcion, texto: texto, fuente: fuente);
}

/// Una estación, una especie, una norma.
class Tema {
  Tema({
    required this.titulo,
    this.descripcion,
    List<String>? estaciones,
    this.vence,
    List<Apartado>? ficha,
    List<Apartado>? detalle,
  }) : estaciones = estaciones ?? [],
       ficha = ficha ?? [],
       detalle = detalle ?? [];

  String titulo;
  String? descripcion;
  List<String> estaciones;

  /// Fecha (AAAA-MM-DD) en que deja de valer. Se usa en los avisos.
  String? vence;

  /// Resumen visible al abrir el tema.
  List<Apartado> ficha;

  /// Información ampliada ("Ver más").
  List<Apartado> detalle;

  Tema copia() => Tema(
    titulo: titulo,
    descripcion: descripcion,
    estaciones: [...estaciones],
    vence: vence,
    ficha: [for (final a in ficha) a.copia()],
    detalle: [for (final a in detalle) a.copia()],
  );
}

/// Un archivo `.md`: una sección del inicio.
class SeccionGuia {
  SeccionGuia({
    required this.archivo,
    required this.titulo,
    this.descripcion,
    List<Tema>? temas,
    this.verificada = false,
  }) : temas = temas ?? [];

  /// Nombre del archivo, por ejemplo `naturaleza.md`.
  final String archivo;
  String titulo;
  String? descripcion;
  List<Tema> temas;

  /// Lo indica el paquete, no el archivo: hoy todo el contenido es un borrador.
  bool verificada;
}

/// Secciones que el guía no puede borrar.
const seccionesFijas = {'avisos.md', 'estaciones.md', 'emergencias.md'};

/// Lee una sección. No falla con texto mal formado: lo que no reconoce lo trata como texto.
SeccionGuia leerSeccion(String archivo, String markdown, {bool verificada = false}) {
  final seccion = SeccionGuia(archivo: archivo, titulo: archivo.replaceAll('.md', ''), verificada: verificada);
  Tema? tema;
  List<Apartado>? nivel;
  Apartado? apartado;
  // A qué título corresponde una línea "> descripción" que aparezca ahora.
  void Function(String)? describir;
  final texto = StringBuffer();

  void cerrarTexto() {
    final valor = texto.toString().trim();
    texto.clear();
    if (valor.isEmpty) return;
    if (apartado == null) {
      // Texto suelto bajo ## o ###: es un apartado sin título.
      if (tema == null) return;
      nivel ??= tema.ficha;
      apartado = Apartado();
      nivel!.add(apartado!);
    }
    apartado!.texto = apartado!.texto.isEmpty ? valor : '${apartado!.texto}\n$valor';
  }

  for (final cruda in markdown.split('\n')) {
    final linea = cruda.trimRight();
    final limpia = linea.trim();

    if (limpia.startsWith('> ') && describir != null && texto.isEmpty) {
      describir(limpia.substring(2).trim());
      describir = null;
      continue;
    }
    if (!limpia.startsWith('#') && limpia.isNotEmpty) describir = null;

    if (limpia.startsWith('#### ')) {
      cerrarTexto();
      if (tema == null) continue;
      nivel ??= tema.ficha;
      final nuevo = Apartado(titulo: limpia.substring(5).trim());
      nivel!.add(nuevo);
      apartado = nuevo;
      describir = (d) => nuevo.descripcion = d;
    } else if (limpia.startsWith('### ')) {
      cerrarTexto();
      if (tema == null) continue;
      final nombre = limpia.substring(4).trim().toLowerCase();
      nivel = nombre.startsWith('detalle') ? tema.detalle : tema.ficha;
      apartado = null;
    } else if (limpia.startsWith('## ')) {
      cerrarTexto();
      final nuevo = Tema(titulo: limpia.substring(3).trim());
      seccion.temas.add(nuevo);
      tema = nuevo;
      nivel = null;
      apartado = null;
      describir = (d) => nuevo.descripcion = d;
    } else if (limpia.startsWith('# ')) {
      cerrarTexto();
      seccion.titulo = limpia.substring(2).trim();
      describir = (d) => seccion.descripcion = d;
    } else if (limpia.startsWith('Fuente:')) {
      cerrarTexto();
      final fuente = limpia.substring(7).trim();
      if (apartado != null) {
        apartado!.fuente = fuente;
      } else if (nivel != null && nivel!.isNotEmpty) {
        nivel!.last.fuente ??= fuente;
      }
    } else if (limpia.startsWith('Estaciones:') && tema != null && nivel == null) {
      tema.estaciones = [
        for (final e in limpia.substring(11).split(','))
          if (e.trim().isNotEmpty) e.trim(),
      ];
    } else if (limpia.startsWith('Vence:') && tema != null && nivel == null) {
      tema.vence = limpia.substring(6).trim();
    } else {
      if (limpia.isEmpty && texto.isEmpty) continue;
      texto.writeln(linea);
    }
  }
  cerrarTexto();

  // Un apartado sin fuente propia toma la del resto de su nivel (como en el ejemplo del documento,
  // donde una sola "Fuente:" cierra la ficha técnica).
  for (final t in seccion.temas) {
    for (final n in [t.ficha, t.detalle]) {
      final comun = n.map((a) => a.fuente).whereType<String>().lastOrNull;
      for (final a in n) {
        a.fuente ??= comun;
      }
    }
  }
  return seccion;
}

/// Genera el Markdown de una sección. El guía no lo escribe a mano: lo produce el formulario.
String escribirSeccion(SeccionGuia seccion) {
  final b = StringBuffer('# ${_unaLinea(seccion.titulo)}\n');
  if (_lleno(seccion.descripcion)) b.writeln('> ${_unaLinea(seccion.descripcion!)}');
  for (final tema in seccion.temas) {
    b.writeln('\n## ${_unaLinea(tema.titulo)}');
    if (_lleno(tema.descripcion)) b.writeln('> ${_unaLinea(tema.descripcion!)}');
    if (tema.estaciones.isNotEmpty) b.writeln('Estaciones: ${tema.estaciones.join(', ')}');
    if (_lleno(tema.vence)) b.writeln('Vence: ${tema.vence}');
    for (final (nombre, apartados) in [('Ficha técnica', tema.ficha), ('Detalle', tema.detalle)]) {
      if (apartados.isEmpty) continue;
      b.writeln('\n### $nombre');
      for (final a in apartados) {
        if (_lleno(a.titulo)) b.writeln('\n#### ${_unaLinea(a.titulo!)}');
        if (_lleno(a.descripcion)) b.writeln('> ${_unaLinea(a.descripcion!)}');
        b.writeln();
        if (a.texto.trim().isNotEmpty) b.writeln(_sinMarcas(a.texto.trim()));
        if (_lleno(a.fuente)) b.writeln('\nFuente: ${_unaLinea(a.fuente!)}');
      }
    }
  }
  return b.toString();
}

bool _lleno(String? s) => s != null && s.trim().isNotEmpty;
String _unaLinea(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Evita que el texto escrito por el guía se lea como un título, una fuente o una descripción.
String _sinMarcas(String texto) => [
  for (final l in texto.split('\n'))
    RegExp(r'^\s*(#|>|Fuente:|Estaciones:|Vence:)').hasMatch(l) ? '​$l' : l,
].join('\n');

/// Lo que recupera el asistente: un apartado con su ruta y las descripciones heredadas.
class Fragmento {
  const Fragmento({
    required this.ruta,
    required this.descripcion,
    required this.estaciones,
    required this.texto,
    required this.fuente,
    this.verificado = false,
  });

  /// "Naturaleza > Frailejón > Detalle > Especies".
  final String ruta;
  final String descripcion;
  final List<String> estaciones;
  final String texto;
  final String fuente;
  final bool verificado;
}

/// Fragmentos con fuente de todas las secciones. Se omiten los apartados sin fuente y los temas vencidos
/// (`Vence:` anterior a [hoy]).
List<Fragmento> fragmentar(Iterable<SeccionGuia> secciones, {DateTime? hoy}) => [
  for (final s in secciones)
    for (final t in s.temas)
      if (!_vencido(t, hoy ?? DateTime.now()))
      for (final (nivel, apartados) in [('Ficha técnica', t.ficha), ('Detalle', t.detalle)])
        for (final a in apartados)
          if (_lleno(a.fuente) && a.texto.trim().isNotEmpty)
            Fragmento(
              ruta: [s.titulo, t.titulo, nivel, if (_lleno(a.titulo)) a.titulo!].join(' > '),
              descripcion: [
                s.descripcion,
                t.descripcion,
                a.descripcion,
              ].whereType<String>().where(_lleno).join(' '),
              estaciones: t.estaciones,
              texto: _textoPlano(a.texto),
              fuente: a.fuente!,
              verificado: s.verificada,
            ),
];

bool _vencido(Tema t, DateTime hoy) {
  final vence = t.vence == null ? null : DateTime.tryParse(t.vence!);
  return vence != null && vence.isBefore(DateTime(hoy.year, hoy.month, hoy.day));
}

/// Quita las marcas de imagen y video y deja su descripción, que sí sirve para buscar.
String _textoPlano(String texto) => texto
    .replaceAllMapped(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), (m) => 'Imagen: ${m[1]}.')
    .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
    .replaceAll('​', '')
    .trim();
