import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:campus_navigation/data/remote/campus_feature_mapper.dart';
import 'package:campus_navigation/data/remote/overpass_service.dart';
import 'package:campus_navigation/domain/campus/campus_feature.dart';

void main() {
  test('maps closed building ways to buildings', () {
    final source = [
      OsmFeature(
        id: 'way/1',
        type: 'way',
        tags: const {'building': 'yes', 'name': 'Bibliothèque'},
        geometry: const [
          LatLng(14.68, -17.47),
          LatLng(14.68, -17.469),
          LatLng(14.681, -17.469),
          LatLng(14.681, -17.47),
          LatLng(14.68, -17.47),
        ],
      ),
    ];

    final result = const CampusFeatureMapper().map(source);

    expect(result, hasLength(1));
    expect(result.single.type, CampusFeatureType.building);
    expect(result.single.name, 'Bibliothèque');
    expect(result.single.category, 'yes');
  });

  test('maps named amenity nodes to POIs', () {
    final source = [
      OsmFeature(
        id: 'node/2',
        type: 'node',
        tags: const {'amenity': 'library', 'name': 'Library'},
        geometry: const [LatLng(14.68, -17.47)],
      ),
    ];

    final result = const CampusFeatureMapper().map(source);

    expect(result.single.type, CampusFeatureType.pointOfInterest);
  });
}
