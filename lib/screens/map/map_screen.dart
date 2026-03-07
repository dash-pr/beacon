import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/shelter_model.dart';
import '../../providers/forum_provider.dart';
import '../../services/map/shelter_service.dart';

enum MapStyle { topographic, standard }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ShelterService _shelterService = ShelterService();
  List<ShelterModel> _shelters = [];
  final MapController _mapController = MapController();
  MapStyle _mapStyle = MapStyle.topographic;
  bool _showForumMarkers = true;

  @override
  void initState() {
    super.initState();
    _loadShelters();
  }

  Future<void> _loadShelters() async {
    final shelters = await _shelterService.loadShelters();
    setState(() => _shelters = shelters);
  }

  String get _tileUrl {
    switch (_mapStyle) {
      case MapStyle.topographic:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String>? get _subdomains {
    switch (_mapStyle) {
      case MapStyle.topographic:
        return ['a', 'b', 'c'];
      case MapStyle.standard:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final forum = context.watch<ForumProvider>();
    final forumReports = forum.verifiedReports;

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
              urlTemplate: _tileUrl,
              subdomains: _subdomains ?? const [],
              userAgentPackageName: 'com.beacon.app',
            ),
            // Shelter markers
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
            // Forum resource markers
            if (_showForumMarkers)
              MarkerLayer(
                markers: forumReports
                    .where((r) => r.lat != null && r.lng != null)
                    .map((r) {
                  return Marker(
                    point: LatLng(r.lat!, r.lng!),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _showResourceInfo(r),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _resourceColor(r.type),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _resourceColor(r.type).withAlpha(80),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(_resourceIcon(r.type), color: Colors.white, size: 18),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),

        // Map style toggle
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(230),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outline.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapStyleButton('Topo', MapStyle.topographic, Icons.terrain),
                _mapStyleButton('Map', MapStyle.standard, Icons.map),
              ],
            ),
          ),
        ),

        // Legend
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(230),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outline.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendItem(Icons.home, AppColors.safeGreen, 'Shelter'),
                _legendItem(Icons.local_hospital, AppColors.sosRed, 'Hospital'),
                _legendItem(Icons.water_drop, AppColors.primary, 'Food/Water'),
                _legendItem(Icons.people, AppColors.urgentOrange, 'Assembly'),
                const Divider(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _showForumMarkers = !_showForumMarkers),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showForumMarkers ? Icons.visibility : Icons.visibility_off,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Community reports',
                        style: TextStyle(
                          fontSize: 10,
                          color: _showForumMarkers ? AppColors.textSecondary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Info bar
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(230),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outline.withAlpha(80)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_shelters.length} shelters',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                if (_showForumMarkers)
                  Text(
                    '${forumReports.where((r) => r.lat != null).length} community reports',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapStyleButton(String label, MapStyle style, IconData icon) {
    final selected = _mapStyle == style;
    return GestureDetector(
      onTap: () => setState(() => _mapStyle = style),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primary : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
        color = AppColors.primary;
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

  Color _resourceColor(ResourceType type) {
    switch (type) {
      case ResourceType.foodWater: return AppColors.info;
      case ResourceType.shelter: return AppColors.safeGreen;
      case ResourceType.medical: return AppColors.urgentOrange;
      case ResourceType.hazard: return AppColors.sosRed;
    }
  }

  IconData _resourceIcon(ResourceType type) {
    switch (type) {
      case ResourceType.foodWater: return Icons.water_drop;
      case ResourceType.shelter: return Icons.home;
      case ResourceType.medical: return Icons.medical_services;
      case ResourceType.hazard: return Icons.warning;
    }
  }

  void _showShelterInfo(ShelterModel shelter) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shelter.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(shelter.nameJa, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(shelter.type.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  if (shelter.capacity != null) ...[
                    Icon(Icons.groups, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text('Capacity: ${shelter.capacity}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(shelter.isOpen ? Icons.check_circle : Icons.cancel, size: 16, color: shelter.isOpen ? AppColors.safeGreen : AppColors.sosRed),
                  const SizedBox(width: 6),
                  Text(shelter.isOpen ? 'Open' : 'Closed', style: TextStyle(color: shelter.isOpen ? AppColors.safeGreen : AppColors.sosRed, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showResourceInfo(ResourceReport report) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_resourceIcon(report.type), color: _resourceColor(report.type), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(report.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(report.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
              if (report.locationName != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(report.locationName!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ],
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(report.reporterName, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
              if (report.status == ReportStatus.verified && report.approverName != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.verified_user, size: 14, color: AppColors.safeGreen),
                  const SizedBox(width: 4),
                  Text('Approved by: ${report.approverName}', style: const TextStyle(fontSize: 11, color: AppColors.safeGreen)),
                ]),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
