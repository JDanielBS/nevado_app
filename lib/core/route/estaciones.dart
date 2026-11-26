/// Estaciones del recorrido habilitado y su contenido interpretativo.
///
/// Las fotos viven en `assets/imagenes/<carpeta>/`. Mientras no estén cargadas,
/// la app muestra un espacio vacío con el nombre de la foto pendiente.
library;

/// Carpeta raíz de las fotos de la ruta.
const carpetaImagenes = 'assets/imagenes';

/// Nombres de archivo que se esperan en la carpeta de cada estación.
abstract final class Fotos {
  /// Panorámica del lugar. También se usa como marca de agua de la estación.
  static const paisaje = 'paisaje.png';
  static const geologia = 'geologia.png';
  static const floraFrailejon = 'flora_frailejon.png';
  static const floraCojin = 'flora_cojin.png';
  static const fauna = 'fauna.png';
}

class Estacion {
  const Estacion({
    required this.nombre,
    required this.carpeta,
    required this.altitud,
    required this.ecosistema,
    required this.fichas,
  });

  final String nombre;

  /// Subcarpeta de [carpetaImagenes] con las fotos de esta estación.
  final String carpeta;

  /// Metros sobre el nivel del mar (aproximado). `null` si no hay dato confirmado.
  final int? altitud;
  final String ecosistema;

  /// Contenido propio de cada pestaña de la ficha, basado en los guiones del parque
  /// (`assets/content/Guion Ecoturistico UTON 2024.md` y `Guion turistico zona norte.md`).
  final Map<Pestana, Ficha> fichas;

  String get textoAltitud =>
      altitud == null ? '[ALTITUD POR CONFIRMAR]' : '≈ ${formatoMiles(altitud!)} m s. n. m.';

  String foto(String archivo) => '$carpetaImagenes/$carpeta/$archivo';
  String get fotoPaisaje => foto(Fotos.paisaje);
}

/// Contenido de una pestaña: fotos (archivo de [Fotos] y lo que muestra) y tarjetas (título, texto).
/// La primera foto va arriba; la segunda, si la hay, después de la primera tarjeta.
typedef Ficha = ({List<(String, String)> fotos, List<(String, String)> textos});

/// 4100 → "4.100".
String formatoMiles(int valor) {
  final texto = valor.toString();
  final grupos = <String>[];
  for (var fin = texto.length; fin > 0; fin -= 3) {
    grupos.insert(0, texto.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
  }
  return grupos.join('.');
}

const estaciones = <Estacion>[
  Estacion(
    nombre: 'Brisas',
    carpeta: '01_brisas',
    altitud: 4100,
    ecosistema: 'Páramo',
    fichas: {
      Pestana.geologia: (
        fotos: [(Fotos.geologia, 'Flanco norte del Complejo Volcánico Nevado del Ruiz')],
        textos: [
          ('Puerta del volcán',
              'Brisas está en el flanco norte del Complejo Volcánico Nevado del Ruiz, formado por cuatro estructuras: Nereidas, Olleta, Piraña y Arenas, el cráter activo.'),
          ('Un volcán vivo',
              'El Ruiz no está apagado: tiene actividad constante y periodos de reposo. El Servicio Geológico Colombiano lo vigila las 24 horas.'),
        ],
      ),
      Pestana.flora: (
        fotos: [(Fotos.floraCojin, 'Pajonal y suelo de páramo en Brisas')],
        textos: [
          ('Una esponja de agua',
              'El suelo, de origen volcánico, retiene hasta 40 veces su peso en agua y la libera poco a poco hacia los ríos.'),
          ('Páramo protegido',
              'De las 62.142 hectáreas del parque, 53.532 son páramo: el 86 % del área protegida.'),
        ],
      ),
      Pestana.fauna: (
        fotos: [(Fotos.fauna, 'Fauna de páramo cerca de Brisas')],
        textos: [
          ('Vida a 2 °C',
              'La temperatura media anual en Brisas es de unos 2,2 °C, con niebla frecuente y viento fuerte. La fauna que vive aquí está adaptada a ese frío.'),
          ('Colibríes de altura',
              'Algunos colibríes del páramo reducen casi al mínimo su actividad durante la noche para ahorrar energía y sobrevivir al frío.'),
        ],
      ),
      Pestana.historia: (
        fotos: [(Fotos.paisaje, 'Panorámica desde Brisas')],
        textos: [
          ('Kumanday',
              'Así llamaban al volcán los pueblos indígenas: "Cerro Blanco", "El de la Nariz Humeante" o "Padre Blanco". Era una montaña sagrada.'),
          ('Agua para el Eje Cafetero',
              'El parque abastece de agua a 37 municipios y a cerca de 3 millones de personas.'),
        ],
      ),
    },
  ),
  Estacion(
    nombre: 'Aguacerales',
    carpeta: '02_aguacerales',
    altitud: 4160,
    ecosistema: 'Páramo propiamente dicho',
    fichas: {
      Pestana.geologia: (
        fotos: [(Fotos.geologia, 'Escarpes de lava y valle en U de Aguacerales')],
        textos: [
          ('Tallado por el hielo',
              'Al retroceder, el glaciar cortó las lavas como un cuchillo gigante: así se formaron los escarpes que rodean la estación y el valle en U al occidente.'),
          ('Rocas de 100.000 años',
              'Las rocas cercanas son andesitas, la roca más común de los Andes. Al noroccidente asoman rocas de 1,8 millones de años, del antiguo "Pre Ruiz".'),
        ],
      ),
      Pestana.flora: (
        fotos: [
          (Fotos.floraFrailejon, 'Frailejón (Espeletia hartwegiana)'),
          (Fotos.floraCojin, 'Musgos sobre la roca que captan la niebla'),
        ],
        textos: [
          ('El agua se atrapa',
              'Aquí la vegetación captura el agua de las nubes. Las gotas pasan a los musgos y forman hilos que alimentan la cuenca del río Chinchiná, día y noche.'),
          ('Espeletia hartwegiana',
              'Es la única especie de frailejón reportada en el parque. Sus pelos blancos lo protegen de la radiación y su "chaqueta" de hojas muertas lo aísla del frío.'),
        ],
      ),
      Pestana.fauna: (
        fotos: [(Fotos.fauna, 'Danta de montaña u otra fauna de Aguacerales')],
        textos: [
          ('La estación más viva',
              'En este páramo se han visto conejos, venados, cusumbos, tairas, zorros, pumas, dantas, colibríes y águilas.'),
          ('La jardinera del páramo',
              'La danta de montaña es un mamífero lanudo que dispersa semillas por el páramo mientras se alimenta.'),
        ],
      ),
      Pestana.historia: (
        fotos: [(Fotos.paisaje, 'Panorámica de Aguacerales')],
        textos: [
          ('¿Por qué Aguacerales?',
              'Por la caída de agua que se ve y se oye sin parar. En noches frías los hilos de agua se congelan y forman carámbanos.'),
          ('10.000 años de historia',
              'Los páramos han sido habitados por comunidades humanas desde hace unos 10.000 años.'),
        ],
      ),
    },
  ),
  Estacion(
    nombre: 'Arenales',
    carpeta: '03_arenales',
    altitud: 4290,
    ecosistema: 'Transición de páramo a superpáramo',
    fichas: {
      Pestana.geologia: (
        fotos: [(Fotos.geologia, 'Dunas de arena volcánica de Arenales')],
        textos: [
          ('Dunas de altura',
              'El viento acumula arena y ceniza contra la barrera de rocas tras la cabaña. Las dunas tendrían entre 200 y 400 años y reposan sobre lavas de unos 100.000 años.'),
          ('Rocas que dejó el glaciar',
              'Las rocas enormes junto a la quebrada no las lanzó el volcán: las dejó el glaciar al retroceder. En el suelo hay piroclastos de la erupción de 1989.'),
        ],
      ),
      Pestana.flora: (
        fotos: [(Fotos.floraCojin, 'Pajonal, loricarias y colchones de agua')],
        textos: [
          ('Del páramo al superpáramo',
              'Aquí el verde da paso al gris. Pajonales, loricarias y colchones de agua resisten en un suelo pobre y ácido.'),
          ('Vegetación pionera',
              'Plantas muy pequeñas intentan colonizar la arena volcánica: son la prueba de que la vida resiste en el límite.'),
        ],
      ),
      Pestana.fauna: (
        fotos: [(Fotos.fauna, 'Huellas de fauna en la arena')],
        textos: [
          ('Huellas en la arena',
              'En Arenales se ven conejos, águilas y, a veces, huellas de tigrillo.'),
          ('No dejes tu huella',
              'Las dunas son patrimonio geológico intangible. Cuando están húmedas, una pisada puede durar meses: camina solo por el sendero.'),
        ],
      ),
      Pestana.historia: (
        fotos: [(Fotos.paisaje, 'Cabaña y paisaje de Arenales')],
        textos: [
          ('Esquí en el Ruiz',
              'En los años 50 y 60 hubo aquí campeonatos sudamericanos de esquí que dieron origen al Club de Ski de Manizales. El deshielo acabó con esa actividad.'),
          ('Del chalet a la cabaña',
              'Aquí hubo una bodega de papa en 1937 y luego el Chalet Arenales, obra de Simón Vélez, que se incendió en 2010.'),
        ],
      ),
    },
  ),
  Estacion(
    nombre: 'Valle Lunar',
    carpeta: '04_valle_lunar',
    altitud: 4350,
    ecosistema: 'Superpáramo',
    fichas: {
      Pestana.geologia: (
        fotos: [(Fotos.geologia, 'Rocas fracturadas y rojizas del Valle Lunar')],
        textos: [
          ('Rocas rotas por el hielo',
              'El agua entra en las grietas, se congela de noche y aumenta de volumen: actúa como una cuña que parte la roca. Se llama gelifracción.'),
          ('Rojo de hierro',
              'Los tonos rojizos vienen de la oxidación del hierro de minerales como la hornblenda al contacto con el oxígeno y la humedad.'),
          ('Minerales a simple vista',
              'En la andesita, los cristales claros son plagioclasas y los negros, hornblendas.'),
        ],
      ),
      Pestana.flora: (
        fotos: [(Fotos.floraCojin, 'Loricaria o "coral de páramo"')],
        textos: [
          ('Coral de páramo',
              'La loricaria, también llamada cacho de venado, es de las pocas plantas que resisten estas condiciones extremas.'),
          ('Un valle que reverdece',
              'Hace unos 100 años aquí no había vegetación. Las grietas de la roca forman suelo arenoso y la vida pionera avanza.'),
        ],
      ),
      Pestana.fauna: (
        fotos: [(Fotos.fauna, 'Cóndor andino (Vultur gryphus)')],
        textos: [
          ('Zona de paso',
              'Casi no hay vegetación, así que pocos animales viven aquí. El cóndor y las águilas lo cruzan en vuelo.'),
          ('Cóndor andino',
              'Planea sin esfuerzo aprovechando las corrientes de aire caliente. Verlo no está garantizado: si aparece, obsérvalo en silencio.'),
        ],
      ),
      Pestana.historia: (
        fotos: [(Fotos.paisaje, 'Panorámica del Valle Lunar')],
        textos: [
          ('¿Por qué "lunar"?',
              'Por su aspecto estéril y desolado, que recuerda la superficie de otros planetas.'),
          ('Arañazos del glaciar',
              'Las marcas como rayones en las rocas son estrías glaciares: muestran hacia dónde se movía el hielo que cubrió este valle.'),
        ],
      ),
    },
  ),
  Estacion(
    nombre: 'Valle de las Tumbas',
    carpeta: '05_valle_de_las_tumbas',
    altitud: 4460,
    ecosistema: 'Superpáramo con transición a zona nival',
    fichas: {
      Pestana.geologia: (
        fotos: [(Fotos.geologia, 'Lavas superpuestas y circo glaciar')],
        textos: [
          ('Cerca del cráter',
              'Estás a unos 4 km del cráter Arenas. Las andesitas de este valle provienen sobre todo del volcán Nereidas y tienen más de 80.000 años.'),
          ('¿Por qué no se sigue?',
              'Más arriba, el riesgo de lahares (flujos de lodo y escombros) dificultaría una evacuación. Por eso el recorrido termina aquí.'),
        ],
      ),
      Pestana.flora: (
        fotos: [(Fotos.floraCojin, 'Pastos colonizadores, musgos y líquenes')],
        textos: [
          ('El límite de la vida',
              'Solo pastos colonizadores, musgos y líquenes logran crecer sobre la roca que dejó el glaciar.'),
          ('Frío cada noche',
              'Entre el día y la noche la temperatura cambia tanto que las plantas necesitan estrategias extremas para no congelarse.'),
        ],
      ),
      Pestana.fauna: (
        fotos: [(Fotos.fauna, 'Cóndor o águila sobre el Valle de las Tumbas')],
        textos: [
          ('Cielo de cóndores',
              'Aquí casi no hay fauna residente: el cóndor y las águilas solo están de paso, aprovechando el viento.'),
          ('Observa sin intervenir',
              'No alimentes, llames ni persigas animales. En este ecosistema cualquier alteración tarda años en recuperarse.'),
        ],
      ),
      Pestana.historia: (
        fotos: [(Fotos.paisaje, 'Panorámica del Valle de las Tumbas')],
        textos: [
          ('Lajas como ataúdes',
              'El nombre viene de rocas largas y planas parecidas a ataúdes. También se le llama "Desierto de la Soledad".'),
          ('Montaña sagrada',
              'Quimbayas, Carrapas, Gualíes, Panches, Ansermas y Pijaos peregrinaban para honrar al Kumanday. Hoy algunas comunidades aún hacen rituales aquí.'),
          ('Armero, 1985',
              'El 13 de noviembre de 1985 la erupción derritió parte del glaciar. Los lahares bajaron por varios ríos y causaron más de 23.000 muertes.'),
        ],
      ),
    },
  ),
];

enum Pestana {
  geologia('Geología y volcán'),
  flora('Flora de páramo'),
  fauna('Fauna adaptada'),
  historia('Paisaje e historia');

  const Pestana(this.etiqueta);
  final String etiqueta;
}

sealed class Bloque {
  const Bloque();
}

class BloqueFoto extends Bloque {
  const BloqueFoto(this.ruta, this.pie);

  /// Ruta del recurso dentro de la app.
  final String ruta;

  /// Qué debe mostrar la foto. Se ve mientras la foto no esté cargada.
  final String pie;
}

class BloqueTexto extends Bloque {
  const BloqueTexto(this.titulo, this.texto, {this.pendiente = false});
  final String titulo;
  final String texto;

  /// Texto aún por validar con el parque.
  final bool pendiente;
}

/// Bloques de una pestaña de la ficha, con el texto y las fotos propios de la estación.
List<Bloque> contenidoDe(Estacion e, Pestana p) {
  final ficha = e.fichas[p]!;
  final fotos = [for (final (archivo, pie) in ficha.fotos) BloqueFoto(e.foto(archivo), pie)];
  final textos = [for (final (titulo, texto) in ficha.textos) BloqueTexto(titulo, texto)];
  return [...fotos.take(1), ...textos.take(1), ...fotos.skip(1), ...textos.skip(1)];
}
