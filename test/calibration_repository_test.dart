import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calibration configuration has the expected shape', () {
    const raw = '''
{
  "version": 1,
  "origin": {
    "latitude": 14.68102,
    "longitude": -17.46643
  },
  "controlPoints": []
}
''';

    final json = jsonDecode(raw) as Map<String, dynamic>;
    final origin = json['origin'] as Map<String, dynamic>;

    expect(origin['latitude'], 14.68102);
    expect(origin['longitude'], -17.46643);
    expect(json['controlPoints'], isEmpty);
  });
}
