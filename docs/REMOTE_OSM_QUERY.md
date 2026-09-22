# ESP Dakar — Remote OSM extraction

## Campus

The target campus is **École Supérieure Polytechnique de Dakar (ESP)**, on the UCAD/Corniche Ouest site in Dakar.

A mapped ESP campus feature is located around **14.68102, -17.46643**. Nearby OSM features include ESP buildings, the ESP football field, library, lecture/classroom areas and other named facilities.

## Working extraction area

Until we have a surveyed campus boundary, use this conservative bounding box:

- south: `14.678`
- west: `-17.472`
- north: `14.686`
- east: `-17.462`

This is an extraction area, not a claim that every feature inside it belongs to ESP.

## Overpass query

The app/exporter use this exact snapshot query:

```overpass
[out:json][timeout:60];
(
  way["building"](14.678,-17.472,14.686,-17.462);
  way["highway"](14.678,-17.472,14.686,-17.462);
  way["amenity"](14.678,-17.472,14.686,-17.462);
  node["amenity"](14.678,-17.472,14.686,-17.462);
  node["name"](14.678,-17.472,14.686,-17.462);
);
out body geom;
```

`out geom` is intentional: it returns full geometry for the selected objects, which lets the local parser render ways without a second geometry reconstruction step. citeturn0search1turn0search2

## Data policy

The extracted OSM dataset is provisional.

Do not overwrite raw coordinates to fix visual alignment or assume every building is correctly named. Instead use:

**OSM source → normalized local data → calibration → rendered map**

When field-survey data becomes available, it can be compared against this dataset and used to calibrate or replace individual features.
