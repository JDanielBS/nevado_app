import 'package:flutter/widgets.dart';

import '../../core/access/access_controller.dart';

/// Da acceso al control de pases desde cualquier pantalla y la redibuja cuando cambia.
class AccessScope extends InheritedNotifier<AccessController> {
  const AccessScope({super.key, required AccessController controller, required super.child})
    : super(notifier: controller);

  /// `null` cuando la app o una pantalla se montan sin control de acceso, como en las pruebas.
  static AccessController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccessScope>()?.notifier;
}
