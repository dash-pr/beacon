import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/message_model.dart';

class SosFeedList extends StatelessWidget {
  final List<MessageModel> messages;

  const SosFeedList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isSos = msg.priority == Priority.sos;
        final isUrgent = msg.priority == Priority.urgent;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSos
              ? AppColors.sosRed.withAlpha(25)
              : isUrgent
                  ? AppColors.urgentOrange.withAlpha(20)
                  : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSos
                  ? AppColors.sosRed.withAlpha(80)
                  : isUrgent
                      ? AppColors.urgentOrange.withAlpha(60)
                      : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isSos)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sosRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.urgentOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      msg.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('HH:mm:ss').format(msg.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  msg.content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (msg.lat != null && msg.lng != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${msg.lat!.toStringAsFixed(4)}, ${msg.lng!.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (msg.hopCount > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.repeat, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          '${msg.hopCount} hop',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
