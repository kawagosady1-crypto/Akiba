import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'i18n.dart';
import 'state.dart';
import 'widgets.dart';

// ======================= Goal sheet =======================

Future<void> showGoalSheet(BuildContext context,
    {Goal? goal, String type = 'mini'}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: GoalSheet(goal: goal, type: type),
    ),
  );
}

class GoalSheet extends StatefulWidget {
  final Goal? goal;
  final String type;
  const GoalSheet({super.key, this.goal, required this.type});

  @override
  State<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<GoalSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late DateTime _deadline;
  late String _type;
  late String _extraDest;
  String? _error;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _name = TextEditingController(text: g?.name ?? '');
    _amount =
        TextEditingController(text: g == null ? '' : g.target.round().toString());
    _deadline = g?.deadline ?? addDays(dayOnly(DateTime.now()), 90);
    _type = g?.type ?? widget.type;
    _extraDest = g?.extraDest ?? 'goal';
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  double get _amt => double.tryParse(_amount.text) ?? 0;

  Future<void> _pickDeadline() async {
    final today = dayOnly(DateTime.now());
    final first = addDays(today, 1);
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(first) ? first : _deadline,
      firstDate: first,
      lastDate: addDays(today, 3650),
    );
    if (d != null) setState(() => _deadline = d);
  }

  void _save() {
    final today = dayOnly(DateTime.now());
    if (_name.text.trim().isEmpty) {
      setState(() => _error = t('required'));
      return;
    }
    if (_amt <= 0) {
      setState(() => _error = t('invalidAmount'));
      return;
    }
    if (!dayOnly(_deadline).isAfter(today)) {
      setState(() => _error = t('deadlinePast'));
      return;
    }
    final g = widget.goal;
    if (g == null) {
      app.addGoal(Goal(
        id: newId(),
        name: _name.text.trim(),
        type: _type,
        target: _amt,
        start: today,
        deadline: dayOnly(_deadline),
        extraDest: _extraDest,
      ));
    } else {
      g.name = _name.text.trim();
      g.target = _amt;
      g.deadline = dayOnly(_deadline);
      g.extraDest = _extraDest;
      app.updateGoal(g);
    }
    Navigator.pop(context);
  }

  Future<void> _archive() async {
    app.archiveGoal(widget.goal!);
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, t('deleteGoalConfirm'),
        okLabel: t('delete'));
    if (!ok || !mounted) return;
    app.deleteGoal(widget.goal!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final canChooseType = widget.goal == null && app.mainGoal == null;
    final saved = widget.goal == null ? 0.0 : app.savedFor(widget.goal!.id);
    final left = max(1, daysBetween(today, _deadline) + 1);
    final preview = _amt > saved ? (_amt - saved) / left : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.goal == null ? t('newGoal') : t('editGoal'),
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (canChooseType) ...[
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'main', label: Text(t('mainGoal'))),
                ButtonSegment(value: 'mini', label: Text(t('miniGoal'))),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _name,
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
                labelText: t('goalAmount'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDeadline,
            icon: const Icon(Icons.event),
            label: Text('${t('deadline')}: ${fmtDate(_deadline)}'),
          ),
          if (preview > 0) ...[
            const SizedBox(height: 12),
            Text('${t('dailyTargetPreview')}: ${moneyUp(preview)}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
          ],
          if (_type == 'main') ...[
            const SizedBox(height: 16),
            Text(t('extraGoesTo')),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'goal', label: Text(t('mainGoal'))),
                ButtonSegment(value: 'buffer', label: Text(t('buffer'))),
              ],
              selected: {_extraDest},
              onSelectionChanged: (s) => setState(() => _extraDest = s.first),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: Text(t('save'))),
          if (widget.goal != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _archive, child: Text(t('archive'))),
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: Text(t('deleteGoal')),
            ),
          ],
        ],
      ),
    );
  }
}

// ======================= Log sheet =======================

Future<void> showLogSheet(BuildContext context, {String kind = 'saving'}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: LogSheet(kind: kind),
    ),
  );
}

class LogSheet extends StatefulWidget {
  final String kind;
  const LogSheet({super.key, required this.kind});

  @override
  State<LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<LogSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _kind;
  late String _goalId;
  late String _location;
  String _category = 'food';
  String _paidFrom = '';
  late DateTime _date;
  String? _error;

  static const List<int> _quick = [500, 1000, 2000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _kind = widget.kind;
    final goals = app.activeGoals;
    _goalId = goals.isNotEmpty ? goals.first.id : bufferId;
    _location = app.locations.isNotEmpty ? app.locations.first : '';
    _date = dayOnly(DateTime.now());
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dayOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: addDays(today, -7),
      lastDate: today,
    );
    if (d != null) setState(() => _date = dayOnly(d));
  }

  void _save() {
    final amt = double.tryParse(_amount.text) ?? 0;
    if (amt <= 0) {
      setState(() => _error = t('invalidAmount'));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    String msg;
    if (_kind == 'saving') {
      app.addSaving(
        amount: amt,
        goalId: _goalId,
        location: _location,
        date: _date,
        note: _note.text.trim(),
      );
      msg = tf('savedMsg', {'a': money(amt)});
      final g = app.goalById(_goalId);
      if (g != null && g.type == 'main' && sameDay(_date, DateTime.now())) {
        final extra = app.todayStat(g).extra;
        if (extra > 0) {
          msg = tf('savedExtraMsg', {'a': money(amt), 'b': money(extra)});
        }
      }
    } else {
      app.addSpending(
        amount: amt,
        category: _category,
        location: _paidFrom,
        date: _date,
        note: _note.text.trim(),
      );
      msg = tf('spentMsg', {'a': money(amt)});
    }
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dayOnly(DateTime.now());
    final yesterday = addDays(today, -1);
    final isOther = !sameDay(_date, today) && !sameDay(_date, yesterday);
    final goals = app.activeGoals;

    Widget label(String s) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(s, style: theme.textTheme.labelLarge),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                  value: 'saving',
                  icon: const Icon(Icons.savings_outlined),
                  label: Text(t('saving'))),
              ButtonSegment(
                  value: 'spending',
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(t('spending'))),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
                labelText: t('amount'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final q in _quick)
                ActionChip(
                  label: Text(num0(q)),
                  onPressed: () => setState(() => _amount.text = q.toString()),
                ),
            ],
          ),
          if (_kind == 'saving') ...[
            label(t('goal')),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final g in goals)
                  ChoiceChip(
                    label: Text(g.name),
                    selected: _goalId == g.id,
                    onSelected: (_) => setState(() => _goalId = g.id),
                  ),
                ChoiceChip(
                  label: Text(t('buffer')),
                  selected: _goalId == bufferId,
                  onSelected: (_) => setState(() => _goalId = bufferId),
                ),
              ],
            ),
            label(t('location')),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final l in app.locations)
                  ChoiceChip(
                    label: Text(l),
                    selected: _location == l,
                    onSelected: (_) => setState(() => _location = l),
                  ),
              ],
            ),
          ] else ...[
            label(t('category')),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    label: Text(t('cat_$c')),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            label(t('paidFrom')),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final l in app.locations)
                  ChoiceChip(
                    label: Text(l),
                    selected: _paidFrom == l,
                    onSelected: (sel) =>
                        setState(() => _paidFrom = sel ? l : ''),
                  ),
              ],
            ),
          ],
          label(t('date')),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: Text(t('today')),
                selected: sameDay(_date, today),
                onSelected: (_) => setState(() => _date = today),
              ),
              ChoiceChip(
                label: Text(t('yesterday')),
                selected: sameDay(_date, yesterday),
                onSelected: (_) => setState(() => _date = yesterday),
              ),
              ChoiceChip(
                label: Text(isOther ? fmtDate(_date) : t('otherDay')),
                selected: isOther,
                onSelected: (_) => _pickDate(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: InputDecoration(
                labelText: t('note'), border: const OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(t('save')),
          ),
        ],
      ),
    );
  }
}
