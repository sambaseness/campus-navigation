# Remote Mapping Strategy

This branch is the remote-first mapping track.

## Objective

Build as much of the campus map as possible before an on-site GPS survey is available.

The remote dataset is explicitly treated as provisional. It must remain replaceable by surveyed data later.

## Sources

The first candidate source is OpenStreetMap. Overpass provides read-only, queryable OSM data and can retrieve buildings, paths, amenities, and other tagged features for a selected area.

Remote sources can give us:
- building footprints
- mapped roads and footways
- named amenities
- campus boundaries when mapped
- points of interest

## Accuracy rule

Remote data is not assumed to be ground truth.

We will keep:
1. source geometry;
2. source metadata;
3. calibration parameters;
4. confidence/status.

The eventual field survey can replace or correct these independently.

## Workflow

OSM / remote imagery
        ↓
remote extraction
        ↓
normalization
        ↓
campus domain model
        ↓
map rendering
        ↓
temporary calibration
        ↓
field survey later
        ↓
validated campus dataset

## What this branch should accomplish

- identify what campus information already exists remotely;
- import usable OSM geometry;
- normalize it into our local data model;
- render buildings and paths;
- build building/POI metadata;
- establish the routing graph structure;
- build search and destination interaction;
- make the field survey a later validation/calibration step.

## What this branch must not assume

- that OSM building outlines are perfectly aligned;
- that all pedestrian paths are mapped;
- that building names are complete;
- that GPS accuracy is sufficient for final calibration;
- that remote imagery is perfectly georeferenced.

## Merge strategy

When field data becomes available, surveyed geometry and control points should replace or override provisional remote data.

The application architecture should not need to change when that happens.
