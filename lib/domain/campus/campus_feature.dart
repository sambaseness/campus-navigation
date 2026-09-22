import 'package:latlong2/latlong.dart';

enum CampusFeatureType { building, path, pointOfInterest }

class CampusFeature {
  const CampusFeature({
    required this.id,
    required this.type,
    required this.geometry,
    this.name,
    this.category,
    this.tags = const {},
  });

  final String id;
  final CampusFeatureType type;
  final List<LatLng> geometry;
  final String? name;
  final String? category;
  final Map<String, String> tags;

  bool get selectable =>
      type == CampusFeatureType.building ||
      type == CampusFeatureType.pointOfInterest;

  String get searchableText {
    final values = <String>[
      name ?? '',
      category ?? '',
      tags['name'] ?? '',
      tags['official_name'] ?? '',
      tags['amenity'] ?? '',
      tags['building'] ?? '',
      tags['ref'] ?? '',
    ];

    return values.join(' ').toLowerCase();
  }

  LatLng get center {
    if (geometry.isEmpty) return const LatLng(0, 0);

    var lat = 0.0;
    var lon = 0.0;
    for (final point in geometry) {
      lat += point.latitude;
      lon += point.longitude;
    }

    return LatLng(lat / geometry.length, lon / geometry.length);
  }
}
