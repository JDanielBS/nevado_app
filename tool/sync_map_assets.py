"""Copia a la app el mapa, que se genera fuera de ella, y actualiza la lista de pubspec.yaml.

- Mapa: maps/visor, maps/salida y la imagen satelital -> assets/map/
- Las fichas viven en assets/content/ y no se copian de ningún lado.

Uso (desde la raíz del repositorio, después de generar el mapa):
    python3 tool/sync_map_assets.py

Flutter no incluye subcarpetas de forma recursiva, por eso cada carpeta con archivos se declara
en pubspec.yaml, entre las marcas "# recursos:inicio" y "# recursos:fin".
"""

import shutil
from pathlib import Path

APP = Path(__file__).resolve().parent.parent
RAIZ = APP
MAPAS = RAIZ / "maps"
DESTINO_MAPA = APP / "assets" / "map"

ARCHIVOS_SALIDA = ["agua.geojson", "area_pnn.geojson", "curvas.geojson", "limite_pnn.geojson",
                   "puntos.geojson", "vias.geojson"]
ARCHIVOS_VISOR = ["index.html", "lib/maplibre-gl.js", "lib/maplibre-gl.css", "lib/LICENSE.txt"]


def copiar(origen: Path, destino: Path) -> None:
    destino.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(origen, destino)


def main() -> None:
    # Se rehace la carpeta del mapa para no dejar archivos viejos.
    if DESTINO_MAPA.exists():
        shutil.rmtree(DESTINO_MAPA)
    for nombre in ARCHIVOS_VISOR:
        copiar(MAPAS / "visor" / nombre, DESTINO_MAPA / "visor" / nombre)
    for nombre in ARCHIVOS_SALIDA:
        copiar(MAPAS / "salida" / nombre, DESTINO_MAPA / "salida" / nombre)
    shutil.copytree(MAPAS / "salida" / "elevacion", DESTINO_MAPA / "salida" / "elevacion")
    copiar(MAPAS / "satelite" / "s2cloudless2016_ruiz.jpg", DESTINO_MAPA / "satelite" / "s2cloudless2016_ruiz.jpg")

    carpetas = sorted(
        {p.parent.relative_to(APP).as_posix() + "/" for p in (APP / "assets").rglob("*") if p.is_file()}
    )
    pubspec = APP / "pubspec.yaml"
    texto = pubspec.read_text(encoding="utf-8")
    inicio = texto.index("    # recursos:inicio\n") + len("    # recursos:inicio\n")
    fin = texto.index("    # recursos:fin\n")
    lista = "".join(f"    - {c}\n" for c in carpetas)
    pubspec.write_text(texto[:inicio] + lista + texto[fin:], encoding="utf-8")

    peso = sum(p.stat().st_size for p in (APP / "assets").rglob("*") if p.is_file())
    print(f"{len(carpetas)} carpetas de recursos, {peso / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()
