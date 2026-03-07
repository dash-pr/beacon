import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/ai/image_analysis_service.dart';
import '../../../services/translation/translation_service.dart';

class TriageResultCard extends StatefulWidget {
  final TriageResult result;

  const TriageResultCard({super.key, required this.result});

  @override
  State<TriageResultCard> createState() => _TriageResultCardState();
}

class _TriageResultCardState extends State<TriageResultCard> {
  String? _translatedOcrText;
  bool _isTranslating = false;

  Future<void> _translateOcr() async {
    if (widget.result.extractedText.isEmpty) return;
    setState(() => _isTranslating = true);
    try {
      final service = TranslationService();
      await service.initialize();
      final result = await service.translate(widget.result.extractedText);
      setState(() {
        _translatedOcrText = result;
        _isTranslating = false;
      });
    } catch (_) {
      setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface.withAlpha(230),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                _hazardIcon,
                const SizedBox(width: 10),
                Text(
                  widget.result.hazardType.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _severityBadge,
              ],
            ),
            const SizedBox(height: 12),

            // Labels
            if (widget.result.labels.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.result.labels.take(5).map((label) {
                  return Chip(
                    label: Text(label, style: const TextStyle(fontSize: 10)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.surfaceLight,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Extracted text (Image-to-Text / OCR)
            if (widget.result.extractedText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.text_fields, size: 14, color: AppColors.accentLight),
                        const SizedBox(width: 6),
                        const Text(
                          'Extracted Text (OCR)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentLight,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: widget.result.extractedText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Text copied'), duration: Duration(seconds: 1)),
                            );
                          },
                          child: const Icon(Icons.copy, size: 14, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isTranslating ? null : _translateOcr,
                          child: _isTranslating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                )
                              : const Icon(Icons.translate, size: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.result.extractedText,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_translatedOcrText != null) ...[
                      const Divider(height: 12, color: AppColors.textMuted),
                      Text(
                        _translatedOcrText!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action (EN)
            Text(
              widget.result.actionEn,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            // Action (JA)
            Text(
              widget.result.actionJa,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _hazardIcon {
    IconData icon;
    Color color;
    switch (widget.result.hazardType) {
      case 'fire':
        icon = Icons.local_fire_department;
        color = AppColors.sosRed;
      case 'medical':
        icon = Icons.medical_services;
        color = AppColors.urgentOrange;
      case 'flood':
        icon = Icons.water;
        color = AppColors.accent;
      case 'structural':
        icon = Icons.domain_disabled;
        color = AppColors.warningYellow;
      default:
        icon = Icons.help_outline;
        color = AppColors.textMuted;
    }
    return Icon(icon, color: color, size: 28);
  }

  Widget get _severityBadge {
    Color color;
    switch (widget.result.severity) {
      case 'critical':
        color = AppColors.sosRed;
      case 'high':
        color = AppColors.urgentOrange;
      case 'medium':
        color = AppColors.warningYellow;
      default:
        color = AppColors.safeGreen;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.result.severity.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
