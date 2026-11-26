"""Genera la capa del recorrido del sector norte para el mapa (assets/map/salida/recorrido.geojson).

Entradas:
- maps/recorrido/estaciones.csv: las cinco paradas (del equipo: ruta_norte_5_paradas.gpx, sin validar en campo).
  Las que no tienen coordenada no se dibujan.
- assets/map/salida/vias.geojson: de ahí se toma el camino (por defecto, la pista de OpenStreetMap 824243975,
  que pasa junto al Refugio Arenales y el Valle de las Tumbas). Se puede cambiar con --via.

Uso, desde la raíz del proyecto:
    python3 maps/scripts/generar_recorrido.py
    python3 maps/scripts/generar_recorrido.py --via 824243975 --via 1068022622

El camino se corta en tramos entre paradas consecutivas (tipo "tramo", con "hasta" = número de la parada
de llegada), para que el mapa pueda mostrar uno solo. Todo sale marcado como sin verificar hasta que el equipo confirme el trazado y las coordenadas.
Sin dependencias: solo la biblioteca estándar.
"""

import argparse
import csv
import json
import math
from pathlib import Path

APP = Path(__file__).resolve().parents[2]
CSV = APP / "maps/recorrido/estaciones.csv"
VIAS = APP / "assets/map/salida/vias.geojson"
SALIDA = APP / "assets/map/salida/recorrido.geojson"
VIA_POR_DEFECTO = 824243975


def metros(a, b):
    x = (a[0] - b[0]) * 111_320 * math.cos(math.radians((a[1] + b[1]) / 2))
    y = (a[1] - b[1]) * 110_574
    return math.hypot(x, y)


def lineas(feature):
    g = feature["geometry"]
    return g["coordinates"] if g["type"] == "MultiLineString" else [g["coordinates"]]


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--via", type=int, action="append", help="id de OpenStreetMap de la vía (se repite)")
    args = parser.parse_args()
    ids = args.via or [VIA_POR_DEFECTO]

    with CSV.open(encoding="utf-8") as f:
        estaciones = list(csv.DictReader(f))
    vias = {v["properties"]["id_osm"]: v for v in json.loads(VIAS.read_text(encoding="utf-8"))["features"]}

    camino = []
    for id_osm in ids:
        if id_osm not in vias:
            raise SystemExit(f"La vía {id_osm} no está en {VIAS.name}.")
        for linea in lineas(vias[id_osm]):
            # Se encadenan en el sentido que continúe la anterior.
            if camino and metros(camino[-1], linea[-1]) < metros(camino[-1], linea[0]):
                linea = list(reversed(linea))
            camino.extend(linea)

    paradas, pendientes = [], []
    for e in sorted(estaciones, key=lambda e: int(e["orden"])):
        if not e["lon"] or not e["lat"]:
            pendientes.append(e["nombre"])
            continue
        punto = [float(e["lon"]), float(e["lat"])]
        indice = min(range(len(camino)), key=lambda i: metros(punto, camino[i]))
        paradas.append((e, punto, indice, metros(punto, camino[indice])))

    # El camino debe ir de la primera a la última parada; si la vía está al revés, se invierte.
    if len(paradas) >= 2 and paradas[0][2] > paradas[-1][2]:
        camino.reverse()
        paradas = [(e, p, len(camino) - 1 - i, d) for e, p, i, d in paradas]

    features = []
    for (a, _, ia, _), (b, _, ib, _) in zip(paradas, paradas[1:]):
        if ib <= ia:
            raise SystemExit(f"{b['nombre']} queda antes que {a['nombre']} sobre el camino: revisa el orden.")
        features.append({
            "type": "Feature",
            "properties": {"tipo": "tramo", "hasta": int(b["orden"]), "desde_nombre": a["nombre"],
                           "hasta_nombre": b["nombre"], "verificado": False,
                           "fuente": "OpenStreetMap " + ", ".join(map(str, ids)) + " (sin verificar)"},
            "geometry": {"type": "LineString", "coordinates": camino[ia:ib + 1]},
        })
    for e, punto, _, distancia in paradas:
        features.append({
            "type": "Feature",
            "properties": {"tipo": "estacion", "orden": int(e["orden"]), "nombre": e["nombre"],
                           "fuente": e["fuente"], "verificado": e["verificado"].strip().lower() == "si",
                           "distancia_al_camino_m": round(distancia)},
            "geometry": {"type": "Point", "coordinates": punto},
        })
        if distancia > 300:
            print(f"Aviso: {e['nombre']} queda a {distancia:.0f} m del camino elegido.")

    SALIDA.write_text(json.dumps({"type": "FeatureCollection", "features": features}, ensure_ascii=False),
                      encoding="utf-8")
    print(f"{SALIDA.relative_to(APP)}: {len(paradas)} paradas, {len(paradas) - 1} tramos.")
    for e, _, _, d in paradas:
        print(f"  {e['orden']}. {e['nombre']}: a {d:.0f} m del camino")
    if pendientes:
        print("Sin coordenada (no se dibujan): " + ", ".join(pendientes))


if __name__ == "__main__":
    main()
