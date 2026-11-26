import '../ai/retriever.dart';

List<Fragment> parseMarkdownFragments(
  String markdown, {
  required String path,
  DateTime? today,
}) {
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final output = <Fragment>[];
  String section = '';
  String topic = '';
  String level = '';
  String topicDescription = '';
  List<String> stations = const [];
  String? title;
  String fragmentLevel = '';
  String fragmentDescription = '';
  final body = <String>[];
  // "Vence:" puede ir bajo el tema (##) o dentro del apartado.
  String? topicExpiry;

  void finish() {
    if (title == null) return;
    final sourceLine = body
        .where((line) => line.trimLeft().startsWith('Fuente:'))
        .join(' ');
    final source = sourceLine
        .replaceFirst(RegExp(r'^\s*Fuente:\s*'), '')
        .trim();
    final expiryLines = body.where(
      (line) => line.trimLeft().startsWith('Vence:'),
    );
    final expiryLine = expiryLines.isEmpty ? null : expiryLines.first;
    final expiry = _parseDate(
      expiryLine?.replaceFirst(RegExp(r'^\s*Vence:\s*'), '').trim() ??
          topicExpiry,
    );
    final now = today ?? DateTime.now();
    if (source.isEmpty ||
        (expiry != null &&
            expiry.isBefore(DateTime(now.year, now.month, now.day)))) {
      return;
    }
    final text = body
        .where(
          (line) =>
              !line.trimLeft().startsWith('Fuente:') &&
              !line.trimLeft().startsWith('Vence:'),
        )
        .join('\n')
        .trim();
    final pathParts = [
      section,
      topic,
      if (fragmentLevel.isNotEmpty) fragmentLevel,
      title!,
    ].where((part) => part.isNotEmpty).toList();
    output.add(
      Fragment(
        id: _slug(pathParts.join('/')),
        text: text,
        source: source,
        date: null,
        score: 0,
        path: pathParts.join(' > '),
        title: title!,
        description: [
          topicDescription,
          fragmentDescription,
        ].where((x) => x.isNotEmpty).join(' '),
        stations: stations,
        expires: expiry,
      ),
    );
  }

  void resetFragment(String nextTitle, String nextLevel) {
    finish();
    title = nextTitle;
    fragmentLevel = nextLevel;
    fragmentDescription = '';
    body.clear();
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#### ')) {
      resetFragment(trimmed.substring(5).trim(), level);
    } else if (trimmed.startsWith('### ')) {
      finish();
      title = null;
      level = trimmed.substring(4).trim();
    } else if (trimmed.startsWith('## ')) {
      finish();
      title = null;
      topic = trimmed.substring(3).trim();
      topicDescription = '';
      topicExpiry = null;
      stations = const [];
    } else if (trimmed.startsWith('# ')) {
      finish();
      title = null;
      section = trimmed.substring(2).trim();
      topic = '';
      topicDescription = '';
      stations = const [];
    } else if (trimmed.startsWith('> ')) {
      if (title == null) {
        topicDescription = trimmed.substring(2).trim();
      } else if (fragmentDescription.isEmpty) {
        fragmentDescription = trimmed.substring(2).trim();
      } else {
        body.add(trimmed.substring(2).trim());
      }
    } else if (trimmed.startsWith('Estaciones:')) {
      stations = trimmed
          .substring('Estaciones:'.length)
          .split(',')
          .map((station) => station.trim())
          .where((station) => station.isNotEmpty)
          .toList(growable: false);
    } else if (title == null && trimmed.startsWith('Vence:')) {
      topicExpiry = trimmed.substring('Vence:'.length).trim();
    } else if (title != null) {
      body.add(line);
    }
  }
  finish();
  return output;
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String _slug(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9áéíóúüñ]+'), '-')
    .replaceAll(RegExp(r'-+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');
