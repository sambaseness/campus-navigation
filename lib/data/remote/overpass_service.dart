import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsmFeature {
  const OsmFeature({
    required this.id,
    required this.type,
    required this.tags,
    required this.geometry,
  });

  final String id;
  final String type;
  final Map<String, String> tags;
  final List<LatLng> geometry;

  String? get name => tags['name'];
  String? get highway => tags['highway'];
  String? get building => tags['building'];

  bool get isClosedPolygon =>
      geometry.length >= 4 && geometry.first == geometry.last;
}

class OverpassService {
  const OverpassService();

  static const endpoint = 'https://overpass-api.de/api/interpreter';

  Future<List<OsmFeature>> fetchEspCampus() async {
    const query = '''
[out:json][timeout:60];
(
  way["building"](14.678,-17.472,14.686,-17.462);
  way["highway"](14.678,-17.472,14.686,-17.462);
  way["amenity"](14.678,-17.472,14.686,-17.462);
  node["amenity"](14.678,-17.472,14.686,-17.462);
  node["name"](14.678,-17.472,14.686,-17.462);
);
out body geom;
''';

    final response = await http.get(
      Uri.parse(endpoint).replace(queryParameters: {'data': query}),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Overpass request failed (${response.statusCode}).',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = json['elements'] as List<dynamic>;

    return elements
        .map((element) => _parseFeature(element as Map<String, dynamic>))
        .whereType<OsmFeature>()
        .toList(growable: false);
  }

  OsmFeature? _parseFeature(Map<String, dynamic> element) {
    final tagsJson = element['tags'];
    final geometryJson = element['geometry'];

    final tags = <String, String>{};
    if (tagsJson is Map) {
      for (final entry in tagsJson.entries) {
        tags[entry.key.toString()] = entry.value.toString();
      }
    }

    final geometry = <LatLng>[];

    if (geometryJson is List) {
      for (final point in geometryJson) {
        if (point is Map<String, dynamic>) {
          final lat = point['lat'];
          final lon = point['lon'];
          if (lat is num && lon is num) {
            geometry.add(LatLng(lat.toDouble(), lon.toDouble()));
          }
        }
      }
    } else if (element['type'] == 'node') {
      final lat = element['lat'];
      final lon = element['lon'];
      if (lat is num && lon is num) {
        geometry.add(LatLng(lat.toDouble(), lon.toDouble()));
      }
    }

    return OsmFeature(
      id: '${element['type']}/${element['id']}',
      type: element['type']?.toString() ?? 'unknown',
      tags: tags,
      geometry: geometry,
    );
  }
}
