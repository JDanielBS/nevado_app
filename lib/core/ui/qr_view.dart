import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Código QR dibujado en la app, sin internet ni imágenes.
class QrView extends StatelessWidget {
  const QrView({super.key, required this.datos, this.lado = 260, this.etiqueta});

  final String datos;
  final double lado;

  /// Texto para lectores de pantalla.
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final imagen = QrImage(QrCode(payload: QrPayload.fromString(datos), errorCorrectLevel: QrErrorCorrectLevel.low));
    return Semantics(
      label: etiqueta ?? 'Código QR',
      image: true,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: SizedBox.square(dimension: lado, child: CustomPaint(painter: _PintorQr(imagen))),
      ),
    );
  }
}

class _PintorQr extends CustomPainter {
  _PintorQr(this.imagen);
  final QrImage imagen;

  @override
  void paint(Canvas canvas, Size size) {
    final n = imagen.moduleCount;
    final m = size.width / n;
    final negro = Paint()..color = Colors.black;
    for (var fila = 0; fila < n; fila++) {
      for (var col = 0; col < n; col++) {
        if (imagen.isDark(fila, col)) canvas.drawRect(Rect.fromLTWH(col * m, fila * m, m + 0.3, m + 0.3), negro);
      }
    }
  }

  @override
  bool shouldRepaint(_PintorQr old) => old.imagen != imagen;
}
