import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/shelter_model.dart';
import '../../providers/forum_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/message_provider.dart';
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
  LatLng? _currentLocation;
  StreamSubscription<Position>? _locationSub;

  // Niseko backcountry center
  static const _niseko = LatLng(42.8604, 140.6874);
  // Tokyo center
  static const _tokyo = LatLng(35.6762, 139.6503);

  @override
  void initState() {
    super.initState();
    // Set fallback location immediately so the blue dot and button show right away
    _currentLocation = _niseko;
    _loadShelters();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Emulator or no GPS — use map center as fallback
        if (mounted) {
          setState(() => _currentLocation = _initialCenter);
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        // Permission denied — use map center as fallback
        if (mounted) {
          setState(() => _currentLocation = _initialCenter);
        }
        return;
      }

      // Get initial position with timeout
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        if (mounted) {
          setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
        }
      } catch (_) {
        // getCurrentPosition timed out — try last known
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null && mounted) {
          setState(() => _currentLocation = LatLng(lastPos.latitude, lastPos.longitude));
        } else if (mounted) {
          // No last known — use map center
          setState(() => _currentLocation = _initialCenter);
        }
      }

      // Stream updates
      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (mounted) {
          setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
        }
      });
    } catch (e) {
      // Any error — use map center as fallback so the dot always shows
      if (mounted) {
        setState(() => _currentLocation = _initialCenter);
      }
    }
  }

  Future<void> _loadShelters() async {
    final shelters = await _shelterService.loadShelters();
    setState(() => _shelters = shelters);
  }

  LatLng get _initialCenter =>
      _mapStyle == MapStyle.topographic ? _niseko : _tokyo;

  double get _initialZoom =>
      _mapStyle == MapStyle.topographic ? 13.0 : 12.0;

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

  void _sendSos(BuildContext context) {
    final locale = context.read<LocaleProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.t('sos_confirm')),
        content: Text(locale.t('sos_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final meshProvider = context.read<MeshProvider>();
              final messageProvider = context.read<MessageProvider>();
              final locText = _currentLocation != null
                  ? ' (${_currentLocation!.latitude.toStringAsFixed(5)}, ${_currentLocation!.longitude.toStringAsFixed(5)})'
                  : '';
              messageProvider.sendTextMessage(
                'SOS — EMERGENCY — I need help at my current location$locText',
                meshProvider.service,
                lat: _currentLocation?.latitude,
                lng: _currentLocation?.longitude,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.sosRed),
            child: Text(locale.t('send_sos')),
          ),
        ],
      ),
    );
  }

  void _switchStyle(MapStyle style) {
    setState(() => _mapStyle = style);
    _mapController.move(
      style == MapStyle.topographic ? _niseko : _tokyo,
      style == MapStyle.topographic ? 13.0 : 12.0,
    );
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
            initialCenter: _initialCenter,
            initialZoom: _initialZoom,
          ),
          children: [
            TileLayer(
              urlTemplate: _tileUrl,
              subdomains: _subdomains ?? const [],
              userAgentPackageName: 'com.beacon.app',
            ),
            // Shelter markers (only in standard/map mode)
            if (_mapStyle == MapStyle.standard)
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
            // Current location marker
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(100),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                if (_mapStyle == MapStyle.topographic) ...[
                  _legendItem(Icons.terrain, const Color(0xFF8B6914), 'Niseko Backcountry'),
                  _legendItem(Icons.my_location, AppColors.primary, 'Your Location'),
                ] else ...[
                  _legendItem(Icons.home, AppColors.safeGreen, 'Shelter'),
                  _legendItem(Icons.local_hospital, AppColors.sosRed, 'Hospital'),
                  _legendItem(Icons.water_drop, AppColors.primary, 'Food/Water'),
                  _legendItem(Icons.people, AppColors.urgentOrange, 'Assembly'),
                ],
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

        // SOS button (topo mode)
        if (_mapStyle == MapStyle.topographic)
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'map_sos',
              backgroundColor: AppColors.sosRed,
              onPressed: () => _sendSos(context),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 22),
                  Text('SOS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

        // Center on my location button
        if (_currentLocation != null)
          Positioned(
            bottom: _mapStyle == MapStyle.topographic ? 140 : 80,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'center_location',
              backgroundColor: AppColors.surface,
              onPressed: () {
                _mapController.move(_currentLocation!, _mapController.camera.zoom);
              },
              child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
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
                if (_mapStyle == MapStyle.topographic)
                  const Row(
                    children: [
                      Icon(Icons.terrain, size: 14, color: Color(0xFF8B6914)),
                      SizedBox(width: 6),
                      Text(
                        'Niseko Backcountry',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  )
                else
                  Text(
                    '${_shelters.length} shelters',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                if (_currentLocation != null)
                  Row(
                    children: [
                      const Icon(Icons.my_location, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                if (_showForumMarkers && _mapStyle == MapStyle.standard)
                  Text(
                    '${forumReports.where((r) => r.lat != null).length} reports',
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
      onTap: () => _switchStyle(style),
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
                  const Icon(Icons.category, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(shelter.type.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  if (shelter.capacity != null) ...[
                    const Icon(Icons.groups, size: 16, color: AppColors.textMuted),
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
