# Instalación y uso básico del modelo de IA

Fecha: 2026-11-25. Estado: diseño aprobado en conversación (opción A).

## Objetivo

Descargar un modelo en la app y usarlo en un chat básico en un teléfono real. Función experimental, solo para desarrollo.

## Decisiones

- Gemma 3 1B q4 (584 MB), según `Docs/pruebas/2026-11-25-prueba-llm-moto-g60.md`.
- `flutter_edge_ai` 2.7.2 y `flutter_edge_ai_litertlm` 1.21.3, versiones exactas.
- Token de Hugging Face con `--dart-define-from-file=.env`. Queda dentro del APK: no sirve para distribuir.
- Compatible: Android `arm64` con 3 500 000 kB de RAM total o más.
- CPU, `topK: 1`, ventana de 2048 tokens, respuesta de máximo 150 tokens, sin historial.

## Estructura

- `lib/core/ai/llm_engine.dart`: contrato.
- `lib/core/ai/edge_llm_engine.dart`: única parte que importa el paquete.
- `lib/core/ai/device_support.dart`: decide si el teléfono es compatible.
- `lib/features/chat/chat_controller.dart`: estado, compartido para que la descarga siga si se sale de la pantalla.
- `lib/features/chat/chat_screen.dart`: vista.

## Integridad

Antes de cargar, `model_integrity.dart` compara el SHA-256 del archivo con el del catálogo del paquete. Si coincide deja una marca junto al archivo y no recalcula. Si no coincide, borra el modelo y la pantalla pide descargarlo de nuevo.

## Estados de la pantalla

No compatible, sin modelo, descargando, cargando, listo y error con reintento. Un aviso fijo advierte que es experimental y puede dar información falsa.

## Fuera de alcance

RAG, embeddings, bloqueo de temas críticos, iOS, GPU, borrar o actualizar el modelo, revertir actualizaciones (RD-05).

## Verificación

Pruebas con un motor falso, `analyze`, compilación Android y web, y prueba manual en Moto G60.
