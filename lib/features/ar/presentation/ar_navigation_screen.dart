import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class ArNavigationScreen extends StatefulWidget {
  const ArNavigationScreen({
    super.key,
    this.destinationName = 'Destination',
  });

  final String destinationName;

  @override
  State<ArNavigationScreen> createState() => _ArNavigationScreenState();
}

class _ArNavigationScreenState extends State<ArNavigationScreen> {
  ARSessionManager? _session;
  ARObjectManager? _objects;
  ARAnchorManager? _anchors;
  final List<ARAnchor> _placedAnchors = [];
  final List<ARNode> _placedNodes = [];
  bool _placing = false;
  String _status = 'Point your camera at the ground.';

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'AR → ' + widget.destinationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _placing ? null : _clearMarkers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset marker'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onCreated(
    ARSessionManager session,
    ARObjectManager objects,
    ARAnchorManager anchors,
    ARLocationManager locations,
  ) {
    _session = session;
    _objects = objects;
    _anchors = anchors;

    session.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
    );
    objects.onInitialize();
    session.onPlaneOrPointTap = _onPlaneTapped;
  }

  Future<void> _onPlaneTapped(List<ARHitTestResult> hits) async {
    if (_placing || hits.isEmpty) return;

    final hit = hits.firstWhere(
      (hit) => hit.type == ARHitTestResultType.plane,
      orElse: () => hits.first,
    );

    setState(() {
      _placing = true;
      _status = 'Placing destination marker…';
    });

    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final addedAnchor = await _anchors?.addAnchor(anchor) ?? false;

    if (!addedAnchor) {
      setState(() {
        _placing = false;
        _status = 'Could not place marker. Try another surface.';
      });
      return;
    }

    _placedAnchors.add(anchor);

    final node = ARNode(
      name: 'destination-marker',
      type: NodeType.localGLB,
      uri: 'assets/models/arrow.glb',
      scale: Vector3.all(0.35),
      position: Vector3(0, 0.03, 0),
      rotation: Vector4(0, 1, 0, 0),
    );

    final addedNode = await _objects?.addNode(
          node,
          planeAnchor: anchor,
        ) ??
        false;

    if (addedNode) {
      _placedNodes.add(node);
      setState(() {
        _placing = false;
        _status = 'Marker placed. Walk toward the destination.';
      });
    } else {
      await _anchors?.removeAnchor(anchor);
      _placedAnchors.remove(anchor);
      setState(() {
        _placing = false;
        _status = 'Could not render marker. Try again.';
      });
    }
  }

  Future<void> _clearMarkers() async {
    for (final node in _placedNodes) {
      await _objects?.removeNode(node);
    }
    for (final anchor in _placedAnchors) {
      await _anchors?.removeAnchor(anchor);
    }
    _placedNodes.clear();
    _placedAnchors.clear();
    setState(() => _status = 'Point your camera at the ground.');
  }
}
