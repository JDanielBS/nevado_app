import 'package:flutter/material.dart';

/// Colores neutros del mockup "Kumanday · Guía de campo offline".
abstract final class Colores {
  static const tinta = Color(0xFF111518);
  static const superficie = Color(0xFFFFFFFF);
  static const texto = tinta;
  static const textoSuave = Color(0xFF3D464D);
  static const borde = Color(0xFFC5CCD2);
  static const bordeFuerte = Color(0xFF4A545C);

  /// Alertas: amarillo de la franja de seguridad y ámbar de zonas cerradas.
  static const alerta = Color(0xFFFFCC33);
  static const aviso = Color(0xFF7A4D00);
  static const avisoFondo = Color(0xFFFFF3D1);

  /// En el mockup las emergencias usan el mismo lenguaje que las alertas (tinta sobre amarillo).
  static const emergencia = tinta;
  static const emergenciaFondo = alerta;

  /// Espacios de foto pendientes de cargar.
  static const fotoFondo = Color(0xFFE6EBEE);
  static const fotoTexto = Color(0xFF242B30);
}

abstract final class Fuentes {
  static const cuerpo = 'AtkinsonHyperlegible';
  static const titulos = 'BarlowCondensed';
}

/// Títulos condensados del mockup.
TextStyle estiloTitulo(double tamano, {Color? color}) => TextStyle(
      fontFamily: Fuentes.titulos,
      fontWeight: FontWeight.w700,
      fontSize: tamano,
      height: 1.05,
      color: color ?? Colores.texto,
    );

abstract final class Espacio {
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
}

/// Altura mínima de los controles, para uso con dedos o guantes finos.
const altoMinimo = 48.0;

/// Paleta de cada estación de la ruta. Cambia según la estación que se está viendo
/// (o, fuera de la ficha, la marcada como "Estoy aquí").
class TemaEstacion {
  const TemaEstacion({
    required this.nombre,
    required this.acento,
    required this.navegacion,
    required this.fondo,
    required this.encabezado,
    required this.encabezadoTexto,
    required this.linea,
    required this.tinte,
    required this.marcaDeAgua,
  });

  /// Nombre de la paleta, visible bajo el título.
  final String nombre;
  final Color acento;
  final Color navegacion;
  final Color fondo;
  final Color encabezado;
  final Color encabezadoTexto;
  final Color linea;
  final Color tinte;

  /// Color con el que se tiñe la foto de paisaje usada como marca de agua.
  final Color marcaDeAgua;

  /// Mezcla dos paletas para animar el cambio de estación. El nombre salta al destino.
  static TemaEstacion lerp(TemaEstacion a, TemaEstacion b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return TemaEstacion(
      nombre: t < 0.5 ? a.nombre : b.nombre,
      acento: c(a.acento, b.acento),
      navegacion: c(a.navegacion, b.navegacion),
      fondo: c(a.fondo, b.fondo),
      encabezado: c(a.encabezado, b.encabezado),
      encabezadoTexto: c(a.encabezadoTexto, b.encabezadoTexto),
      linea: c(a.linea, b.linea),
      tinte: c(a.tinte, b.tinte),
      marcaDeAgua: c(a.marcaDeAgua, b.marcaDeAgua),
    );
  }
}

/// Interpola entre paletas de estación para `TweenAnimationBuilder`.
class TemaEstacionTween extends Tween<TemaEstacion> {
  TemaEstacionTween({super.begin, super.end});

  @override
  TemaEstacion lerp(double t) => TemaEstacion.lerp(begin!, end!, t);
}

/// Una paleta por estación, en el orden de la ruta.
const temasEstacion = <TemaEstacion>[
  TemaEstacion(
    nombre: 'Brisas · Páramo dorado',
    acento: Color(0xFF7A5200),
    navegacion: Color(0xFF2B2008),
    fondo: Color(0xFFFBF5E4),
    encabezado: Color(0xFFFFF8E3),
    encabezadoTexto: Colores.tinta,
    linea: Color(0xFFB8902A),
    tinte: Color(0xFFF0DFA8),
    marcaDeAgua: Color(0xFF7A5200),
  ),
  TemaEstacion(
    nombre: 'Aguacerales · Verde esmeralda',
    acento: Color(0xFF00634A),
    navegacion: Color(0xFF06251C),
    fondo: Color(0xFFEDF8F4),
    encabezado: Color(0xFFE0F3EB),
    encabezadoTexto: Colores.tinta,
    linea: Color(0xFF1F9C78),
    tinte: Color(0xFFC4E9DA),
    marcaDeAgua: Color(0xFF00634A),
  ),
  TemaEstacion(
    nombre: 'Arenales · Ceniza volcánica',
    acento: Color(0xFF2F363B),
    navegacion: Color(0xFF0B0D0E),
    fondo: Color(0xFFE7E9EA),
    encabezado: Color(0xFF1C2023),
    encabezadoTexto: Color(0xFFFFFFFF),
    linea: Color(0xFF5C656B),
    tinte: Color(0xFFC9CED1),
    marcaDeAgua: Colores.tinta,
  ),
  TemaEstacion(
    nombre: 'Valle Lunar · Roca y plata',
    acento: Color(0xFF5C4638),
    navegacion: Color(0xFF241B15),
    fondo: Color(0xFFF3F0ED),
    encabezado: Color(0xFFE4DFDA),
    encabezadoTexto: Colores.tinta,
    linea: Color(0xFF8F8279),
    tinte: Color(0xFFD8D0C9),
    marcaDeAgua: Color(0xFF4A3A2F),
  ),
  TemaEstacion(
    nombre: 'Valle de las Tumbas · Blanco glaciar',
    acento: Color(0xFF135A78),
    navegacion: Color(0xFF0C2A38),
    fondo: Color(0xFFF8FCFE),
    encabezado: Color(0xFFFFFFFF),
    encabezadoTexto: Colores.tinta,
    linea: Color(0xFF7FB6CE),
    tinte: Color(0xFFD6ECF5),
    marcaDeAgua: Color(0xFF135A78),
  ),
];

/// Da a todas las pantallas la paleta de la estación actual.
class TemaScope extends InheritedWidget {
  const TemaScope({super.key, required this.tema, required super.child});

  final TemaEstacion tema;

  /// Sin ámbito (por ejemplo en pruebas de una sola pantalla) se usa la primera paleta.
  static TemaEstacion of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TemaScope>()?.tema ?? temasEstacion.first;

  @override
  bool updateShouldNotify(TemaScope oldWidget) => tema != oldWidget.tema;
}
