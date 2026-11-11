import 'package:flutter/material.dart';

import 'format.dart';
import 'i18n.dart';
import 'state.dart';

Color statusColor(DayStatus s) => switch (s) {
      DayStatus.above => Colors.green.shade700,
      DayStatus.on => Colors.teal.shade600,
      DayStatus.short => Colors.orange.shade800,
      DayStatus.missed => Colors.red.shade700,
      DayStatus.pending => Colors.grey.shade600,
      DayStatus.done => Colors.blueGrey.shade600,
    };

String statusLabel(DayStatus s) => switch (s) {
      DayStatus.above => t('statusAbove'),
      DayStatus.on => t('statusOn'),
      DayStatus.short => t('statusShort'),
      DayStatus.missed => t('statusMissed'),
      DayStatus.pending => t('statusPending'),
      DayStatus.done => t('statusDone'),
    };

String goalLabel(String id) {
  if (id == bufferId) return t('buffer');
  return app.goalById(id)?.name ?? '-';
}

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color? color;
  const SectionCard({super.key, this.title, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

Widget statRow(String label, String value, {Color? color, bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  final DayStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status),
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class TxnTile extends StatelessWidget {
  final Txn tx;
  const TxnTile(this.tx, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSave = tx.kind == 'saving';
    final parts = <String>[
      shortDate(tx.date),
      if (tx.location.isNotEmpty) tx.location,
      if (tx.note.isNotEmpty) tx.note,
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isSave ? cs.primaryContainer : cs.errorContainer,
        child: Icon(
          isSave ? Icons.savings_outlined : Icons.shopping_bag_outlined,
          color: isSave ? cs.onPrimaryContainer : cs.onErrorContainer,
        ),
      ),
      title: Text(isSave ? goalLabel(tx.goalId) : t('cat_${tx.category}')),
      subtitle: Text(parts.join(' · ')),
      trailing: Text(
        '${isSave ? '+' : '-'}${num0(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isSave ? cs.primary : cs.error,
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  const GoalCard(this.goal, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dayOnly(DateTime.now());
    final saved = app.savedFor(goal.id);
    final double pct =
        goal.target <= 0 ? 0.0 : (saved / goal.target).clamp(0.0, 1.0).toDouble();
    final done = saved >= goal.target;
    final left = daysBetween(today, goal.deadline);
    final perDay = app.targetFor(goal, today);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(goal.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Text(
                    goal.type == 'main' ? t('mainGoal') : t('miniGoal'),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text('${money(saved)} ${t('of')} ${money(goal.target)}  ·  ${(pct * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 4),
              Text(
                done
                    ? t('goalDone')
                    : '${moneyUp(perDay)} ${t('perDay')}  ·  ${t('due')} ${fmtDate(goal.deadline)}'
                        '${left >= 0 ? '  ·  $left ${t('daysLeft')}' : '  ·  ${t('deadlinePassed')}'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String message,
    {String? okLabel}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(okLabel ?? t('ok'))),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> askText(BuildContext context, String title,
    {int maxLines = 1}) async {
  final ctl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctl,
        autofocus: true,
        maxLines: maxLines,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: Text(t('ok'))),
      ],
    ),
  );
}
