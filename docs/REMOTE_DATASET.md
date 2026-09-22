# ESP Remote Dataset

The app can use a versioned OSM snapshot at `assets/data/esp_osm.json`.

The snapshot is generated from the same ESP extraction query documented in
`docs/REMOTE_OSM_QUERY.md`.

## Why snapshot the data?

Overpass is a read-only data service intended for querying selected OSM data.
It is useful for extraction, but the mobile app should not depend on an external
query succeeding every time the app starts. `out geom` provides full geometry
for returned ways and relations.

The repository snapshot also gives us a stable input for calibration and testing.
Raw OSM geometry remains untouched.

## Updating the snapshot

From the repository root:

```bash
dart run tool/export_esp_osm.dart
```

Review the generated file before committing it.

## Data lifecycle

Overpass
  ↓
esp_osm.json
  ↓
OSM parser
  ↓
CampusFeatureMapper
  ↓
calibration
  ↓
map

The snapshot is provisional. Field-surveyed data can later replace it without
changing the map/domain architecture.
