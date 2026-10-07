# Campus Navigation

Flutter campus navigation prototype.

## AR navigation MVP

The app now includes an AR mode based on \`ar_flutter_plugin_plus\`. The MVP detects horizontal planes and places a 3D directional marker when the user taps a detected surface.

This is deliberately the first AR layer. It does **not** yet claim to be geospatial navigation: the marker is locally anchored to an AR plane. The next layer is ARCore Geospatial/VPS so destinations can be anchored to real campus coordinates.

### Run

1. Generate the native Flutter platforms if they are not already present:
   \`flutter create .\`
2. Run \`flutter pub get\`.
3. Test on a physical ARCore-capable Android device.
4. Build a release APK for smoother AR tracking.

ARCore Geospatial can later replace the local plane anchor with Terrain/Rooftop/WGS84 anchors. Google recommends Terrain/Rooftop anchors where their coverage is available.
