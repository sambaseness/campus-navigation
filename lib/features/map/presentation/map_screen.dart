import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/remote/overpass_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  static const campusCenter = LatLng(14.6816, -17.4668);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _service = OverpassService();

  List<OsmFeature> _features = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCampus();
  }

  Future<void> _loadCampus() async {
    try {
      final features = await _service.fetchEspCampus();
      if (!mounted) return;
      setState(() {
        _features = features;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildings = _features.where(
      (feature) => feature.building != null && feature.isClosedPolygon,
    );
    final paths = _features.where(
      (feature) => feature.highway != null && feature.geometry.length >= 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP Dakar'),
        actions: [
          IconButton(
            tooltip: 'Reload OSM data',
            onPressed: _loading ? null : _loadCampus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: MapScreen.campusCenter,
              initialZoom: 17,
              minZoom: 14,
              maxZoom: 21,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusnavigation.app',
                maxZoom: 19,
              ),
              PolygonLayer(
                polygons: [
                  for (final feature in buildings)
                    Polygon(
                      points: feature.geometry,
                      color: Colors.blue.withValues(alpha: 0.20),
                      borderColor: Colors.blue.shade700,
                      borderStrokeWidth: 1.2,
                    ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  for (final feature in paths)
                    Polyline(
                      points: feature.geometry,
                      color: Colors.orange.shade700,
                      strokeWidth: feature.highway == 'footway' ? 2 : 3,
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          if (_loading)
            const Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading ESP map data…'),
                    ],
                  ),
                ),
              ),
            ),
          if (_error != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Could not load remote OSM data. The base map remains available.\n'
                    '$_error',
                  ),
                ),
              ),
            ),
          if (!_loading && _error == null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Chip(
                avatar: const Icon(Icons.layers, size: 18),
                label: Text(
                  '${buildings.length} buildings · ${paths.length} paths',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
