# Mapa del sector Nevado del Ruiz

Zona: oeste -75.45, sur 4.75, este -75.20, norte 5.10. **Versión de revisión sin verificar: no usar para orientarse.**

## Contenido
- `scripts/generar_mapa.py`: genera los datos en `maps/salida/`.
- `visor/`: visor con MapLibre GL JS (estilo ilustrado, relieve 3D y mapa plano).
- `satelite/`: imagen Sentinel-2 cloudless 2016 y su origen.

La app incluye una copia ya generada en `assets/map/`.

## Regenerar
Los datos crudos no están en el repositorio. Descargarlos en estas carpetas:

| Carpeta | Fuente | Archivo esperado por el script |
|---|---|---|
| `maps/dem/` | Copernicus DEM GLO-30 | Teselas `N04_00_W076_00` y `N05_00_W076_00` |
| `maps/geofabrik/` | OpenStreetMap (Geofabrik, Colombia), licencia ODbL | `colombia-261124.osm.pbf` |
| `maps/WDPA_WDOECM_NOV2026/` | WDPA (Protected Planet) | `WDPA_WDOECM_Nov2026_Public_147.gdb` |

Dependencias de Python: `numpy`, `osmium`, `pyogrio`, `rasterio`, `shapely`, `pillow`, `pyproj`, `scikit-image`.

Desde la raíz del repositorio:

```bash
cd maps && python3 scripts/generar_mapa.py && cd ..
python3 tool/sync_map_assets.py
```

## Pendiente antes de distribuir
- Confirmar las condiciones de redistribución del límite del parque (WDPA), incluido en los datos de la app.
- Confirmar la licencia y vigencia del mapa de amenaza volcánica del SGC (no está incluido).
- Verificar senderos y refugios, que vienen de OpenStreetMap sin revisar.
