import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/message_model.dart';

class ResponderMap extends StatelessWidget {
  final List<MessageModel> messages;

  const ResponderMap({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final located = messages
        .where((m) => m.lat != null && m.lng != null)
        .toList();

    // Build pin markers
    final markers = located.map((m) {
      final isSos = m.priority == Priority.sos;
      return Marker(
        point: LatLng(m.lat!, m.lng!),
        width: 36,
        height: 36,
        child: Tooltip(
          message: '${m.senderName}: ${m.content.length > 30 ? '${m.content.substring(0, 30)}...' : m.content}',
          child: Container(
            decoration: BoxDecoration(
              color: isSos ? AppColors.sosRed : AppColors.urgentOrange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: (isSos ? AppColors.sosRed : AppColors.urgentOrange).withAlpha(120),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isSos ? Icons.emergency : Icons.warning,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }).toList();

    // Build heatmap circles — cluster nearby messages
    final heatCircles = _buildHeatCircles(located);

    // Center on first message with location, or default to Tokyo
    final center = located.isNotEmpty
        ? LatLng(located.first.lat!, located.first.lng!)
        : const LatLng(35.6762, 139.6503);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.beacon.app',
            ),
            // Heatmap circles (underneath pins)
            CircleLayer(circles: heatCircles),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  List<CircleMarker> _buildHeatCircles(List<MessageModel> located) {
    // Create a heatmap effect: larger/more opaque circles where messages cluster
    final circles = <CircleMarker>[];

    for (final m in located) {
      final isSos = m.priority == Priority.sos;
      final isUrgent = m.priority == Priority.urgent;

      // Count nearby messages for intensity
      int nearby = 0;
      for (final other in located) {
        if (other.id == m.id) continue;
        final dist = _distanceMeters(m.lat!, m.lng!, other.lat!, other.lng!);
        if (dist < 2000) nearby++;
      }

      final intensity = (nearby + 1).clamp(1, 5);
      final baseColor = isSos
          ? AppColors.sosRed
          : isUrgent
              ? AppColors.urgentOrange
              : AppColors.warningYellow;

      // Outer glow
      circles.add(CircleMarker(
        point: LatLng(m.lat!, m.lng!),
        radius: 40.0 + (intensity * 15.0),
        color: baseColor.withAlpha(15 + (intensity * 8)),
        borderColor: Colors.transparent,
        borderStrokeWidth: 0,
      ));

      // Inner heat
      circles.add(CircleMarker(
        point: LatLng(m.lat!, m.lng!),
        radius: 20.0 + (intensity * 8.0),
        color: baseColor.withAlpha(30 + (intensity * 12)),
        borderColor: Colors.transparent,
        borderStrokeWidth: 0,
      ));
    }

    return circles;
  }

  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lng2 - lng1) * p)) / 2;
    return 12742000 * math.asin(math.sqrt(a)); // 2 * R * asin...
  }
}
