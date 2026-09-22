import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main() async {
  const endpoint = 'https://overpass-api.de/api/interpreter';
  const query = '''
[out:json][timeout:60];
(
  way["building"](14.678,-17.472,14.686,-17.462);
  way["highway"](14.678,-17.472,14.686,-17.462);
  way["amenity"](14.678,-17.472,14.686,-17.462);
  node["amenity"](14.678,-17.472,14.686,-17.462);
  node["name"](14.678,-17.472,14.686,-17.462);
);
out body geom;
''';

  stdout.writeln('Downloading ESP OSM snapshot…');

  final response = await http.get(
    Uri.parse(endpoint).replace(queryParameters: {'data': query}),
    headers: const {'Accept': 'application/json'},
  );

  if (response.statusCode != 200) {
    throw HttpException(
      'Overpass returned ${response.statusCode}',
      uri: Uri.parse(endpoint),
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final elements = json['elements'];
  if (elements is! List) {
    throw const FormatException('Overpass response has no elements array.');
  }

  final file = File('assets/data/esp_osm.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'source': 'OpenStreetMap / Overpass',
      'bbox': {
        'south': 14.678,
        'west': -17.472,
        'north': 14.686,
        'east': -17.462,
      },
      'elements': elements,
    }),
  );

  stdout.writeln('Wrote ${elements.length} OSM elements to ${file.path}');
}
