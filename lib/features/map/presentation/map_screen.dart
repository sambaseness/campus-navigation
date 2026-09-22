import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/remote/campus_data_repository.dart';
import '../../../data/remote/calibration_repository.dart';
import '../../../data/remote/campus_feature_mapper.dart';
import '../../../data/remote/campus_search.dart';
import '../../../domain/campus/campus_feature.dart';
import '../../../domain/campus/destination_selection.dart';
import '../../../domain/map/calibration.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  static const campusCenter = LatLng(14.6816, -17.4668);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _repository = const CampusDataRepository();
  final _calibrationRepository = const CalibrationRepository();
  final _mapper = const CampusFeatureMapper();
  final _search = const CampusSearch();
  final _mapController = MapController();
  final _polygonHitNotifier = ValueNotifier<LayerHitResult<CampusFeature>?>(null);
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<CampusFeature> _features = const [];
  List<CampusFeature> _searchResults = const [];
  CampusFeature? _selected;
  DestinationSelection? _destination;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _polygonHitNotifier.addListener(_handlePolygonHit);
    _searchController.addListener(_updateSearch);
    _loadCampus();
  }

  @override
  void dispose() {
    _polygonHitNotifier.removeListener(_handlePolygonHit);
    _polygonHitNotifier.dispose();
    _searchController
      ..removeListener(_updateSearch)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handlePolygonHit() {
    final hit = _polygonHitNotifier.value;
    final feature = hit?.hitValues.firstOrNull;
    if (feature == null || !mounted) return;
    setState(() => _selected = feature);
  }

  void _updateSearch() {
    final results = _search.search(_features, _searchController.text);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  Future<void> _loadCampus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final source = await _repository.load();
      final calibration = await _calibrationRepository.load();
      final features = _applyCalibration(_mapper.map(source), calibration);

      if (!mounted) return;
      setState(() {
        _features = features;
        _selected = null;
        _destination = null;
        _searchResults = _search.search(features, _searchController.text);
        _loading = false;
      });
      _mapController.move(calibration.transform(MapScreen.campusCenter), 17);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<CampusFeature> _applyCalibration(
    List<CampusFeature> features,
    MapCalibration calibration,
  ) {
    return features
        .map(
          (feature) => CampusFeature(
            id: feature.id,
            type: feature.type,
            geometry: calibration.transformPath(feature.geometry),
            name: feature.name,
            category: feature.category,
            tags: feature.tags,
          ),
        )
        .toList(growable: false);
  }

  void _selectFeature(CampusFeature feature, {bool focusMap = true}) {
    setState(() {
      _selected = feature;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });

    if (focusMap) {
      _mapController.move(feature.center, 19);
    }
  }

  void _setDestination(CampusFeature feature) {
    setState(() {
      _selected = feature;
      _destination = DestinationSelection(
        feature: feature,
        point: feature.center,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final buildings = _features.where(
      (feature) => feature.type == CampusFeatureType.building,
    );
    final paths = _features.where(
      (feature) => feature.type == CampusFeatureType.path,
    );
    final places = _features.where(
      (feature) => feature.type == CampusFeatureType.pointOfInterest,
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
            mapController: _mapController,
            options: MapOptions(
              initialCenter: MapScreen.campusCenter,
              initialZoom: 17,
              minZoom: 14,
              maxZoom: 21,
              onTap: (_, __) {
                setState(() {
                  _selected = null;
                  _destination = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusnavigation.app',
                maxZoom: 19,
              ),
              PolygonLayer<CampusFeature>(
                hitNotifier: _polygonHitNotifier,
                polygons: [
                  for (final feature in buildings)
                    Polygon<CampusFeature>(
                      points: feature.geometry,
                      color: _selected?.id == feature.id
                          ? Colors.blue.withValues(alpha: 0.40)
                          : Colors.blue.withValues(alpha: 0.20),
                      borderColor: _selected?.id == feature.id
                          ? Colors.blue.shade900
                          : Colors.blue.shade700,
                      borderStrokeWidth:
                          _selected?.id == feature.id ? 2.5 : 1.2,
                      hitValue: feature,
                      label: feature.name ?? '',
                    ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  for (final feature in paths)
                    Polyline(
                      points: feature.geometry,
                      color: Colors.orange.shade700,
                      strokeWidth: feature.category == 'footway' ? 2 : 3,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final feature in places)
                    Marker(
                      point: feature.center,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _selectFeature(feature),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
              if (_destination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _destination!.point,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.green,
                        size: 38,
                      ),
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
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _SearchPanel(
              controller: _searchController,
              focusNode: _searchFocusNode,
              results: _searchResults,
              onSelect: _selectFeature,
              onClear: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
              },
            ),
          ),
          if (_loading)
            const Positioned(
              top: 82,
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
              top: 82,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Could not load remote OSM data.\n$$_error'),
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
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 70,
              child: _FeatureCard(
                feature: _selected!,
                destination: _destination,
                onDestination: () => _setDestination(_selected!),
                onClose: () => setState(() {
                  _selected = null;
                  _destination = null;
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.focusNode,
    required this.results,
    required this.onSelect,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<CampusFeature> results;
  final ValueChanged<CampusFeature> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.text.trim().isNotEmpty;

    return Card(
      elevation: 5,
      child: Column(
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search buildings or places…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasQuery
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (hasQuery && results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final feature = results[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      feature.type == CampusFeatureType.building
                          ? Icons.apartment
                          : Icons.place,
                    ),
                    title: Text(
                      feature.name ??
                          (feature.category ?? 'Unnamed destination'),
                    ),
                    subtitle: Text(feature.category ?? 'ESP Dakar'),
                    onTap: () => onSelect(feature),
                  );
                },
              ),
            ),
          if (hasQuery && results.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No matching campus destination.'),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.feature,
    required this.destination,
    required this.onDestination,
    required this.onClose,
  });

  final CampusFeature feature;
  final DestinationSelection? destination;
  final VoidCallback onDestination;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final title = feature.name ??
        (feature.type == CampusFeatureType.building
            ? 'Bâtiment ESP'
            : 'Lieu sans nom');

    final subtitle = feature.category ?? 'ESP Dakar';
    final isDestination = destination?.feature.id == feature.id;

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(
                feature.type == CampusFeatureType.building
                    ? Icons.apartment
                    : Icons.place,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isDestination
                        ? 'Destination sélectionnée — itinéraire à venir'
                        : 'Données provisoires OpenStreetMap',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!isDestination)
              FilledButton.tonal(
                onPressed: onDestination,
                child: const Text('Go here'),
              ),
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
