import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../l10n.dart';
import 'neo_design.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (controller.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 90),
          child: NeoSurface(
            accent: NeoColors.cyan,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: NeoColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: NeoColors.cyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    color: NeoColors.cyan,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  strings.text('history_empty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: controller.history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = controller.history[index];
        final accent = _color(entry.action);
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 240 + index.clamp(0, 8) * 32),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: child,
            ),
          ),
          child: NeoSurface(
            accent: accent,
            radius: 21,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  child: Icon(_icon(entry.action), color: accent, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              entry.title.isEmpty
                                  ? entry.action.name
                                  : entry.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${entry.accountName}  ·  '
                        '${DateFormat.yMd(locale).add_Hm().format(entry.timestamp)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (entry.details?.isNotEmpty == true) ...<Widget>[
                        const SizedBox(height: 7),
                        Text(
                          entry.details!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _icon(HistoryAction action) => switch (action) {
    HistoryAction.confirmationSeen => Icons.notifications_outlined,
    HistoryAction.accepted => Icons.check_circle_outline_rounded,
    HistoryAction.declined => Icons.cancel_outlined,
    HistoryAction.autoAccepted => Icons.auto_awesome_rounded,
    HistoryAction.autoSkipped => Icons.rule_rounded,
    HistoryAction.qrApproved => Icons.qr_code_scanner_rounded,
    HistoryAction.authenticatorAdded => Icons.add_moderator_outlined,
    HistoryAction.backupCreated => Icons.backup_outlined,
    HistoryAction.backupRestored => Icons.restore_rounded,
    HistoryAction.error => Icons.error_outline_rounded,
  };

  Color _color(HistoryAction action) => switch (action) {
    HistoryAction.accepted || HistoryAction.autoAccepted => NeoColors.mint,
    HistoryAction.declined || HistoryAction.error => NeoColors.danger,
    HistoryAction.autoSkipped => NeoColors.amber,
    HistoryAction.qrApproved => NeoColors.cyan,
    HistoryAction.backupCreated ||
    HistoryAction.backupRestored => NeoColors.violet,
    HistoryAction.confirmationSeen ||
    HistoryAction.authenticatorAdded => NeoColors.blue,
  };
}
