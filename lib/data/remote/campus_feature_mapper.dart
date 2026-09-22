import '../../domain/campus/campus_feature.dart';
import 'overpass_service.dart';

class CampusFeatureMapper {
  const CampusFeatureMapper();

  List<CampusFeature> map(List<OsmFeature> source) {
    final result = <CampusFeature>[];

    for (final feature in source) {
      final mapped = mapOne(feature);
      if (mapped != null) result.add(mapped);
    }

    return result;
  }

  CampusFeature? mapOne(OsmFeature feature) {
    if (feature.geometry.isEmpty) return null;

    if (feature.building != null && feature.isClosedPolygon) {
      return CampusFeature(
        id: feature.id,
        type: CampusFeatureType.building,
        geometry: feature.geometry,
        name: feature.name,
        category: feature.building,
        tags: feature.tags,
      );
    }

    if (feature.highway != null && feature.geometry.length >= 2) {
      return CampusFeature(
        id: feature.id,
        type: CampusFeatureType.path,
        geometry: feature.geometry,
        name: feature.name,
        category: feature.highway,
        tags: feature.tags,
      );
    }

    if (feature.type == 'node' &&
        (feature.name != null || feature.tags['amenity'] != null)) {
      return CampusFeature(
        id: feature.id,
        type: CampusFeatureType.pointOfInterest,
        geometry: feature.geometry,
        name: feature.name,
        category: feature.tags['amenity'],
        tags: feature.tags,
      );
    }

    return null;
  }
}
