import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/content/card_repository.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';

/// Seguridad y normas del recorrido. Contenido fijo, sin búsqueda ni modelo: siempre disponible.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencias = fichasDeEmergencia(AppScope.maybeOf(context)?.cards ?? const []);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Text('Seguridad y normas', style: estiloTitulo(30)),
        const SizedBox(height: 12),
        const TarjetaTexto(
          titulo: 'Ceniza o gases',
          texto: 'Avisa al guía. Cubre nariz y boca, protege tus ojos, regresa al vehículo y sigue las '
              'instrucciones de evacuación del personal.',
          color: Colores.avisoFondo,
          borde: Colores.aviso,
        ),
        const TarjetaTexto(
          titulo: 'Mal de altura',
          texto: 'Camina despacio e hidrátate. Si sientes dolor de cabeza, mareo, náuseas, ahogo o confusión, '
              'avisa de inmediato: lo más importante es descender.',
          color: Colores.avisoFondo,
          borde: Colores.aviso,
        ),
        const TarjetaTexto(
          titulo: 'No salgas del sendero',
          texto: 'Baja del vehículo solo en las paradas autorizadas y sigue siempre al guía.',
        ),
        const TarjetaTexto(
          titulo: 'No extraigas nada',
          texto: 'Deja rocas, ceniza, plantas y cualquier elemento natural en su lugar.',
        ),
        const TarjetaTexto(
          titulo: 'Cuida el páramo',
          texto: 'Llévate tus residuos. No uses drones ni plásticos de un solo uso. No alimentes fauna.',
        ),
        const TarjetaTexto(
          titulo: 'Estado del volcán',
          texto: 'Esta aplicación no tiene datos en tiempo real. La palabra del personal del parque prevalece siempre.',
          borde: Colores.tinta,
        ),
        const SizedBox(height: 6),
        Text('En una emergencia', style: estiloTitulo(24)),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colores.tinta, borderRadius: BorderRadius.circular(14)),
          child: const Text(
            'Esta guía no es un servicio de emergencias. Busca a un guía o funcionario del parque.',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.4),
          ),
        ),
        for (final ficha in emergencias) FichaTarjeta(ficha: ficha),
      ],
    );
  }
}
