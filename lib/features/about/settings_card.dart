import 'package:flutter/material.dart';

import '../../core/settings/battery_saver.dart';
import '../../core/settings/settings.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';

/// Tamaño de texto, voz y modo ahorro de batería.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.settings});

  final Ajustes settings;

  @override
  Widget build(BuildContext context) {
    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ajustes', style: estiloTitulo(21)),
          const SizedBox(height: 6),
          const Linea('Tamaño del texto', negrita: true),
          Wrap(
            spacing: Espacio.s,
            runSpacing: Espacio.s,
            children: [
              for (final scale in escalasTexto.entries)
                ChoiceChip(
                  label: Text(scale.value),
                  selected: settings.escala == scale.key,
                  selectedColor: TemaScope.of(context).tinte,
                  side: const BorderSide(color: Colores.bordeFuerte, width: 2),
                  onSelected: (_) => settings.escala = scale.key,
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Respuestas con voz'),
            subtitle: const Text('La Guía IA lee en voz alta lo que escribe el modelo. El modo ahorro la apaga.'),
            value: settings.vozActiva,
            activeTrackColor: TemaScope.of(context).acento,
            onChanged: (value) => settings.vozActiva = value,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Modo ahorro de batería'),
            subtitle: Text(
                'Batería: ${porcentaje(settings.nivelBateria)}. Se activa solo con 20 % o menos; puedes desactivarlo.'),
            value: settings.ahorroActivo,
            activeTrackColor: TemaScope.of(context).acento,
            onChanged: settings.elegirAhorro,
          ),
          if (settings.ahorroActivo) ...const [
            Linea('Para cuidar la batería:'),
            Linea('• Baja el brillo de la pantalla.'),
            Linea('• Activa el modo avión: esta guía no necesita señal.'),
            Linea('• Pide la ubicación solo cuando la necesites.'),
            Linea('• El mapa se abre sin relieve 3D.'),
            Linea('• El asistente responde solo con búsqueda local, sin modelo de IA.'),
          ],
        ],
      ),
    );
  }
}
