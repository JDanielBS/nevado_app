import 'package:flutter/material.dart';

import '../../core/access/access_controller.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import 'access_scope.dart';
import 'scan_screen.dart';

String mensajeAcceso(EstadoAcceso estado) => switch (estado) {
  EstadoAcceso.comprobando => 'Comprobando el pase…',
  EstadoAcceso.sinPase => 'Escanea el pase del recorrido para usar la guía.',
  EstadoAcceso.activo => 'Pase activo.',
  EstadoAcceso.vencido => 'El pase venció. Pide uno nuevo al personal del parque.',
  EstadoAcceso.relojAtrasado =>
    'La hora del teléfono cambió. Activa la hora automática o pide un pase nuevo.',
};

/// "04:59" o "11 h 05 min".
String describirRestante(Duration restante) {
  String dos(int n) => n.toString().padLeft(2, '0');
  if (restante.inHours > 0) return '${restante.inHours} h ${dos(restante.inMinutes % 60)} min';
  return '${dos(restante.inMinutes)}:${dos(restante.inSeconds % 60)}';
}

/// Muestra [child] solo con un pase vigente. Al vencer, reemplaza la pantalla abierta.
class AccessGate extends StatelessWidget {
  const AccessGate({super.key, this.title, required this.child});

  /// Título de la barra cuando [child] es una pantalla completa. Las secciones no lo usan.
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final access = AccessScope.maybeOf(context);
    if (access == null || access.activo) return child;
    final aviso = ListView(padding: const EdgeInsets.all(Espacio.m), children: const [AccessCard()]);
    final titulo = title;
    return titulo == null ? aviso : Scaffold(appBar: AppBar(title: Text(titulo)), body: SafeArea(child: aviso));
  }
}

/// Estado del pase y botón para escanear uno.
class AccessCard extends StatelessWidget {
  const AccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    final access = AccessScope.maybeOf(context);
    if (access == null) return const SizedBox.shrink();
    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloCaja('Pase del recorrido'),
          Linea(mensajeAcceso(access.estado), tamano: 16),
          if (access.activo) Linea('Tiempo restante: ${describirRestante(access.restante)}', negrita: true),
          if (!access.activo) const Linea('La sección Seguridad funciona sin pase.'),
          const SizedBox(height: Espacio.s),
          FilledButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(access.activo ? 'Escanear otro pase' : 'Escanear pase'),
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => ScanScreen(access: access))),
          ),
        ],
      ),
    );
  }
}
