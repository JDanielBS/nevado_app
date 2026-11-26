/// Tipos de contenido de la guía.
library;

enum Categoria { seguridad, emergencia, norma, clima, fauna, flora, ruta, lugar, refugio }

enum EstadoFicha { borrador, verificado }

const Map<Categoria, String> etiquetaCategoria = {
  Categoria.seguridad: 'Seguridad',
  Categoria.emergencia: 'Emergencia',
  Categoria.norma: 'Normas',
  Categoria.clima: 'Clima',
  Categoria.fauna: 'Fauna',
  Categoria.flora: 'Flora',
  Categoria.ruta: 'Rutas',
  Categoria.lugar: 'Lugares',
  Categoria.refugio: 'Refugios',
};

/// Unidad de contenido de la guía. Una idea por ficha.
class Ficha {
  const Ficha({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.texto,
    required this.fuente,
    required this.fechaVerificacion,
    required this.estado,
    this.palabrasClave = const [],
  });

  final String id;
  final Categoria categoria;
  final String titulo;
  final String texto;
  final List<String> palabrasClave;

  /// Entidad o documento de origen.
  final String fuente;

  /// Fecha (AAAA-MM-DD) en que un revisor verificó la ficha; null si aún no.
  final String? fechaVerificacion;
  final EstadoFicha estado;

  bool get verificada => estado == EstadoFicha.verificado;

  factory Ficha.desdeJson(Map<String, dynamic> json) => Ficha(
        id: json['id'] as String,
        categoria: Categoria.values.byName(json['categoria'] as String),
        titulo: json['titulo'] as String,
        texto: json['texto'] as String,
        palabrasClave: [for (final p in (json['palabrasClave'] as List? ?? const [])) p as String],
        fuente: json['fuente'] as String,
        fechaVerificacion: json['fechaVerificacion'] as String?,
        estado: EstadoFicha.values.byName(json['estado'] as String),
      );
}

class Coincidencia {
  const Coincidencia(this.ficha, this.puntaje);
  final Ficha ficha;
  final int puntaje;
}

enum TipoRespuesta {
  /// Se encontró contenido en las fichas.
  respuesta,

  /// No hay ficha suficiente: no se inventa.
  sinInformacion,

  /// La app no puede responder por diseño (clima actual, tiempos, "es seguro").
  limite,

  /// La persona describe una urgencia.
  emergencia,
}

class Respuesta {
  const Respuesta(this.tipo, this.texto, this.fuentes);
  final TipoRespuesta tipo;
  final String texto;

  /// Fichas en las que se basa la respuesta.
  final List<Ficha> fuentes;
}

/// Contrato del asistente. Hoy lo implementa la búsqueda local; más adelante
/// puede implementarlo un modelo en el dispositivo sin cambiar las pantallas.
abstract interface class Asistente {
  Future<Respuesta> responder(String pregunta);
}
