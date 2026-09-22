import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:campus_navigation/data/remote/campus_search.dart';
import 'package:campus_navigation/domain/campus/campus_feature.dart';

void main() {
  const search = CampusSearch();

  final features = [
    CampusFeature(
      id: '1',
      type: CampusFeatureType.building,
      geometry: [const LatLng(14.68, -17.47)],
      name: 'Bibliothèque ESP',
      category: 'yes',
    ),
    CampusFeature(
      id: '2',
      type: CampusFeatureType.building,
      geometry: [const LatLng(14.681, -17.469)],
      name: 'Amphithéâtre',
      category: 'yes',
    ),
  ];

  test('returns prefix matches before weaker matches', () {
    final result = search.search(features, 'bibl');

    expect(result, hasLength(1));
    expect(result.single.id, '1');
  });

  test('ignores paths in destination search', () {
    final path = CampusFeature(
      id: '3',
      type: CampusFeatureType.path,
      geometry: features.first.geometry,
      name: 'Bibliothèque path',
      category: 'footway',
    );

    expect(search.search([...features, path], 'bibliothèque'), hasLength(1));
  });
}
