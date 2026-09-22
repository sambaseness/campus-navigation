import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'overpass_service.dart';

class CampusDataRepository {
  const CampusDataRepository({
    this.assetPath = 'assets/data/esp_osm.json',
    this.remote = const OverpassService(),
  });

  final String assetPath;
  final OverpassService remote;

  Future<List<OsmFeature>> load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return parseElements(json['elements']);
    } on FlutterError {
      return remote.fetchEspCampus();
    } on FormatException {
      return remote.fetchEspCampus();
    }
  }

  static List<OsmFeature> parseElements(dynamic rawElements) {
    if (rawElements is! List) {
      throw const FormatException('OSM snapshot has no elements array.');
    }

    return rawElements
        .whereType<Map<String, dynamic>>()
        .map(_parseFeature)
        .whereType<OsmFeature>()
        .toList(growable: false);
  }

  static OsmFeature? _parseFeature(Map<String, dynamic> element) {
    final tags = <String, String>{};
    final tagsJson = element['tags'];
    if (tagsJson is Map) {
      for (final entry in tagsJson.entries) {
        tags[entry.key.toString()] = entry.value.toString();
      }
    }

    final geometry = <LatLng>[];
    final geometryJson = element['geometry'];

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
      id: element['type'].toString() + '/' + element['id'].toString(),
      type: element['type']?.toString() ?? 'unknown',
      tags: tags,
      geometry: geometry,
    );
  }
}
