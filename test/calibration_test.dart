import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:campus_navigation/domain/map/calibration.dart';

void main() {
  test('identity calibration keeps coordinates unchanged', () {
    const origin = LatLng(14.7167, -17.4677);
    final calibration = MapCalibration(origin: origin);
    const point = LatLng(14.717, -17.4672);
    final result = calibration.transform(point);
    expect(result.latitude, closeTo(point.latitude, 1e-10));
    expect(result.longitude, closeTo(point.longitude, 1e-10));
  });

  test('translation is learned from control points', () {
    const origin = LatLng(14.7167, -17.4677);
    final calibration = MapCalibration(
      origin: origin,
      controlPoints: const [
        MapControlPoint(
          source: LatLng(14.7167, -17.4677),
          target: LatLng(14.7168, -17.4676),
        ),
        MapControlPoint(
          source: LatLng(14.7177, -17.4677),
          target: LatLng(14.7178, -17.4676),
        ),
      ],
    );
    final result = calibration.transform(const LatLng(14.7172, -17.4672));
    expect(result.latitude, closeTo(14.7173, 1e-7));
    expect(result.longitude, closeTo(-17.4671, 1e-7));
  });
}
