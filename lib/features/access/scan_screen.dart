import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/access/access_controller.dart';
import '../../core/ui/palette.dart';

const _mensajes = {
  ResultadoPase.invalido: 'Ese código no es un pase válido.',
  ResultadoPase.vencido: 'Ese pase ya venció.',
  ResultadoPase.relojDesajustado: 'La hora del teléfono no coincide con la del pase. Revísala.',
};

/// Lee el QR de un pase con la cámara. El análisis se hace en el teléfono.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.access, this.camara = true});

  final AccessController access;

  /// En pruebas se desactiva porque no hay cámara.
  final bool camara;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _codigo = TextEditingController();
  String? _error;
  String? _ultimoLeido;
  bool _validando = false;

  Future<void> _activar(String codigo) async {
    if (_validando) return;
    _validando = true;
    final resultado = await widget.access.activar(codigo);
    _validando = false;
    if (!mounted) return;
    if (resultado == ResultadoPase.aceptado) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = _mensajes[resultado]);
    }
  }

  void _detectado(BarcodeCapture captura) {
    final valor = captura.barcodes.firstOrNull?.rawValue;
    // La cámara entrega el mismo código muchas veces: solo se valida al cambiar.
    if (valor == null || valor == _ultimoLeido) return;
    _ultimoLeido = valor;
    _activar(valor);
  }

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear pase')),
      body: ListView(
        padding: const EdgeInsets.all(Espacio.m),
        children: [
          if (widget.camara)
            SizedBox(
              height: 300,
              child: MobileScanner(
                onDetect: _detectado,
                errorBuilder: (context, error) => const Center(
                  child: Text(
                    'No se pudo usar la cámara. Concede el permiso en los ajustes del teléfono '
                    'o pega el código.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: Espacio.m),
            Text(_error!, style: const TextStyle(color: Colores.aviso, fontSize: 16)),
          ],
          const SizedBox(height: Espacio.m),
          TextField(
            controller: _codigo,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'O pega el código del pase',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Espacio.s),
          OutlinedButton(onPressed: () => _activar(_codigo.text), child: const Text('Usar código')),
        ],
      ),
    );
  }
}
