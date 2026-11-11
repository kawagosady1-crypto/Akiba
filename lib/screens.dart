import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'i18n.dart';
import 'insights.dart';
import 'settings.dart';
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
  final _startCtl = TextEditingController();
  String _startLocation = app.locations.isNotEmpty ? app.locations.first : '';
  DateTime _deadline = addDays(dayOnly(DateTime.now()), 90);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _amount.dispose();
    _startCtl.dispose();
    super.dispose();
  }

  double get _amt => double.tryParse(_amount.text) ?? 0;
  double get _startAmt => double.tryParse(_startCtl.text) ?? 0;

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
    if (_startAmt >= _amt) {
      setState(() => _error = t('startTooBig'));
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
      startAmount: _startAmt,
      startLocation: _startLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final days = max(1, daysBetween(today, _deadline) + 1);
    final need = _amt - _startAmt;
    final preview = need > 0 ? need / days : 0.0;

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
            TextField(
              controller: _startCtl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: t('alreadySaved'),
                  helperText: t('alreadySavedHelp'),
                  border: const OutlineInputBorder()),
            ),
            if (_startAmt > 0) ...[
              const SizedBox(height: 12),
              Text(t('whereKept'), style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              chipWrap([
                for (final l in app.locations)
                  ChoiceChip(
                    label: Text(l),
                    selected: _startLocation == l,
                    onSelected: (_) => setState(() => _startLocation = l),
                  ),
              ]),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.event),
              label: Text(
                  '${t('deadline')}: ${fmtDate(_deadline)}  ($days ${t('days').toLowerCase()})'),
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
                      const SizedBox(height: 4),
                      Text(t('changeLater'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onPrimaryContainer)),
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
          const GoalsScreen(),
          const HistoryScreen(),
          const InsightsScreen(),
          const RewardsScreen(),
        ];
        final titles = [
          app.userName.isEmpty ? t('hello') : '${t('hello')}, ${app.userName}',
          t('goals'),
          t('history'),
          t('insights'),
          t('rewards'),
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
          body: KeyedSubtree(
            key: ValueKey('tab$_index${app.lang}'),
            child: pages[_index],
          ),
          floatingActionButton: app.activeGoals.isEmpty && _index == 0
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => showLogSheet(context),
                  icon: const Icon(Icons.add),
                  label: Text(t('log')),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
              NavigationDestination(
                  icon: const Icon(Icons.emoji_events_outlined),
                  selectedIcon: const Icon(Icons.emoji_events),
                  label: t('rewards')),
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

  String _hoursLeft(WithdrawRequest r) {
    final mins = r.readyAt.difference(DateTime.now()).inMinutes;
    final h = (mins / 60).floor();
    final m = mins % 60;
    return '${h}h ${m}m';
  }

  List<Widget> _requestCards(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final out = <Widget>[];
    for (final r in app.requests) {
      final ready = r.isReady;
      out.add(SectionCard(
        color: ready ? cs.secondaryContainer : null,
        title: t('withdrawRequest'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${money(r.amount)} · ${goalLabel(r.goalId)} · ${t('why_${r.reason}')}'),
            const SizedBox(height: 4),
            Text(ready
                ? t('requestReady')
                : tf('requestWait', {'a': _hoursLeft(r)})),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => app.cancelRequest(r),
                  child: Text(t('cancelRequest')),
                ),
                if (ready)
                  FilledButton(
                    onPressed: () => app.completeRequest(r),
                    child: Text(t('withdrawNow')),
                  ),
              ],
            ),
          ],
        ),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final g = app.mainGoal;
    final children = <Widget>[..._requestCards(context)];

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
      final saved = app.balance(g.id);
      final done = saved >= g.target;
      final stats = app.periodStats(g);
      final ts = stats.isNotEmpty ? stats.last : app.currentStat(g);
      final prev = stats.length >= 2 ? stats[stats.length - 2] : null;

      children.add(GoalCard(g, onTap: () => showGoalSheet(context, goal: g)));

      if (done) {
        children.add(SectionCard(
          color: cs.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.celebration, size: 40, color: cs.onPrimaryContainer),
              const SizedBox(height: 8),
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
        // Current period
        final met = ts.met;
        children.add(SectionCard(
          title: g.period == 'day'
              ? t('today')
              : '${periodName(g.period)} · ${shortDate(ts.start)} - ${shortDate(ts.end)}',
          color: met ? cs.primaryContainer : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statRow(
                  g.isFixed
                      ? '${targetLabel(g)} (${t('fixedTag')})'
                      : targetLabel(g),
                  moneyUp(ts.target),
                  bold: true),
              statRow(savedPeriodLabel(g), money(ts.actual)),
              const SizedBox(height: 8),
              progressBar(ts.target <= 0 ? 1.0 : ts.actual / ts.target),
              const SizedBox(height: 10),
              if (met)
                Text(
                  ts.extra > 0
                      ? '${t('targetMet')}  ${t('extraLabel')}: ${money(ts.extra)}'
                      : t('targetMet'),
                  style:
                      TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
                )
              else
                Text('${t('remainingPeriod')}: ${moneyUp(ts.shortfall)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ));

        // Time vs money
        final tf_ = app.timeFraction(g);
        final mf = app.moneyFraction(g);
        final ahead = mf >= tf_ - 0.02;
        children.add(SectionCard(
          title: t('pace'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                SizedBox(width: 110, child: Text(t('timeUsed'))),
                Expanded(child: progressBar(tf_, color: cs.outline)),
                const SizedBox(width: 8),
                SizedBox(
                    width: 40,
                    child: Text('${(tf_ * 100).round()}%',
                        textAlign: TextAlign.right)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                SizedBox(width: 110, child: Text(t('moneySaved'))),
                Expanded(child: progressBar(mf)),
                const SizedBox(width: 8),
                SizedBox(
                    width: 40,
                    child: Text('${(mf * 100).round()}%',
                        textAlign: TextAlign.right)),
              ]),
              const SizedBox(height: 10),
              Text(
                ahead ? t('paceAhead') : t('paceBehind'),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ahead ? Colors.green.shade700 : Colors.orange.shade800),
              ),
            ],
          ),
        ));

        // Shortfall recovery
        if (prev != null && !prev.met) {
          String msg;
          if (g.isFixed) {
            final f = app.finishAt(g, g.fixedAmount!);
            final params = {
              'a': moneyUp(prev.shortfall),
              'b': '${moneyUp(g.fixedAmount!)} ${perLabel(g)}',
              'c': f == null ? '-' : fmtDate(f),
            };
            msg = prev.actual <= 0
                ? tf('missedFixed', params)
                : tf('shortFixed', params);
          } else {
            msg = prev.actual <= 0
                ? tf('missedPrev', {'b': moneyUp(ts.target)})
                : tf('shortPrev', {
                    'a': moneyUp(prev.shortfall),
                    'b': moneyUp(ts.target)
                  });
          }
          children.add(SectionCard(
            color: cs.tertiaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg, style: TextStyle(color: cs.onTertiaryContainer)),
                if (!g.isFixed) ...[
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
              ],
            ),
          ));
        }

        // Streak + projection
        final streak = app.streak(g);
        final finish = app.projectedFinish(g);
        final onTrack = finish != null && !finish.isAfter(g.deadline);
        children.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            statRow(t('buffer'), money(app.bufferBalance)),
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

    // Loans to pay back
    final loans = app.activeLoans();
    if (loans.isNotEmpty) {
      children.add(SectionCard(
        title: t('loansTitle'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final l in loans) ...[
              Text(tf('loanLine', {
                'g': goalLabel(l.goalId),
                'a': money(app.outstanding(l)),
                'b': money(l.amount),
              })),
              const SizedBox(height: 6),
              progressBar(1 - app.outstanding(l) / l.amount),
              if (l.loanDays > 0) ...[
                const SizedBox(height: 4),
                Text(
                    tf('loanPlan', {
                      'a': moneyUp(l.amount / l.loanDays),
                      'd': fmtDate(addDays(l.date, l.loanDays)),
                    }),
                    style: theme.textTheme.bodySmall),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      showLogSheet(context, kind: 'saving', goalId: l.goalId),
                  child: Text(t('repayNow')),
                ),
              ),
            ],
          ],
        ),
      ));
    }

    // Spending limits close to or over
    final near = app.categoriesNearLimit();
    if (near.isNotEmpty) {
      children.add(SectionCard(
        title: t('limitsTitle'),
        color: cs.errorContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in near)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  tf('limitStatusNamed', {
                    'c': t('cat_$c'),
                    'a': money(app.monthSpent(c)),
                    'b': money(app.limits[c]!),
                  }),
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ),
          ],
        ),
      ));
    }

    // Today's money
    children.add(SectionCard(
      title: t('today'),
      child: Column(
        children: [
          statRow(t('savedToday'), money(app.totalOn('saving', today)),
              color: cs.primary, bold: true),
          statRow(t('spentToday'), money(app.totalOn('spending', today)),
              color: cs.error, bold: true),
          if (app.totalOn('income', today) > 0)
            statRow(t('incomeToday'), money(app.totalOn('income', today)),
                color: cs.tertiary, bold: true),
          if (app.totalOn('withdrawal', today) > 0)
            statRow(t('withdrawnToday'),
                money(app.totalOn('withdrawal', today)),
                color: Colors.orange.shade800, bold: true),
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
        if (app.bufferBalance > 0) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: t('buffer'),
            child: statRow(t('balance'), money(app.bufferBalance), bold: true),
          ),
        ],
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
                  '${money(app.balance(g.id))} ${t('of')} ${money(g.target)}'),
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
  String _mode = 'periods';
  String _filter = 'all';

  Widget _periods(BuildContext context) {
    final g = app.mainGoal;
    if (g == null) return Center(child: Text(t('noMainGoal')));
    final stats = app.periodStats(g).reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: stats.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = stats[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(periodTitle(s, g)),
          subtitle: Text(
              '${t('target')}: ${num0(s.target.ceil())}   ${t('actual')}: ${num0(s.actual)}'),
          trailing: StatusChip(s.status),
        );
      },
    );
  }

  Widget _entries(BuildContext context) {
    var list = app.sortedTxns;
    if (_filter != 'all') list = list.where((x) => x.kind == _filter).toList();
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final f in ['all', 'saving', 'spending', 'withdrawal', 'income'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t('filter_$f')),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(t('noEntries')))
              : ListView.builder(
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
                      confirmDismiss: (_) => confirmDialog(
                          context, t('deleteEntry'),
                          okLabel: t('delete')),
                      onDismissed: (_) => app.deleteTxn(x.id),
                      child: TxnTile(x),
                    );
                  },
                ),
        ),
      ],
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
                ButtonSegment(value: 'periods', label: Text(t('periodsTab'))),
                ButtonSegment(value: 'entries', label: Text(t('entries'))),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
        ),
        Expanded(
            child:
                _mode == 'periods' ? _periods(context) : _entries(context)),
      ],
    );
  }
}
