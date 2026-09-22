import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/map/calibration.dart';

class CalibrationRepository {
  const CalibrationRepository({
    this.assetPath = 'assets/data/calibration.json',
  });

  final String assetPath;

  Future<MapCalibration> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final originJson = json['origin'] as Map<String, dynamic>?;
    if (originJson == null) {
      throw const FormatException('Calibration has no origin.');
    }

    final latitude = originJson['latitude'];
    final longitude = originJson['longitude'];
    if (latitude is! num || longitude is! num) {
      throw const FormatException('Calibration origin is invalid.');
    }

    final controlPointsJson = json['controlPoints'];
    final controlPoints = <MapControlPoint>[];

    if (controlPointsJson is List) {
      for (final rawPoint in controlPointsJson) {
        if (rawPoint is! Map<String, dynamic>) continue;

        final source = _parsePoint(rawPoint['source']);
        final target = _parsePoint(rawPoint['target']);
        if (source != null && target != null) {
          controlPoints.add(
            MapControlPoint(
              id: rawPoint['id']?.toString(),
              source: source,
              target: target,
            ),
          );
        }
      }
    }

    return MapCalibration(
      origin: LatLng(latitude.toDouble(), longitude.toDouble()),
      controlPoints: controlPoints,
    );
  }

  static LatLng? _parsePoint(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final latitude = raw['latitude'];
    final longitude = raw['longitude'];
    if (latitude is! num || longitude is! num) return null;
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }
}
