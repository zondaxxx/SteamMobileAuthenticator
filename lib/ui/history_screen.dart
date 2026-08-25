import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../l10n.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (controller.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            strings.text('history_empty'),
            textAlign: TextAlign.center,
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
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(_icon(entry.action))),
            title: Text(entry.title.isEmpty ? entry.action.name : entry.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${entry.accountName} · '
                  '${DateFormat.yMd(locale).add_Hm().format(entry.timestamp)}',
                ),
                if (entry.details?.isNotEmpty == true)
                  Text(
                    entry.details!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
}
