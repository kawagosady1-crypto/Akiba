import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'i18n.dart';
import 'services.dart';
import 'state.dart';
import 'widgets.dart';

/// True while the PIN screen should cover the app.
final ValueNotifier<bool> appLocked = ValueNotifier<bool>(false);

Future<String?> askPin(BuildContext context, String title) {
  final ctl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctl,
        autofocus: true,
        obscureText: true,
        maxLength: 6,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
            border: const OutlineInputBorder(), helperText: t('pinHelp')),
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

// ======================= Lock screen =======================

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (app.useBiometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _bio() async {
    final ok = await Bio.authenticate();
    if (ok) appLocked.value = false;
  }

  void _check(String v) {
    if (v.length < 4) return;
    if (app.checkPin(v)) {
      appLocked.value = false;
    } else if (v.length >= 6) {
      setState(() => _error = t('wrongPin'));
      _pin.clear();
    }
  }

  void _submit() {
    if (app.checkPin(_pin.text)) {
      appLocked.value = false;
    } else {
      setState(() => _error = t('wrongPin'));
      _pin.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: cs.primary),
                const SizedBox(height: 16),
                Text('Akiba',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(t('enterPin')),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _pin,
                    autofocus: !app.useBiometric,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(letterSpacing: 12),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _check,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), counterText: ''),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: cs.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: _submit, child: Text(t('unlock'))),
                if (app.useBiometric) ...[
                  const SizedBox(height: 16),
                  IconButton.filledTonal(
                    iconSize: 36,
                    onPressed: _bio,
                    icon: const Icon(Icons.fingerprint),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
  late final TextEditingController _fixed = TextEditingController(
      text: app.mainGoal?.isFixed == true
          ? app.mainGoal!.fixedAmount!.round().toString()
          : '');
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    Bio.available().then((v) {
      if (mounted) setState(() => _bioAvailable = v);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _fixed.dispose();
    super.dispose();
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  // ---------- target ----------
  void _setMode(Goal g, String mode) {
    if (mode == 'auto') {
      app.setTargetMode(g, clearFixed: true);
      return;
    }
    var v = double.tryParse(_fixed.text) ?? 0;
    if (v <= 0) {
      v = app.autoTargetNow(g).ceilToDouble();
      if (v <= 0) v = 1000;
      _fixed.text = v.round().toString();
    }
    app.setTargetMode(g, fixedAmount: v);
  }

  Widget _targetSection(BuildContext context) {
    final theme = Theme.of(context);
    final g = app.mainGoal;
    if (g == null) return Text(t('noMainGoal'));
    final fixed = g.isFixed;
    final children = <Widget>[
      Text(t('targetPeriod'), style: theme.textTheme.bodySmall),
      const SizedBox(height: 6),
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          for (final p in periodTypes)
            ButtonSegment(value: p, label: Text(periodName(p))),
        ],
        selected: {g.period},
        onSelectionChanged: (s) => app.setTargetMode(g, period: s.first),
      ),
      const SizedBox(height: 12),
      Text(t('targetAmountMode'), style: theme.textTheme.bodySmall),
      const SizedBox(height: 6),
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'auto', label: Text(t('auto'))),
          ButtonSegment(value: 'fixed', label: Text(t('fixed'))),
        ],
        selected: {fixed ? 'fixed' : 'auto'},
        onSelectionChanged: (s) => _setMode(g, s.first),
      ),
      const SizedBox(height: 12),
    ];
    if (!fixed) {
      children.add(Text(
          tf('autoExplain', {
            'a': '${moneyUp(app.autoTargetNow(g))} ${perLabel(g)}',
          }),
          style: theme.textTheme.bodySmall));
    } else {
      final f = app.finishAt(g, g.fixedAmount!);
      final isLate = f != null && f.isAfter(g.deadline);
      final finishText = f == null
          ? ''
          : tf('fixedFinish', {
              'a': '${moneyUp(g.fixedAmount!)} ${perLabel(g)}',
              'b': fmtDate(f),
            });
      final verdict = isLate
          ? tf('fixedLate', {'c': fmtDate(g.deadline)})
          : t('fixedEarly');
      children.addAll([
        TextField(
          controller: _fixed,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
              labelText: '${t('fixedAmount')} (${perLabel(g)})',
              border: const OutlineInputBorder()),
          onChanged: (v) {
            final n = double.tryParse(v) ?? 0;
            if (n > 0) app.setTargetMode(g, fixedAmount: n);
          },
        ),
        const SizedBox(height: 8),
        if (f != null)
          Text(
            '$finishText $verdict',
            style: TextStyle(
                color: isLate ? theme.colorScheme.error : Colors.green.shade700),
          ),
      ]);
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  // ---------- reminder ----------
  Future<void> _toggleReminder(bool on) async {
    if (!on) {
      await Reminders.cancel();
      app.setReminder(false, app.reminderHour, app.reminderMinute);
      return;
    }
    await Reminders.requestPermission();
    final ok = await Reminders.schedule(app.reminderHour, app.reminderMinute);
    app.setReminder(ok, app.reminderHour, app.reminderMinute);
    if (!ok && mounted) _snack(t('reminderFailed'));
  }

  Future<void> _pickReminderTime() async {
    final tm = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: app.reminderHour, minute: app.reminderMinute),
    );
    if (tm == null) return;
    app.setReminder(app.reminderOn, tm.hour, tm.minute);
    if (app.reminderOn) await Reminders.schedule(tm.hour, tm.minute);
  }

  // ---------- security ----------
  Future<void> _togglePin(bool on) async {
    if (!on) {
      app.setPin(null);
      return;
    }
    final a = await askPin(context, t('newPin'));
    if (a == null || a.length < 4) {
      if (a != null && mounted) _snack(t('pinTooShort'));
      return;
    }
    if (!mounted) return;
    final b = await askPin(context, t('repeatPin'));
    if (b != a) {
      if (mounted) _snack(t('pinMismatch'));
      return;
    }
    app.setPin(a);
    if (mounted) _snack(t('pinSet'));
  }

  Future<void> _toggleBio(bool on) async {
    if (on) {
      final ok = await Bio.authenticate();
      if (!ok) return;
    }
    app.setBiometric(on);
  }

  // ---------- data ----------
  Future<void> _addLocation() async {
    final v = await askText(context, t('addLocation'));
    if (v != null) app.addLocation(v);
  }

  Future<void> _copyBackup() async {
    await Clipboard.setData(ClipboardData(text: app.exportJson()));
    if (mounted) _snack(t('backupCopied'));
  }

  Future<void> _restore() async {
    final v = await askText(context, t('pasteBackup'), maxLines: 6);
    if (v == null || v.trim().isEmpty) return;
    final ok = app.importJson(v);
    if (ok) _name.text = app.userName;
    if (mounted) _snack(ok ? t('restored') : t('restoreFailed'));
  }

  Future<void> _reset() async {
    final ok =
        await confirmDialog(context, t('resetConfirm'), okLabel: t('delete'));
    if (!ok || !mounted) return;
    await Reminders.cancel();
    if (!mounted) return;
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
        final time = TimeOfDay(
                hour: app.reminderHour, minute: app.reminderMinute)
            .format(context);
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
                onSelectionChanged: (s) {
                  app.setLang(s.first);
                  if (app.reminderOn) {
                    Reminders.schedule(app.reminderHour, app.reminderMinute);
                  }
                },
              ),
              header(t('savingTarget')),
              _targetSection(context),
              header(t('reminder')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: app.reminderOn,
                onChanged: _toggleReminder,
                title: Text(t('dailyReminder')),
                subtitle: Text(t('reminderHelp')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: app.reminderOn,
                leading: const Icon(Icons.schedule),
                title: Text(t('reminderTime')),
                trailing: Text(time),
                onTap: app.reminderOn ? _pickReminderTime : null,
              ),
              header(t('security')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: app.hasPin,
                onChanged: _togglePin,
                title: Text(t('pinLock')),
                subtitle: Text(t('pinLockHelp')),
              ),
              if (app.hasPin && _bioAvailable)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: app.useBiometric,
                  onChanged: _toggleBio,
                  title: Text(t('fingerprint')),
                ),
              header(t('saveFirst')),
              Text(t('saveFirstHelp'), style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              chipWrap([
                for (final p in [0, 5, 10, 15, 20, 30])
                  ChoiceChip(
                    label: Text(p == 0 ? t('off') : '$p%'),
                    selected: app.saveFirstPercent == p,
                    onSelected: (_) => app.setSaveFirst(p),
                  ),
              ]),
              header(t('locations')),
              chipWrap([
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
              ]),
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
              const Text('Akiba 2.0'),
            ],
          ),
        );
      },
    );
  }
}
