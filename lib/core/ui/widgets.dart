import 'package:flutter/material.dart';

import '../content/card.dart';
import '../settings/battery_saver.dart';
import '../settings/settings.dart';
import 'palette.dart';

/// Tarjeta blanca con borde, usada en todas las pantallas.
class Caja extends StatelessWidget {
  const Caja({
    super.key,
    required this.child,
    this.color = Colores.superficie,
    this.borde = Colores.borde,
    this.margen = true,
  });

  final Widget child;
  final Color color;
  final Color borde;

  /// Deja espacio debajo para separarla de la siguiente.
  final bool margen;

  // Se usa Material (no un fondo decorado) para que los controles internos muestren su efecto al tocarlos.
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: margen ? 10 : 0),
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borde, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      );
}

/// Tarjeta con título condensado y un párrafo, como las del mockup.
class TarjetaTexto extends StatelessWidget {
  const TarjetaTexto({
    super.key,
    required this.titulo,
    required this.texto,
    this.color = Colores.superficie,
    this.borde = Colores.borde,
  });

  final String titulo;
  final String texto;
  final Color color;
  final Color borde;

  @override
  Widget build(BuildContext context) => Caja(
        color: color,
        borde: borde,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(titulo, style: estiloTitulo(21)),
            Text(texto, style: const TextStyle(fontSize: 15, height: 1.45, color: Colores.texto)),
          ],
        ),
      );
}

/// Botón relleno con el color de acento de la estación.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({super.key, required this.texto, required this.onPressed});

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: tema.acento,
        foregroundColor: Colors.white,
        disabledBackgroundColor: tema.acento.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(altoMinimo, altoMinimo),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: Fuentes.cuerpo, fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(texto, textAlign: TextAlign.center),
    );
  }
}

/// Botón blanco con borde de tinta.
class BotonSecundario extends StatelessWidget {
  const BotonSecundario({super.key, required this.texto, required this.onPressed});

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colores.superficie,
          foregroundColor: Colores.tinta,
          side: const BorderSide(color: Colores.tinta, width: 2),
          minimumSize: const Size(altoMinimo, altoMinimo),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: Fuentes.cuerpo, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: Text(texto, textAlign: TextAlign.center),
      );
}

/// Foto local del parque. Mientras el archivo no exista deja el espacio reservado
/// con la descripción de la foto que falta.
class FotoLocal extends StatelessWidget {
  const FotoLocal({super.key, required this.ruta, required this.pie, this.alto = 160});

  final String ruta;
  final String pie;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        image: true,
        label: pie,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: alto,
            width: double.infinity,
            child: Image.asset(
              ruta,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stack) => _EspacioFoto(pie: pie),
            ),
          ),
        ),
      ),
    );
  }
}

class _EspacioFoto extends StatelessWidget {
  const _EspacioFoto({required this.pie});
  final String pie;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colores.fotoFondo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colores.bordeFuerte, width: 2),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'FOTO PENDIENTE DE CARGAR\n$pie',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colores.fotoTexto),
            ),
          ),
        ),
      );
}

/// Marca de agua de la estación: su foto de paisaje teñida con el color de la paleta y
/// desvanecida hacia arriba. Si la foto aún no está cargada no se dibuja nada.
class MarcaDeAgua extends StatelessWidget {
  const MarcaDeAgua({super.key, required this.ruta, required this.color});

  final String ruta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: 0.17,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black, Colors.black],
              stops: [0, 0.45, 1],
            ).createShader(rect),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.color),
              child: Image.asset(
                ruta,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso de modo ahorro visible arriba de todas las pantallas.
class AvisoAhorro extends StatelessWidget {
  const AvisoAhorro({super.key, required this.ajustes});

  final Ajustes ajustes;

  @override
  Widget build(BuildContext context) {
    final motivo = ajustes.motivoAhorro;
    if (!ajustes.ahorroActivo || motivo == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: Espacio.m),
        decoration: const BoxDecoration(
          color: Colores.avisoFondo,
          border: Border(bottom: BorderSide(color: Colores.aviso, width: 2)),
        ),
        child: Text(
          'Modo ahorro activo. ${textoMotivo[motivo]}',
          style: const TextStyle(color: Colores.aviso, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class FichaTarjeta extends StatelessWidget {
  const FichaTarjeta({super.key, required this.ficha});

  final Ficha ficha;

  @override
  Widget build(BuildContext context) {
    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (etiquetaCategoria[ficha.categoria] ?? ficha.categoria.name).toUpperCase(),
            style: TextStyle(fontSize: 12, color: TemaScope.of(context).acento, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(ficha.titulo, style: estiloTitulo(21)),
          const SizedBox(height: 6),
          Text(ficha.texto, style: const TextStyle(fontSize: 15, color: Colores.texto, height: 1.45)),
          const SizedBox(height: Espacio.s),
          Text('Fuente: ${ficha.fuente}', style: const TextStyle(fontSize: 12, color: Colores.textoSuave)),
          const SizedBox(height: 2),
          Text(
            ficha.verificada ? 'Verificada el ${ficha.fechaVerificacion}' : 'Contenido de demostración, sin verificar',
            style: TextStyle(fontSize: 12, color: ficha.verificada ? Colores.textoSuave : Colores.aviso),
          ),
        ],
      ),
    );
  }
}

/// Párrafo simple.
class Linea extends StatelessWidget {
  const Linea(this.texto, {super.key, this.color = Colores.texto, this.negrita = false, this.tamano = 15});
  final String texto;
  final Color color;
  final bool negrita;
  final double tamano;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: tamano,
            color: color,
            height: 1.45,
            fontWeight: negrita ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      );
}
