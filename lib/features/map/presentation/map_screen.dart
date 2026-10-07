import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../ar/presentation/ar_navigation_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const campusCenter = LatLng(14.7167, -17.4677);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigation'),
        actions: [
          IconButton(
            tooltip: 'AR navigation',
            icon: const Icon(Icons.view_in_ar),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ArNavigationScreen(
                    destinationName: 'Selected destination',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: campusCenter,
          initialZoom: 17,
          minZoom: 14,
          maxZoom: 21,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.campusnavigation.app',
            maxZoom: 19,
          ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}
