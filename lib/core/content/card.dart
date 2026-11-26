/// Tarjetas fijas (capa determinista) y respuestas del asistente.
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

/// Tarjeta fija escrita y revisada por personas, como las de emergencia. No depende del modelo.
class Ficha {
  const Ficha({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.texto,
    required this.fuente,
    required this.fechaVerificacion,
    required this.estado,
  });

  final String id;
  final Categoria categoria;
  final String titulo;
  final String texto;

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
        fuente: json['fuente'] as String,
        fechaVerificacion: json['fechaVerificacion'] as String?,
        estado: EstadoFicha.values.byName(json['estado'] as String),
      );
}

enum TipoRespuesta {
  /// Se encontraron fragmentos de la guía y se muestran sin modelo (modo ahorro o sin modelo).
  respuesta,

  /// No hay fragmento con fuente: no se inventa.
  sinInformacion,

  /// La app no responde por diseño (medicamentos).
  limite,

  /// La persona describe una urgencia.
  emergencia,
}

class Respuesta {
  const Respuesta(this.tipo, this.texto, {this.fuentes = const [], this.tarjetas = const [], this.verificada = false});
  final TipoRespuesta tipo;
  final String texto;

  /// Citas de los fragmentos en que se basa (guion y página).
  final List<String> fuentes;

  /// Tarjetas fijas que se muestran, como las de emergencia.
  final List<Ficha> tarjetas;
  final bool verificada;
}

/// Secciones de la guía en Markdown, para la app del guía y las pruebas. No se incluyen en la app del
/// visitante: se entregan cifradas. Hoy es contenido en borrador.
const rutaSecciones = 'contenido/secciones';
