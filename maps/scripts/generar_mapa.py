"""Genera los datos del mapa 3D del sector del Nevado del Ruiz.

Uso (desde la carpeta maps/):
    ~/herramientas/mapas-venv/bin/python scripts/generar_mapa.py

Salidas en maps/salida/:
    limite_pnn.geojson     límite del parque (WDPA)
    vias.geojson           vías y senderos de OpenStreetMap con altitud del DEM
    agua.geojson           ríos, quebradas y cuerpos de agua
    puntos.geojson         picos, localidades y sitios turísticos
    curvas.geojson         curvas de nivel cada 100 m
    elevacion/{z}/{x}/{y}.png   teselas de elevación en formato Terrarium
    senderos_3500.md       listado de senderos por encima de 3.500 m
"""

import json
import math
from pathlib import Path

import numpy as np
import osmium
import pyogrio
import rasterio
import shapely
from PIL import Image
from pyproj import Geod
from rasterio.merge import merge
from rasterio.transform import from_bounds
from rasterio.warp import Resampling, reproject
from skimage import measure

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "salida"
PBF = RAIZ / "geofabrik" / "colombia-261124.osm.pbf"
GDB = RAIZ / "WDPA_WDOECM_NOV2026" / "WDPA_WDOECM_Nov2026_Public_147.gdb"
CAPA_LIMITE = "WDPA_WDOECM_poly_Nov2026_147"

OESTE, SUR, ESTE, NORTE = -75.45, 4.75, -75.20, 5.10
CAJA = shapely.box(OESTE, SUR, ESTE, NORTE)
UMBRAL_ALTITUD = 3500
INTERVALO_CURVAS = 100
ZOOM_ELEVACION = range(10, 13)
# Altitud plana asignada a todo lo que queda fuera de la zona.
ALTITUD_BASE = 1800
GEOD = Geod(ellps="WGS84")

TIPOS_SENDERO = {"path", "footway", "track", "bridleway", "steps"}


def redondear(coords):
    return [[round(float(x), 6), round(float(y), 6)] for x, y in coords]


def geometria(geom):
    return json.loads(shapely.to_geojson(shapely.set_precision(geom, 1e-6)))


def guardar(nombre, elementos):
    ruta = SALIDA / nombre
    ruta.write_text(
        json.dumps({"type": "FeatureCollection", "features": elementos}, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"{nombre}: {len(elementos)} elementos, {ruta.stat().st_size / 1024:.0f} KB")


def elemento(geom, propiedades):
    return {"type": "Feature", "geometry": geom, "properties": propiedades}


def cargar_dem():
    rutas = sorted((RAIZ / "dem").glob("*.tif"))
    fuentes = [rasterio.open(r) for r in rutas]
    datos, transformada = merge(fuentes)
    crs = fuentes[0].crs
    for f in fuentes:
        f.close()
    return datos[0].astype("float32"), transformada, crs


def muestrear(dem, transformada, puntos):
    inversa = ~transformada
    alturas = []
    for lon, lat in puntos:
        columna, fila = inversa * (lon, lat)
        fila, columna = int(fila), int(columna)
        if 0 <= fila < dem.shape[0] and 0 <= columna < dem.shape[1]:
            alturas.append(float(dem[fila, columna]))
    return alturas


def exportar_limite():
    meta, _, geometrias, campos = pyogrio.raw.read(GDB, layer=CAPA_LIMITE)
    union = shapely.union_all(shapely.from_wkb(geometrias))
    nombres = list(meta["fields"])
    nombre = str(campos[nombres.index("NAME")][0])
    # Se exporta solo la línea del límite dentro de la zona, sin cerrar el polígono en los bordes.
    borde = shapely.intersection(union.boundary, CAJA)
    guardar(
        "limite_pnn.geojson",
        [elemento(geometria(borde), {"nombre": nombre, "fuente": "WDPA, noviembre de 2026"})],
    )
    guardar("area_pnn.geojson", [elemento(geometria(shapely.intersection(union, CAJA)), {"nombre": nombre})])
    return union


def densificar(coords, paso=0.0003):
    linea = shapely.segmentize(shapely.LineString(coords), paso)
    return list(linea.coords)


def extraer_osm(dem, transformada, limite):
    vias, agua, puntos, senderos = [], [], [], []
    claves = osmium.filter.KeyFilter("highway", "waterway", "natural", "place", "tourism")
    lector = osmium.FileProcessor(str(PBF)).with_locations().with_filter(claves)
    for objeto in lector:
        etiquetas = {t.k: t.v for t in objeto.tags}
        nombre = etiquetas.get("name", "")
        if objeto.is_node():
            lon, lat = objeto.location.lon, objeto.location.lat
            if not (OESTE <= lon <= ESTE and SUR <= lat <= NORTE):
                continue
            tipo = None
            if etiquetas.get("natural") in {"peak", "volcano", "hot_spring", "saddle"}:
                tipo = etiquetas["natural"]
            elif etiquetas.get("tourism") in {
                "alpine_hut", "wilderness_hut", "camp_site", "viewpoint", "information", "hotel"
            }:
                tipo = etiquetas["tourism"]
            elif etiquetas.get("place") in {"village", "hamlet", "locality"}:
                tipo = etiquetas["place"]
            if tipo and nombre:
                altura = muestrear(dem, transformada, [(lon, lat)])
                puntos.append(
                    elemento(
                        {"type": "Point", "coordinates": [round(lon, 6), round(lat, 6)]},
                        {"nombre": nombre, "tipo": tipo, "altitud": round(altura[0]) if altura else None},
                    )
                )
            continue
        if not objeto.is_way():
            continue
        coords = [(n.lon, n.lat) for n in objeto.nodes if n.location.valid()]
        if len(coords) < 2:
            continue
        recorte = shapely.intersection(shapely.LineString(coords), CAJA)
        if recorte.is_empty:
            continue
        partes = [p for p in shapely.get_parts(recorte) if p.geom_type == "LineString"]
        for parte in partes:
            tramo = list(parte.coords)
            if "highway" in etiquetas:
                clase = etiquetas["highway"]
                densa = densificar(tramo)
                alturas = muestrear(dem, transformada, densa)
                if not alturas:
                    continue
                props = {
                    "id_osm": objeto.id,
                    "nombre": nombre,
                    "tipo": clase,
                    "altitud_min": round(min(alturas)),
                    "altitud_max": round(max(alturas)),
                }
                vias.append(elemento({"type": "LineString", "coordinates": redondear(tramo)}, props))
                if clase in TIPOS_SENDERO and max(alturas) >= UMBRAL_ALTITUD:
                    senderos.append(
                        {
                            **props,
                            "km": GEOD.geometry_length(parte) / 1000,
                            "dentro": bool(shapely.intersects(limite, parte)),
                        }
                    )
            elif "waterway" in etiquetas:
                agua.append(
                    elemento(
                        {"type": "LineString", "coordinates": redondear(tramo)},
                        {"nombre": nombre, "tipo": etiquetas["waterway"]},
                    )
                )
        # Los cuerpos de agua formados por una sola vía cerrada se exportan como polígono.
        if etiquetas.get("natural") in {"water", "glacier"} and coords[0] == coords[-1] and len(coords) >= 4:
            poligono = shapely.make_valid(shapely.Polygon(coords))
            agua.append(elemento(geometria(poligono), {"nombre": nombre, "tipo": etiquetas["natural"]}))
    guardar("vias.geojson", vias)
    guardar("agua.geojson", agua)
    guardar("puntos.geojson", puntos)
    return senderos, puntos


def informe_senderos(senderos):
    senderos.sort(key=lambda s: (not s["dentro"], -s["altitud_max"]))
    lineas = [
        f"# Senderos por encima de {UMBRAL_ALTITUD} m (OpenStreetMap, sin verificar)",
        "",
        f"Zona: oeste {OESTE}, sur {SUR}, este {ESTE}, norte {NORTE}. "
        "Datos de OpenStreetMap (ODbL); altitudes calculadas con Copernicus DEM GLO-30.",
        "La presencia de un trazado en este listado no indica que esté abierto ni que sea seguro.",
        "",
        f"Total: {len(senderos)} tramos, {sum(s['km'] for s in senderos):.1f} km. "
        f"Dentro o en contacto con el parque: {sum(s['dentro'] for s in senderos)} tramos, "
        f"{sum(s['km'] for s in senderos if s['dentro']):.1f} km.",
        "",
        "| Nombre | Tipo | km | Altitud mín. | Altitud máx. | Toca el parque | ID OSM |",
        "|---|---|---|---|---|---|---|",
    ]
    for s in senderos:
        lineas.append(
            f"| {s['nombre'] or '(sin nombre)'} | {s['tipo']} | {s['km']:.2f} | {s['altitud_min']} | "
            f"{s['altitud_max']} | {'sí' if s['dentro'] else 'no'} | {s['id_osm']} |"
        )
    (SALIDA / "senderos_3500.md").write_text("\n".join(lineas) + "\n", encoding="utf-8")
    print("\n".join(lineas[4:7]))


def curvas_de_nivel(dem, transformada):
    inversa = ~transformada
    c0, f0 = (int(v) for v in inversa * (OESTE, NORTE))
    c1, f1 = (math.ceil(v) for v in inversa * (ESTE, SUR))
    recorte = dem[f0:f1, c0:c1]
    inicio = math.ceil(recorte.min() / INTERVALO_CURVAS) * INTERVALO_CURVAS
    elementos = []
    for nivel in range(max(inicio, INTERVALO_CURVAS), int(recorte.max()), INTERVALO_CURVAS):
        for contorno in measure.find_contours(recorte, nivel):
            if len(contorno) < 20:
                continue
            columnas = contorno[:, 1] + c0 + 0.5
            filas = contorno[:, 0] + f0 + 0.5
            xs, ys = transformada * (columnas, filas)
            linea = shapely.simplify(shapely.LineString(np.column_stack([xs, ys])), 0.0002)
            elementos.append(
                elemento(
                    {"type": "LineString", "coordinates": redondear(linea.coords)},
                    {"altitud": nivel, "maestra": nivel % 500 == 0},
                )
            )
    guardar("curvas.geojson", elementos)
    print(f"Altitud en la zona: {recorte.min():.0f} a {recorte.max():.0f} m")


def teselas_elevacion(dem, transformada, crs):
    mitad = 20037508.342789244
    total, peso = 0, 0
    for z in ZOOM_ELEVACION:
        n = 2**z
        x_de = lambda lon: int((lon + 180) / 360 * n)
        y_de = lambda lat: int((1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2 * n)
        lado = 2 * mitad / n
        for x in range(x_de(OESTE), x_de(ESTE) + 1):
            for y in range(y_de(NORTE), y_de(SUR) + 1):
                izquierda = -mitad + x * lado
                arriba = mitad - y * lado
                destino = np.full((256, 256), np.nan, dtype="float32")
                reproject(
                    dem,
                    destino,
                    src_transform=transformada,
                    src_crs=crs,
                    dst_transform=from_bounds(izquierda, arriba - lado, izquierda + lado, arriba, 256, 256),
                    dst_crs="EPSG:3857",
                    dst_nodata=np.nan,
                    resampling=Resampling.bilinear,
                )
                # Centros de píxel en coordenadas geográficas, para aplanar el exterior de la zona.
                desplazamientos = (np.arange(256) + 0.5) * lado / 256
                longitudes = np.degrees((izquierda + desplazamientos) / 6378137)
                latitudes = np.degrees(np.arctan(np.sinh((arriba - desplazamientos) / 6378137)))
                dentro = np.outer(
                    (latitudes >= SUR) & (latitudes <= NORTE), (longitudes >= OESTE) & (longitudes <= ESTE)
                )
                destino = np.where(dentro & ~np.isnan(destino), destino, ALTITUD_BASE)
                valor = destino + 32768.0
                rgb = np.stack(
                    [valor // 256, np.floor(valor % 256), np.floor((valor - np.floor(valor)) * 256)], axis=-1
                ).astype("uint8")
                ruta = SALIDA / "elevacion" / str(z) / str(x) / f"{y}.png"
                ruta.parent.mkdir(parents=True, exist_ok=True)
                Image.fromarray(rgb).save(ruta, optimize=True)
                total += 1
                peso += ruta.stat().st_size
    print(f"Teselas de elevación: {total}, {peso / 1024 / 1024:.1f} MB")


def main():
    SALIDA.mkdir(exist_ok=True)
    dem, transformada, crs = cargar_dem()
    limite = exportar_limite()
    senderos, _ = extraer_osm(dem, transformada, limite)
    informe_senderos(senderos)
    curvas_de_nivel(dem, transformada)
    teselas_elevacion(dem, transformada, crs)


if __name__ == "__main__":
    main()
