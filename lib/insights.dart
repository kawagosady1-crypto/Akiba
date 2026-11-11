import 'dart:math';

import 'package:flutter/material.dart';

import 'format.dart';
import 'i18n.dart';
import 'services.dart';
import 'state.dart';
import 'widgets.dart';

// ======================= Insights =======================

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _busy = false;

  Widget _bar(double v, double maxV, Color c) {
    final h = maxV <= 0 ? 2.0 : max(2.0, 110 * v / maxV);
    return Container(
      width: 8,
      height: h,
      decoration:
          BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _legend(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label),
        ],
      );

  Future<void> _report(DateTime month) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final ok = await Reports.shareMonthly(month);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(t('reportFailed'))));
    }
  }

  Future<void> _editLimit(String c) async {
    final v = await askText(context, '${t('limitFor')} ${t('cat_$c')}',
        number: true,
        initial: app.limits[c] == null ? '' : app.limits[c]!.round().toString());
    if (v == null) return;
    app.setLimit(c, double.tryParse(v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final days = List<DateTime>.generate(7, (i) => addDays(today, i - 6));
    final saved = days.map((d) => app.totalOn('saving', d)).toList();
    final spent = days.map((d) => app.totalOn('spending', d)).toList();
    final taken = days.map((d) => app.totalOn('withdrawal', d)).toList();
    var maxV = 0.0;
    for (final v in [...saved, ...spent, ...taken]) {
      if (v > maxV) maxV = v;
    }
    final weekFrom = days.first;
    final mFrom = app.monthStart(today);
    final mTo = app.monthEnd(today);
    final mIncome = app.totalBetween('income', mFrom, mTo);
    final mSaved = app.totalBetween('saving', mFrom, mTo);
    final mTaken = app.totalBetween('withdrawal', mFrom, mTo);
    final mSpent = app.totalBetween('spending', mFrom, mTo);

    final weekCats = app.spendingByCategory(weekFrom, today).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final locs = app.balanceByLocation().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final locTotal = locs.fold<double>(0, (a, b) => a + b.value);
    final prevMonth = DateTime(today.year, today.month - 1, 1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // This month
        SectionCard(
          title: '${t('thisMonth')} · ${monthLong(today.month)}',
          child: Column(
            children: [
              statRow(t('legendIncome'), money(mIncome), color: cs.tertiary),
              statRow(t('legendSaved'), money(mSaved), color: cs.primary),
              statRow(t('legendWithdrawn'), money(mTaken),
                  color: Colors.orange.shade800),
              statRow(t('legendSpent'), money(mSpent), color: cs.error),
              const Divider(),
              statRow(t('netSaved'), money(mSaved - mTaken), bold: true),
              if (mIncome > 0)
                statRow(t('savingRate'),
                    '${((mSaved - mTaken) / mIncome * 100).round()}%'),
            ],
          ),
        ),

        // Last 7 days chart
        SectionCard(
          title: t('thisWeek'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _bar(saved[i], maxV, cs.primary),
                                const SizedBox(width: 2),
                                _bar(spent[i], maxV, cs.error),
                                const SizedBox(width: 2),
                                _bar(taken[i], maxV, Colors.orange.shade700),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(weekdayShort(days[i].weekday),
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 16, runSpacing: 4, children: [
                _legend(cs.primary, t('legendSaved')),
                _legend(cs.error, t('legendSpent')),
                _legend(Colors.orange.shade700, t('legendWithdrawn')),
              ]),
              if (weekCats.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  tf('topSpendingLine', {
                    'c': t('cat_${weekCats.first.key}'),
                    'a': money(weekCats.first.value),
                  }),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),

        // Spending limits
        SectionCard(
          title: t('limitsMonth'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('limitsHelp'), style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              for (final c in categories)
                InkWell(
                  onTap: () => _editLimit(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(t('cat_$c'))),
                          Text(app.limits[c] == null
                              ? '${money(app.monthSpent(c))} · ${t('setLimit')}'
                              : '${num0(app.monthSpent(c))} / ${num0(app.limits[c]!)}'),
                        ]),
                        if (app.limits[c] != null) ...[
                          const SizedBox(height: 4),
                          progressBar(app.monthSpent(c) / app.limits[c]!,
                              height: 6,
                              color: app.monthSpent(c) > app.limits[c]!
                                  ? cs.error
                                  : app.monthSpent(c) >= app.limits[c]! * 0.8
                                      ? Colors.orange.shade700
                                      : cs.primary),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Where the money is
        SectionCard(
          title: t('byLocation'),
          child: locs.isEmpty
              ? Text(t('nothingYet'))
              : Column(
                  children: [
                    for (final e in locs) statRow(e.key, money(e.value)),
                    const Divider(),
                    statRow(t('total'), money(locTotal), bold: true),
                  ],
                ),
        ),

        // Monthly report
        SectionCard(
          title: t('monthlyReport'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('reportHelp'), style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.icon(
                    onPressed: () => _report(today),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(monthLong(today.month)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _report(prevMonth),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(monthLong(prevMonth.month)),
                  ),
                ]),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================= Rewards =======================

IconData _badgeIcon(String id) => switch (id) {
      'firstSave' => Icons.savings,
      'streak7' => Icons.local_fire_department,
      'streak30' => Icons.whatshot,
      'saved100k' => Icons.workspace_premium,
      'saved1m' => Icons.diamond,
      'goalDone' => Icons.flag,
      'noSpend7' => Icons.block,
      'loanRepaid' => Icons.handshake,
      _ => Icons.emoji_events,
    };

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  Widget _challengeCard(BuildContext context, String type) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = app.activeChallenge(type);
    if (c == null) {
      return SectionCard(
        title: t('ch_$type'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t('chd_$type')),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => app.startChallenge(type),
                child: Text(t('startChallenge')),
              ),
            ),
          ],
        ),
      );
    }
    final p = app.challengeProgress(c);
    String line;
    switch (type) {
      case 'week52':
        line = tf('w52Line', {
          'w': '${p.week}',
          'a': money(p.weekTarget),
          'b': money(p.weekSaved),
          't': money(p.value),
        });
        break;
      case 'nospend':
        line = tf('nospendLine', {'n': p.value.round().toString()});
        break;
      default:
        line = tf('streak30Line', {'n': p.value.round().toString()});
    }
    return SectionCard(
      title: t('ch_$type'),
      color: p.done ? cs.primaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(line),
          const SizedBox(height: 8),
          progressBar(p.fraction),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  p.done
                      ? t('challengeDone')
                      : p.ended
                          ? t('challengeEnded')
                          : '${t('started')} ${fmtDate(c.start)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: p.done ? FontWeight.w700 : null),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final ok = await confirmDialog(context, t('stopChallengeAsk'),
                      okLabel: t('stop'));
                  if (ok) app.stopChallenge(c);
                },
                child: Text(p.done || p.ended ? t('close') : t('stop')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final earned = app.earnedBadges();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionCard(
          title: '${t('badges')} · ${earned.length}/${badgeIds.length}',
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              for (final id in badgeIds)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: earned.contains(id)
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      child: Icon(
                        _badgeIcon(id),
                        color: earned.contains(id)
                            ? cs.primary
                            : cs.onSurfaceVariant.withAlpha(90),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t('badge_$id'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: earned.contains(id)
                            ? null
                            : cs.onSurfaceVariant.withAlpha(140),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(t('challenges'), style: theme.textTheme.titleMedium),
        ),
        for (final type in challengeTypes) _challengeCard(context, type),
      ],
    );
  }
}
