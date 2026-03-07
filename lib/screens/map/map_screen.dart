import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../models/shelter_model.dart';
import '../../services/map/shelter_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ShelterService _shelterService = ShelterService();
  List<ShelterModel> _shelters = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadShelters();
  }

  Future<void> _loadShelters() async {
    final shelters = await _shelterService.loadShelters();
    setState(() => _shelters = shelters);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(35.6762, 139.6503),
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tasuke.tasuke',
            ),
            MarkerLayer(
              markers: _shelters.map((shelter) {
                return Marker(
                  point: LatLng(shelter.lat, shelter.lng),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showShelterInfo(shelter),
                    child: _shelterIcon(shelter.type),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Legend
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(220),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendItem(Icons.home, AppColors.safeGreen, 'Shelter'),
                _legendItem(Icons.local_hospital, AppColors.sosRed, 'Hospital'),
                _legendItem(Icons.water_drop, AppColors.accent, 'Food/Water'),
                _legendItem(Icons.people, AppColors.urgentOrange, 'Assembly'),
              ],
            ),
          ),
        ),

        // Shelter count
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(220),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_shelters.length} shelters loaded',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shelterIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'hospital':
        icon = Icons.local_hospital;
        color = AppColors.sosRed;
      case 'food_water':
        icon = Icons.water_drop;
        color = AppColors.accent;
      case 'assembly_point':
        icon = Icons.people;
        color = AppColors.urgentOrange;
      default:
        icon = Icons.home;
        color = AppColors.safeGreen;
    }
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showShelterInfo(ShelterModel shelter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shelter.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                shelter.nameJa,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    shelter.type.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const Spacer(),
                  if (shelter.capacity != null) ...[
                    Icon(Icons.groups, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Capacity: ${shelter.capacity}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    shelter.isOpen ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: shelter.isOpen ? AppColors.safeGreen : AppColors.sosRed,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    shelter.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      color: shelter.isOpen ? AppColors.safeGreen : AppColors.sosRed,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
