import 'package:latlong2/latlong.dart';

import '../../domain/campus/campus_feature.dart';

class DestinationSelection {
  const DestinationSelection({
    required this.feature,
    required this.point,
  });

  final CampusFeature feature;
  final LatLng point;
}
