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
  OsmFeature? _selected;
  String? _error;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadCampus(); }

  Future<void> _loadCampus() async {
    try {
      final features = await _service.fetchEspCampus();
      if (!mounted) return;
      setState(() {
        _features = features;
        _selected = null;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildings = _features.where((f) => f.building != null && f.isClosedPolygon);
    final paths = _features.where((f) => f.highway != null && f.geometry.length >= 2);
    final places = _features.where((f) => f.type == 'node' && f.name != null && f.geometry.length == 1);

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
            options: MapOptions(
              initialCenter: MapScreen.campusCenter,
              initialZoom: 17,
              minZoom: 14,
              maxZoom: 21,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusnavigation.app',
                maxZoom: 19,
              ),
              PolygonLayer(
                polygons: [
                  for (final feature in buildings)
                    Polygon(
                      points: feature.geometry,
                      color: _selected?.id == feature.id
                          ? Colors.blue.withValues(alpha: 0.40)
                          : Colors.blue.withValues(alpha: 0.20),
                      borderColor: _selected?.id == feature.id
                          ? Colors.blue.shade900
                          : Colors.blue.shade700,
                      borderStrokeWidth: _selected?.id == feature.id ? 2.5 : 1.2,
                      hitValue: feature,
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
              MarkerLayer(
                markers: [
                  for (final feature in places)
                    Marker(
                      point: feature.geometry.first,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = feature),
                        child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),
          if (_loading)
            const Positioned(
              top: 12, left: 12, right: 12,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Loading ESP map data…'),
                    ],
                  ),
                ),
              ),
            ),
          if (_error != null)
            Positioned(
              top: 12, left: 12, right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Could not load remote OSM data.\n$_error'),
                ),
              ),
            ),
          if (!_loading && _error == null)
            Positioned(
              bottom: 16, left: 16,
              child: Chip(
                avatar: const Icon(Icons.layers, size: 18),
                label: Text('${buildings.length} buildings · ${paths.length} paths'),
              ),
            ),
          if (_selected != null)
            Positioned(
              left: 12, right: 12, bottom: 70,
              child: _FeatureCard(
                feature: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.onClose});

  final OsmFeature feature;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final title = feature.name ??
        (feature.building != null ? 'Bâtiment ESP' : 'Lieu sans nom');
    final subtitle = feature.tags['amenity'] ??
        feature.building ??
        feature.highway ??
        'ESP Dakar';

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.school)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  const Text('Données provisoires OpenStreetMap', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            IconButton(tooltip: 'Close', onPressed: onClose, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}
