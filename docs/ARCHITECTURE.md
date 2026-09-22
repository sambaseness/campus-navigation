# Campus Navigation — Architecture

## Goal
Build the campus navigation core from a clean foundation. The first milestone is a trustworthy campus coordinate system; turn-by-turn routing comes later.

## Coordinate spaces
1. **Source space** — raw OSM, GPS, survey, or manually exported coordinates.
2. **Campus display space** — corrected coordinates used by the app.

Raw data is never edited just to compensate for a systematic offset.

Pipeline:
source data → calibration → map rendering → interaction → routing

## Layers
- UI: map, search, destination selection, controls
- Map: base tiles, campus geometry, calibrated overlays, user position
- Domain: buildings, paths, calibration and future routing graph
- Data: local JSON/GeoJSON initially
- Infrastructure: OSM tiles and device location

## Why calibration is first-class
A campus can be consistently displaced because different data sources use different measurements, dates, or reference assumptions. Instead of manually moving every building and road, we estimate one transform from reliable control points.

This makes correction centralized, reversible, testable, and reusable by future routing.

## Phase 1 definition of done
- Interactive map can pan and zoom.
- Local campus geometry can be rendered.
- Buildings and paths pass through the calibration layer.
- Buildings can be selected.
- Calibration can change without editing source geometry.
- The data model leaves room for routing later.

## Out of scope for Phase 1
- Authentication
- Backend/database
- Cloud routing
- AR navigation
- Social features
- Analytics
