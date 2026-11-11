import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'i18n.dart';
import 'sheets.dart';
import 'state.dart';
import 'widgets.dart';

// ======================= Onboarding =======================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  final _amount = TextEditingController();
  DateTime _deadline = addDays(dayOnly(DateTime.now()), 90);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _amount.dispose();
    super.dispose();
  }

  double get _amt => double.tryParse(_amount.text) ?? 0;

  Future<void> _pickDeadline() async {
    final today = dayOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: addDays(today, 1),
      lastDate: addDays(today, 3650),
    );
    if (d != null) setState(() => _deadline = d);
  }

  void _start() {
    if (_goal.text.trim().isEmpty) {
      setState(() => _error = t('required'));
      return;
    }
    if (_amt <= 0) {
      setState(() => _error = t('invalidAmount'));
      return;
    }
    final today = dayOnly(DateTime.now());
    app.completeOnboarding(
      _name.text,
      Goal(
        id: newId(),
        name: _goal.text.trim(),
        type: 'main',
        target: _amt,
        start: today,
        deadline: dayOnly(_deadline),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final left = max(1, daysBetween(today, _deadline) + 1);
    final preview = _amt > 0 ? _amt / left : 0.0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Icon(Icons.savings, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(t('welcome'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(t('welcomeSub'),
                textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(t('language'), style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sw', label: Text('Kiswahili')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {app.lang},
              onSelectionChanged: (s) => setState(() => app.setLang(s.first)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: t('yourName'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Text(t('firstGoal'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _goal,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  labelText: t('goalName'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: t('goalAmount'),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.event),
              label: Text('${t('deadline')}: ${fmtDate(_deadline)}'),
            ),
            if (preview > 0) ...[
              const SizedBox(height: 16),
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(t('dailyTargetPreview'),
                          style: TextStyle(color: cs.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text(moneyUp(preview),
                          style: theme.textTheme.headlineSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: cs.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(t('start')),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Shell (bottom tabs) =======================

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final pages = <Widget>[
          HomeScreen(onSeeAll: () => setState(() => _index = 2)),
          GoalsScreen(),
          HistoryScreen(),
          InsightsScreen(),
        ];
        final titles = [
          app.userName.isEmpty ? t('hello') : '${t('hello')}, ${app.userName}',
          t('goals'),
          t('history'),
          t('insights'),
        ];
        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_index]),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: t('settings'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          body: pages[_index],
          floatingActionButton: app.activeGoals.isEmpty && _index == 0
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => showLogSheet(context),
                  icon: const Icon(Icons.add),
                  label: Text(t('log')),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: t('home')),
              NavigationDestination(
                  icon: const Icon(Icons.flag_outlined),
                  selectedIcon: const Icon(Icons.flag),
                  label: t('goals')),
              NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: const Icon(Icons.calendar_month),
                  label: t('history')),
              NavigationDestination(
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: const Icon(Icons.insights),
                  label: t('insights')),
            ],
          ),
        );
      },
    );
  }
}

// ======================= Home =======================

class HomeScreen extends StatelessWidget {
  final VoidCallback onSeeAll;
  const HomeScreen({super.key, required this.onSeeAll});

  Future<void> _extend(BuildContext context, Goal g) async {
    final today = dayOnly(DateTime.now());
    final first = addDays(today, 1);
    final init = g.deadline.isBefore(first) ? first : addDays(g.deadline, 7);
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: addDays(today, 3650),
    );
    if (d != null) {
      g.deadline = dayOnly(d);
      app.updateGoal(g);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final g = app.mainGoal;
    final children = <Widget>[];

    if (g == null) {
      children.add(SectionCard(
        child: Center(
          child: Column(
            children: [
              Icon(Icons.savings_outlined, size: 48, color: cs.primary),
              const SizedBox(height: 12),
              Text(t('noMainGoal'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => showGoalSheet(context, type: 'main'),
                child: Text(t('createGoal')),
              ),
            ],
          ),
        ),
      ));
    } else {
      final saved = app.savedFor(g.id);
      final done = saved >= g.target;
      final stats = app.dayStats(g);
      final ts = stats.isNotEmpty
          ? stats.last
          : DayStat(today, app.targetFor(g, today), 0);
      final y = stats.length >= 2 ? stats[stats.length - 2] : null;

      children.add(GoalCard(g, onTap: () => showGoalSheet(context, goal: g)));

      if (done) {
        children.add(SectionCard(
          color: cs.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('goalDone'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  app.archiveGoal(g);
                  showGoalSheet(context, type: 'main');
                },
                child: Text(t('startNewGoal')),
              ),
            ],
          ),
        ));
      } else {
        // Today
        final met = ts.met;
        children.add(SectionCard(
          title: t('today'),
          color: met ? cs.primaryContainer : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statRow(t('todayTarget'), moneyUp(ts.target), bold: true),
              statRow(t('savedToday'), money(ts.actual)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: ts.target <= 0
                    ? 1.0
                    : (ts.actual / ts.target).clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 10),
              if (met)
                Text(
                  ts.extra > 0
                      ? '${t('targetMet')}  ${t('extraToday')}: ${money(ts.extra)}'
                      : t('targetMet'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: cs.primary),
                )
              else
                Text('${t('remainingToday')}: ${moneyUp(ts.shortfall)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ));

        // Shortfall recovery
        if (y != null && !y.met) {
          children.add(SectionCard(
            color: cs.tertiaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  y.actual <= 0
                      ? tf('missedYesterday', {'b': moneyUp(ts.target)})
                      : tf('shortYesterday', {
                          'a': moneyUp(y.shortfall),
                          'b': moneyUp(ts.target)
                        }),
                  style: TextStyle(color: cs.onTertiaryContainer),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _extend(context, g),
                    icon: const Icon(Icons.event_repeat),
                    label: Text(t('extendDeadline')),
                  ),
                ),
              ],
            ),
          ));
        }

        // Streak + projection
        final streak = app.streak(g);
        final finish = app.projectedFinish(g);
        final onTrack = finish != null && !finish.isAfter(g.deadline);
        children.add(Row(
          children: [
            Expanded(
              child: SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.local_fire_department,
                          color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Text('$streak',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ]),
                    Text(t('streak'), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('projected'), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    if (finish == null)
                      Text(t('noProjection'), style: theme.textTheme.bodySmall)
                    else ...[
                      Text(fmtDate(finish),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(onTrack ? t('onTrack') : t('behind'),
                          style: TextStyle(
                              color: onTrack
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ));
      }

      // Extra pot
      children.add(SectionCard(
        title: t('extraPot'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            statRow(t('extraTotal'), money(app.totalExtra(g)), bold: true),
            statRow(t('buffer'), money(app.bufferTotal)),
            const SizedBox(height: 10),
            Text(t('extraGoesTo'), style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'goal', label: Text(t('mainGoal'))),
                ButtonSegment(value: 'buffer', label: Text(t('buffer'))),
              ],
              selected: {g.extraDest},
              onSelectionChanged: (s) {
                g.extraDest = s.first;
                app.updateGoal(g);
              },
            ),
          ],
        ),
      ));
    }

    // Today's money in and out
    children.add(SectionCard(
      child: Column(
        children: [
          statRow(t('savedToday'), money(app.totalOn('saving', today)),
              color: cs.primary, bold: true),
          statRow(t('spentToday'), money(app.totalOn('spending', today)),
              color: cs.error, bold: true),
        ],
      ),
    ));

    // Mini-goals
    final minis = app.miniGoals;
    if (minis.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(t('miniGoals'), style: theme.textTheme.titleMedium),
      ));
      for (final m in minis) {
        children.add(GoalCard(m, onTap: () => showGoalSheet(context, goal: m)));
      }
    }

    // Recent entries
    final recent = app.sortedTxns.take(5).toList();
    children.add(SectionCard(
      title: t('recent'),
      child: recent.isEmpty
          ? Text(t('noEntries'))
          : Column(
              children: [
                for (final x in recent) TxnTile(x),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: onSeeAll, child: Text(t('seeAll'))),
                ),
              ],
            ),
    ));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: children,
    );
  }
}

// ======================= Goals =======================

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = app.activeGoals;
    final finished = app.finishedGoals;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        for (final g in active)
          GoalCard(g, onTap: () => showGoalSheet(context, goal: g)),
        OutlinedButton.icon(
          onPressed: () => showGoalSheet(context,
              type: app.mainGoal == null ? 'main' : 'mini'),
          icon: const Icon(Icons.add),
          label: Text(app.mainGoal == null ? t('createGoal') : t('addMini')),
        ),
        if (finished.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(t('completed'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final g in finished)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(g.name),
              subtitle: Text(
                  '${money(app.savedFor(g.id))} ${t('of')} ${money(g.target)}'),
            ),
        ],
      ],
    );
  }
}

// ======================= History =======================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _mode = 'days';

  Widget _days(BuildContext context) {
    final g = app.mainGoal;
    if (g == null) return Center(child: Text(t('noMainGoal')));
    final stats = app.dayStats(g).reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: stats.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = stats[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(fmtDate(s.day)),
          subtitle: Text(
              '${t('target')}: ${num0(s.target.ceil())}   ${t('actual')}: ${num0(s.actual)}'),
          trailing: StatusChip(s.status),
        );
      },
    );
  }

  Widget _entries(BuildContext context) {
    final list = app.sortedTxns;
    if (list.isEmpty) return Center(child: Text(t('noEntries')));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final x = list[i];
        return Dismissible(
          key: ValueKey(x.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Theme.of(context).colorScheme.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) =>
              confirmDialog(context, t('deleteEntry'), okLabel: t('delete')),
          onDismissed: (_) => app.deleteTxn(x.id),
          child: TxnTile(x),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'days', label: Text(t('days'))),
                ButtonSegment(value: 'entries', label: Text(t('entries'))),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
        ),
        Expanded(child: _mode == 'days' ? _days(context) : _entries(context)),
      ],
    );
  }
}

// ======================= Insights =======================

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  Widget _bar(double v, double maxV, Color c) {
    final h = maxV <= 0 ? 2.0 : max(2.0, 110 * v / maxV);
    return Container(
      width: 10,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final days = List<DateTime>.generate(7, (i) => addDays(today, i - 6));
    final saved = days.map((d) => app.totalOn('saving', d)).toList();
    final spent = days.map((d) => app.totalOn('spending', d)).toList();
    var maxV = 0.0;
    for (final v in [...saved, ...spent]) {
      if (v > maxV) maxV = v;
    }
    final weekSaved = saved.fold<double>(0, (a, b) => a + b);
    final weekSpent = spent.fold<double>(0, (a, b) => a + b);

    final weekCats = app.spendingByCategory(days.first).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final monthCats = app
        .spendingByCategory(addDays(today, -29))
        .entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final monthMax = monthCats.isEmpty ? 0.0 : monthCats.first.value;
    final locs = app.savingsByLocation().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final locTotal = locs.fold<double>(0, (a, b) => a + b.value);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionCard(
          title: '${t('savedVsSpent')} · ${t('thisWeek')}',
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
                                const SizedBox(width: 3),
                                _bar(spent[i], maxV, cs.error),
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
              Wrap(spacing: 16, children: [
                _legend(cs.primary, t('legendSaved')),
                _legend(cs.error, t('legendSpent')),
              ]),
              const SizedBox(height: 8),
              statRow(t('legendSaved'), money(weekSaved),
                  color: cs.primary, bold: true),
              statRow(t('legendSpent'), money(weekSpent),
                  color: cs.error, bold: true),
            ],
          ),
        ),
        SectionCard(
          title: t('topSpending'),
          child: weekCats.isEmpty
              ? Text(t('nothingYet'))
              : Row(
                  children: [
                    Icon(Icons.trending_up, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(t('cat_${weekCats.first.key}'),
                            style: theme.textTheme.titleMedium)),
                    Text(money(weekCats.first.value),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
        SectionCard(
          title: t('spendingByCat'),
          child: monthCats.isEmpty
              ? Text(t('nothingYet'))
              : Column(
                  children: [
                    for (final e in monthCats)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(t('cat_${e.key}'))),
                              Text(money(e.value)),
                            ]),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: monthMax <= 0 ? 0.0 : e.value / monthMax,
                              minHeight: 6,
                              color: cs.error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
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
      ],
    );
  }
}

// ======================= Settings =======================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name =
      TextEditingController(text: app.userName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _addLocation() async {
    final v = await askText(context, t('addLocation'));
    if (v != null) app.addLocation(v);
  }

  Future<void> _copyBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: app.exportJson()));
    messenger.showSnackBar(SnackBar(content: Text(t('backupCopied'))));
  }

  Future<void> _restore() async {
    final messenger = ScaffoldMessenger.of(context);
    final v = await askText(context, t('pasteBackup'), maxLines: 6);
    if (v == null || v.trim().isEmpty) return;
    final ok = app.importJson(v);
    if (ok) _name.text = app.userName;
    messenger.showSnackBar(
        SnackBar(content: Text(ok ? t('restored') : t('restoreFailed'))));
  }

  Future<void> _reset() async {
    final ok =
        await confirmDialog(context, t('resetConfirm'), okLabel: t('delete'));
    if (!ok || !mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    app.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        Widget header(String s) => Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Text(s,
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
            );
        return Scaffold(
          appBar: AppBar(title: Text(t('settings'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                    labelText: t('yourName'),
                    border: const OutlineInputBorder()),
                onChanged: app.setName,
              ),
              header(t('language')),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'sw', label: Text('Kiswahili')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {app.lang},
                onSelectionChanged: (s) => app.setLang(s.first),
              ),
              header(t('locations')),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final l in app.locations)
                    InputChip(
                      label: Text(l),
                      onDeleted: app.locations.length > 1
                          ? () => app.removeLocation(l)
                          : null,
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(t('addLocation')),
                    onPressed: _addLocation,
                  ),
                ],
              ),
              header(t('backup')),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.copy_all_outlined),
                title: Text(t('copyBackup')),
                subtitle: Text(t('copyBackupSub')),
                onTap: _copyBackup,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore),
                title: Text(t('restore')),
                onTap: _restore,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_forever_outlined, color: cs.error),
                title: Text(t('resetAll'), style: TextStyle(color: cs.error)),
                onTap: _reset,
              ),
              header(t('about')),
              const Text('Akiba 1.0'),
            ],
          ),
        );
      },
    );
  }
}
