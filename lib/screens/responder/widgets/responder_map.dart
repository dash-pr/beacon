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
    final markers = messages
        .where((m) => m.lat != null && m.lng != null)
        .map((m) {
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

    // Center on first message with location, or default to Tokyo
    final center = messages.isNotEmpty && messages.first.lat != null
        ? LatLng(messages.first.lat!, messages.first.lng!)
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
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
