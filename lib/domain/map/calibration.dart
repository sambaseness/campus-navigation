import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class MapControlPoint {
  const MapControlPoint({required this.source, required this.target, this.id});

  final LatLng source;
  final LatLng target;
  final String? id;
}

class MapCalibration {
  MapCalibration({required this.origin, this.controlPoints = const []}) {
    _fit();
  }

  final LatLng origin;
  final List<MapControlPoint> controlPoints;

  double _a = 1;
  double _b = 0;
  double _tx = 0;
  double _ty = 0;

  LatLng transform(LatLng source) {
    final p = _toLocal(source);
    return _fromLocal(_Point(
      _a * p.x - _b * p.y + _tx,
      _b * p.x + _a * p.y + _ty,
    ));
  }

  List<LatLng> transformPath(List<LatLng> path) =>
      path.map(transform).toList(growable: false);

  _Point _toLocal(LatLng point) {
    const latScale = 111320.0;
    final lonScale = latScale * math.cos(origin.latitude * math.pi / 180.0);
    return _Point(
      (point.longitude - origin.longitude) * lonScale,
      (point.latitude - origin.latitude) * latScale,
    );
  }

  LatLng _fromLocal(_Point point) {
    const latScale = 111320.0;
    final lonScale = latScale * math.cos(origin.latitude * math.pi / 180.0);
    return LatLng(
      origin.latitude + point.y / latScale,
      origin.longitude + point.x / lonScale,
    );
  }

  void _fit() {
    if (controlPoints.length < 2) return;

    final rows = <List<double>>[];
    final values = <double>[];

    for (final cp in controlPoints) {
      final source = _toLocal(cp.source);
      final target = _toLocal(cp.target);
      rows.add([source.x, -source.y, 1, 0]);
      values.add(target.x);
      rows.add([source.y, source.x, 0, 1]);
      values.add(target.y);
    }

    final normal = List.generate(4, (_) => List<double>.filled(5, 0));

    for (var row = 0; row < rows.length; row++) {
      for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 4; j++) {
          normal[i][j] += rows[row][i] * rows[row][j];
        }
        normal[i][4] += rows[row][i] * values[row];
      }
    }

    final solution = _solve(normal);
    if (solution == null) return;
    _a = solution[0];
    _b = solution[1];
    _tx = solution[2];
    _ty = solution[3];
  }

  List<double>? _solve(List<List<double>> matrix) {
    for (var pivot = 0; pivot < 4; pivot++) {
      var best = pivot;
      for (var row = pivot + 1; row < 4; row++) {
        if (matrix[row][pivot].abs() > matrix[best][pivot].abs()) {
          best = row;
        }
      }
      if (matrix[best][pivot].abs() < 1e-12) return null;

      final temporary = matrix[pivot];
      matrix[pivot] = matrix[best];
      matrix[best] = temporary;

      final divisor = matrix[pivot][pivot];
      for (var column = pivot; column < 5; column++) {
        matrix[pivot][column] /= divisor;
      }

      for (var row = 0; row < 4; row++) {
        if (row == pivot) continue;
        final factor = matrix[row][pivot];
        for (var column = pivot; column < 5; column++) {
          matrix[row][column] -= factor * matrix[pivot][column];
        }
      }
    }
    return List.generate(4, (index) => matrix[index][4]);
  }
}

class _Point {
  const _Point(this.x, this.y);
  final double x;
  final double y;
}
