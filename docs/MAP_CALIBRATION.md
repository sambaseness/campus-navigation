# Map Calibration

## Problem
OSM/GPS coordinates and manually surveyed campus geometry may not line up perfectly.

If every feature is shifted independently, the dataset becomes fragile. Buildings, entrances, paths and future routes can then disagree.

## First solution: similarity transform
Use control points: known pairs of source and trusted target coordinates.

x' = a·x - b·y + tx
y' = b·x + a·y + ty

tx and ty represent translation; a and b jointly represent scale and rotation.

The fit is performed in local east/north metres around a chosen origin.

## Control-point strategy
Start with 3–6 reliable landmarks distributed across the campus:
- building corners
- road intersections
- campus gates
- other fixed, identifiable landmarks

Do not cluster all control points in one small area.

## Error monitoring
With more than the minimum number of control points, calculate residual error between transformed source points and their targets.

If residuals are small and spatially consistent, the similarity transform is a good first model.

If residuals vary systematically across the campus, the calibration layer can later be upgraded to an affine or piecewise transform without changing map/domain consumers.

## Non-negotiable rule
**Never bake calibration corrections into raw source data.**

Calibration must remain explicit and reversible.
