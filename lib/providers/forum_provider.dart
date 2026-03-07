import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../main.dart' as app;

enum ResourceType { foodWater, shelter, medical, hazard }

enum ReportStatus { pending, verified, rejected }

enum ApproverRole { responder, government, volunteer, authority }

class ResourceReport {
  final String id;
  final ResourceType type;
  final String title;
  final String description;
  final String reportedBy;
  final String reporterName;
  final DateTime reportedAt;
  final double? lat;
  final double? lng;
  final String? locationName;
  ReportStatus status;
  String? approvedBy;
  String? approverName;
  ApproverRole? approverRole;
  DateTime? approvedAt;
  int upvotes;
  final Set<String> upvotedBy;

  ResourceReport({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.reportedBy,
    required this.reporterName,
    required this.reportedAt,
    this.lat,
    this.lng,
    this.locationName,
    this.status = ReportStatus.pending,
    this.approvedBy,
    this.approverName,
    this.approverRole,
    this.approvedAt,
    this.upvotes = 0,
    Set<String>? upvotedBy,
  }) : upvotedBy = upvotedBy ?? {};
}

class ForumProvider extends ChangeNotifier {
  final List<ResourceReport> _reports = [];

  List<ResourceReport> get reports => List.unmodifiable(_reports);

  List<ResourceReport> get verifiedReports =>
      _reports.where((r) => r.status == ReportStatus.verified).toList();

  List<ResourceReport> get pendingReports =>
      _reports.where((r) => r.status == ReportStatus.pending).toList();

  List<ResourceReport> byType(ResourceType type) =>
      _reports.where((r) => r.type == type).toList();

  ForumProvider() {
    _loadDemoData();
  }

  void addReport({
    required ResourceType type,
    required String title,
    required String description,
    double? lat,
    double? lng,
    String? locationName,
  }) {
    _reports.insert(
      0,
      ResourceReport(
        id: const Uuid().v4(),
        type: type,
        title: title,
        description: description,
        reportedBy: app.deviceId,
        reporterName: app.displayName,
        reportedAt: DateTime.now(),
        lat: lat,
        lng: lng,
        locationName: locationName,
      ),
    );
    notifyListeners();
  }

  void approveReport(String reportId, {ApproverRole role = ApproverRole.volunteer}) {
    final report = _reports.firstWhere((r) => r.id == reportId);
    report.status = ReportStatus.verified;
    report.approvedBy = app.deviceId;
    report.approverName = app.displayName;
    report.approverRole = role;
    report.approvedAt = DateTime.now();
    notifyListeners();
  }

  void upvoteReport(String reportId) {
    final report = _reports.firstWhere((r) => r.id == reportId);
    if (report.upvotedBy.contains(app.deviceId)) return;
    report.upvotedBy.add(app.deviceId);
    report.upvotes++;
    notifyListeners();
  }

  void _loadDemoData() {
    _reports.addAll([
      ResourceReport(
        id: 'demo-1',
        type: ResourceType.foodWater,
        title: 'Water distribution at Shinjuku Central Park',
        description: 'Red Cross has set up a water distribution point at the south entrance. Open until 6pm. Bring your own containers.',
        reportedBy: 'gov-001',
        reporterName: 'Shinjuku Ward Office',
        reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
        lat: 35.6938,
        lng: 139.6917,
        locationName: 'Shinjuku Central Park',
        status: ReportStatus.verified,
        approvedBy: 'auth-001',
        approverName: 'Tokyo Disaster HQ',
        approverRole: ApproverRole.government,
        approvedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        upvotes: 24,
      ),
      ResourceReport(
        id: 'demo-2',
        type: ResourceType.shelter,
        title: 'Shibuya Community Center — Open Shelter',
        description: 'Capacity 200, currently at 60%. Blankets and basic meals available. Pet-friendly area on 2F.',
        reportedBy: 'vol-001',
        reporterName: 'Shibuya Volunteer Team',
        reportedAt: DateTime.now().subtract(const Duration(hours: 3)),
        lat: 35.6619,
        lng: 139.7034,
        locationName: 'Shibuya Community Center',
        status: ReportStatus.verified,
        approvedBy: 'auth-002',
        approverName: 'Shibuya Ward',
        approverRole: ApproverRole.government,
        approvedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        upvotes: 18,
      ),
      ResourceReport(
        id: 'demo-3',
        type: ResourceType.medical,
        title: 'First aid station at Yoyogi Park',
        description: 'Volunteer nurses providing basic first aid. Minor wound treatment, bandages, and pain relief available.',
        reportedBy: 'resp-001',
        reporterName: 'Japan Red Cross',
        reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
        lat: 35.6715,
        lng: 139.6950,
        locationName: 'Yoyogi Park West Gate',
        status: ReportStatus.verified,
        approvedBy: 'resp-001',
        approverName: 'Japan Red Cross',
        approverRole: ApproverRole.responder,
        approvedAt: DateTime.now().subtract(const Duration(minutes: 50)),
        upvotes: 12,
      ),
      ResourceReport(
        id: 'demo-4',
        type: ResourceType.hazard,
        title: 'Gas leak reported on Meiji-dori near Harajuku',
        description: 'Strong gas smell near the Harajuku Station construction site. Area cordoned off by fire department. Avoid the area.',
        reportedBy: 'user-001',
        reporterName: 'Local Resident',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        lat: 35.6702,
        lng: 139.7027,
        locationName: 'Meiji-dori, Harajuku',
        status: ReportStatus.pending,
        upvotes: 7,
      ),
      ResourceReport(
        id: 'demo-5',
        type: ResourceType.foodWater,
        title: 'Rice balls & tea at Ueno Station',
        description: 'Local volunteers handing out onigiri and hot tea at Ueno Station Hirokoji exit. Limited supply — first come first served.',
        reportedBy: 'user-002',
        reporterName: 'Ueno Helper',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        lat: 35.7141,
        lng: 139.7774,
        locationName: 'Ueno Station',
        status: ReportStatus.pending,
        upvotes: 3,
      ),
    ]);
  }
}
