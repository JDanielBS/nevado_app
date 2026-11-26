import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import 'settings_card.dart';

/// Información del parque, privacidad y ajustes de la app.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.maybeOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Text('Acerca del parque', style: estiloTitulo(30)),
        const SizedBox(height: 12),
        const TarjetaTexto(
          titulo: 'PNN Los Nevados',
          texto: 'Área protegida en la Cordillera Central de Colombia, en los departamentos de Caldas, '
              'Risaralda, Quindío y Tolima.',
        ),
        const TarjetaTexto(
          titulo: 'Tu privacidad',
          texto: 'Esta guía no pide registro ni datos personales y funciona sin internet. '
              'Solo la descarga opcional del modelo de IA usa conexión.',
        ),
        const TarjetaTexto(
          titulo: 'Sobre el contenido',
          texto: 'Guía interpretativa de campo. No reemplaza las indicaciones del personal del parque.',
        ),
        if (scope != null && [...scope.emergencia.map((f) => f.verificada), ...scope.secciones.map((s) => s.verificada)].contains(false))
          const TarjetaTexto(
            titulo: 'Contenido de demostración',
            texto: 'El contenido aún no está verificado. No lo uses para tomar decisiones de seguridad.',
            color: Colores.avisoFondo,
            borde: Colores.aviso,
          ),
        if (scope != null) SettingsCard(settings: scope.settings),
      ],
    );
  }
}
