import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n.dart';

/// The single app state, used by every screen.
final AppState app = AppState();

const String bufferId = 'buffer';
const List<String> categories = [
  'food',
  'transport',
  'airtime',
  'bills',
  'family',
  'other'
];
const List<String> defaultLocations = [
  'M-Pesa',
  'Mixx by Yas',
  'Airtel Money',
  'Bank',
  'Cash'
];

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;
String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
bool sameDay(DateTime a, DateTime b) => daysBetween(a, b) == 0;

final Random _rnd = Random();
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${_rnd.nextInt(99999)}';

class Goal {
  final String id;
  String name;
  String type; // 'main' or 'mini'
  double target;
  DateTime start;
  DateTime deadline;
  String extraDest; // 'goal' or 'buffer'
  bool archived;

  Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    required this.start,
    required this.deadline,
    this.extraDest = 'goal',
    this.archived = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'target': target,
        'start': start.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'extraDest': extraDest,
        'archived': archived,
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        target: (j['target'] as num).toDouble(),
        start: DateTime.parse(j['start'] as String),
        deadline: DateTime.parse(j['deadline'] as String),
        extraDest: (j['extraDest'] as String?) ?? 'goal',
        archived: (j['archived'] as bool?) ?? false,
      );
}

class Txn {
  final String id;
  String kind; // 'saving' or 'spending'
  double amount;
  String goalId; // for savings; '' for spending
  String category; // for spending
  String location;
  String source; // 'manual' now; 'sms', 'mpesa', 'bank' later
  String externalRef;
  DateTime date;
  String note;

  Txn({
    required this.id,
    required this.kind,
    required this.amount,
    this.goalId = '',
    this.category = '',
    this.location = '',
    this.source = 'manual',
    this.externalRef = '',
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'amount': amount,
        'goalId': goalId,
        'category': category,
        'location': location,
        'source': source,
        'externalRef': externalRef,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as String,
        kind: j['kind'] as String,
        amount: (j['amount'] as num).toDouble(),
        goalId: (j['goalId'] as String?) ?? '',
        category: (j['category'] as String?) ?? '',
        location: (j['location'] as String?) ?? '',
        source: (j['source'] as String?) ?? 'manual',
        externalRef: (j['externalRef'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
        note: (j['note'] as String?) ?? '',
      );
}

enum DayStatus { above, on, short, missed, pending, done }

class DayStat {
  final DateTime day;
  final double target;
  final double actual;
  DayStat(this.day, this.target, this.actual);

  bool get met => actual >= target - 0.5;
  double get extra => max(0.0, actual - target);
  double get shortfall => max(0.0, target - actual);

  DayStatus get status {
    if (target <= 0.5) return actual > 0 ? DayStatus.above : DayStatus.done;
    if (met) return actual > target + 0.5 ? DayStatus.above : DayStatus.on;
    if (sameDay(day, DateTime.now())) return DayStatus.pending;
    return actual <= 0 ? DayStatus.missed : DayStatus.short;
  }
}

class AppState extends ChangeNotifier {
  static const String _key = 'akiba_data_v1';
  SharedPreferences? _prefs;

  String lang = 'sw';
  String userName = '';
  bool onboarded = false;
  List<Goal> goals = [];
  List<Txn> txns = [];
  List<String> locations = List<String>.from(defaultLocations);

  // ---------- persistence ----------
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    currentLang = lang;
  }

  Map<String, dynamic> _toJson() => {
        'version': 1,
        'lang': lang,
        'userName': userName,
        'onboarded': onboarded,
        'locations': locations,
        'goals': goals.map((g) => g.toJson()).toList(),
        'txns': txns.map((x) => x.toJson()).toList(),
      };

  void _fromJson(Map<String, dynamic> j) {
    final g = (j['goals'] as List)
        .map((e) => Goal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final x = (j['txns'] as List)
        .map((e) => Txn.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    goals = g;
    txns = x;
    lang = (j['lang'] as String?) ?? 'sw';
    userName = (j['userName'] as String?) ?? '';
    onboarded = (j['onboarded'] as bool?) ?? true;
    final locs = j['locations'];
    locations = locs is List && locs.isNotEmpty
        ? locs.map((e) => e.toString()).toList()
        : List<String>.from(defaultLocations);
  }

  void _changed() {
    notifyListeners();
    _prefs?.setString(_key, jsonEncode(_toJson()));
  }

  String exportJson() => jsonEncode(_toJson());

  bool importJson(String raw) {
    try {
      final j = jsonDecode(raw.trim()) as Map<String, dynamic>;
      _fromJson(j);
      currentLang = lang;
      _changed();
      return true;
    } catch (_) {
      return false;
    }
  }

  void resetAll() {
    goals = [];
    txns = [];
    userName = '';
    onboarded = false;
    locations = List<String>.from(defaultLocations);
    _changed();
  }

  // ---------- settings ----------
  void setLang(String l) {
    lang = l;
    currentLang = l;
    _changed();
  }

  void setName(String n) {
    userName = n.trim();
    _changed();
  }

  void addLocation(String l) {
    final v = l.trim();
    if (v.isEmpty || locations.contains(v)) return;
    locations.add(v);
    _changed();
  }

  void removeLocation(String l) {
    if (locations.length <= 1) return;
    locations.remove(l);
    _changed();
  }

  void completeOnboarding(String name, Goal g) {
    userName = name.trim();
    goals.add(g);
    onboarded = true;
    _changed();
  }

  // ---------- goals ----------
  Goal? get mainGoal {
    for (final g in goals) {
      if (g.type == 'main' && !g.archived) return g;
    }
    return null;
  }

  List<Goal> get miniGoals =>
      goals.where((g) => g.type == 'mini' && !g.archived).toList();

  List<Goal> get activeGoals {
    final m = mainGoal;
    return [if (m != null) m, ...miniGoals];
  }

  List<Goal> get finishedGoals => goals.where((g) => g.archived).toList();

  Goal? goalById(String id) {
    for (final g in goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  void addGoal(Goal g) {
    goals.add(g);
    _changed();
  }

  void updateGoal(Goal g) => _changed();

  void archiveGoal(Goal g) {
    g.archived = true;
    _changed();
  }

  void deleteGoal(Goal g) {
    goals.removeWhere((x) => x.id == g.id);
    txns.removeWhere((x) => x.goalId == g.id);
    _changed();
  }

  // ---------- transactions ----------
  void addSaving({
    required double amount,
    required String goalId,
    required String location,
    required DateTime date,
    String note = '',
  }) {
    final day = dayOnly(date);
    final g = goalById(goalId);
    if (g != null && g.type == 'main' && g.extraDest == 'buffer') {
      // Only the part up to today's target goes to the goal; the rest is extra.
      final target = targetFor(g, day).ceilToDouble();
      final already = savedOn(g.id, day);
      final goalPart = min(amount, max(0.0, target - already));
      final extraPart = amount - goalPart;
      if (goalPart > 0) {
        txns.add(Txn(
            id: newId(),
            kind: 'saving',
            amount: goalPart,
            goalId: g.id,
            location: location,
            date: day,
            note: note));
      }
      if (extraPart > 0) {
        txns.add(Txn(
            id: newId(),
            kind: 'saving',
            amount: extraPart,
            goalId: bufferId,
            location: location,
            date: day,
            note: note));
      }
    } else {
      txns.add(Txn(
          id: newId(),
          kind: 'saving',
          amount: amount,
          goalId: goalId,
          location: location,
          date: day,
          note: note));
    }
    _changed();
  }

  void addSpending({
    required double amount,
    required String category,
    String location = '',
    required DateTime date,
    String note = '',
  }) {
    txns.add(Txn(
        id: newId(),
        kind: 'spending',
        amount: amount,
        category: category,
        location: location,
        date: dayOnly(date),
        note: note));
    _changed();
  }

  void deleteTxn(String id) {
    txns.removeWhere((x) => x.id == id);
    _changed();
  }

  List<Txn> get sortedTxns {
    final list = List<Txn>.from(txns);
    list.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return list;
  }

  // ---------- calculations ----------
  double savedFor(String goalId, {DateTime? before}) {
    var sum = 0.0;
    for (final x in txns) {
      if (x.kind != 'saving' || x.goalId != goalId) continue;
      if (before != null && !x.date.isBefore(dayOnly(before))) continue;
      sum += x.amount;
    }
    return sum;
  }

  double savedOn(String goalId, DateTime day) {
    var sum = 0.0;
    for (final x in txns) {
      if (x.kind == 'saving' && x.goalId == goalId && sameDay(x.date, day)) {
        sum += x.amount;
      }
    }
    return sum;
  }

  double totalOn(String kind, DateTime day) {
    var sum = 0.0;
    for (final x in txns) {
      if (x.kind == kind && sameDay(x.date, day)) sum += x.amount;
    }
    return sum;
  }

  double totalSince(String kind, DateTime from) {
    var sum = 0.0;
    for (final x in txns) {
      if (x.kind == kind && !x.date.isBefore(dayOnly(from))) sum += x.amount;
    }
    return sum;
  }

  double get bufferTotal => savedFor(bufferId);

  /// Daily target = (goal - saved before that day) / days remaining.
  double targetFor(Goal g, DateTime day) {
    final remaining = g.target - savedFor(g.id, before: day);
    if (remaining <= 0) return 0;
    final left = max(1, daysBetween(day, g.deadline) + 1);
    return remaining / left;
  }

  /// One entry per day from the goal's start until today.
  List<DayStat> dayStats(Goal g) {
    final today = dayOnly(DateTime.now());
    final startDay = dayOnly(g.start);
    final goalByDay = <String, double>{};
    final bufByDay = <String, double>{};
    var before = 0.0;
    for (final x in txns) {
      if (x.kind != 'saving') continue;
      if (x.goalId == g.id) {
        if (x.date.isBefore(startDay)) {
          before += x.amount;
        } else {
          goalByDay.update(dayKey(x.date), (v) => v + x.amount,
              ifAbsent: () => x.amount);
        }
      } else if (x.goalId == bufferId && g.type == 'main') {
        bufByDay.update(dayKey(x.date), (v) => v + x.amount,
            ifAbsent: () => x.amount);
      }
    }
    final out = <DayStat>[];
    var day = startDay;
    var guard = 0;
    while (!day.isAfter(today) && guard < 4000) {
      guard++;
      final remaining = g.target - before;
      final left = max(1, daysBetween(day, g.deadline) + 1);
      final target = remaining <= 0 ? 0.0 : remaining / left;
      final ag = goalByDay[dayKey(day)] ?? 0.0;
      final ab = bufByDay[dayKey(day)] ?? 0.0;
      out.add(DayStat(day, target, ag + ab));
      before += ag;
      day = addDays(day, 1);
    }
    return out;
  }

  DayStat todayStat(Goal g) {
    final s = dayStats(g);
    if (s.isNotEmpty) return s.last;
    final today = dayOnly(DateTime.now());
    return DayStat(today, targetFor(g, today), 0);
  }

  double totalExtra(Goal g) {
    var sum = 0.0;
    for (final s in dayStats(g)) {
      sum += s.extra;
    }
    return sum;
  }

  int streak(Goal g) {
    final s = dayStats(g);
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      final d = s[i];
      if (i == s.length - 1 && !d.met) continue; // today not finished yet
      if (d.met) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Finish date at the average pace of the last 14 days.
  DateTime? projectedFinish(Goal g) {
    final remaining = g.target - savedFor(g.id);
    if (remaining <= 0) return null;
    final s = dayStats(g);
    if (s.isEmpty) return null;
    final window = s.length > 14 ? s.sublist(s.length - 14) : s;
    final from = window.first.day;
    var sum = 0.0;
    for (final x in txns) {
      if (x.kind == 'saving' && x.goalId == g.id && !x.date.isBefore(from)) {
        sum += x.amount;
      }
    }
    final avg = sum / window.length;
    if (avg <= 0) return null;
    return addDays(dayOnly(DateTime.now()), (remaining / avg).ceil());
  }

  Map<String, double> spendingByCategory(DateTime from) {
    final m = <String, double>{};
    for (final x in txns) {
      if (x.kind == 'spending' && !x.date.isBefore(dayOnly(from))) {
        m.update(x.category, (v) => v + x.amount, ifAbsent: () => x.amount);
      }
    }
    return m;
  }

  Map<String, double> savingsByLocation() {
    final m = <String, double>{};
    for (final x in txns) {
      if (x.kind == 'saving') {
        final k = x.location.isEmpty ? '-' : x.location;
        m.update(k, (v) => v + x.amount, ifAbsent: () => x.amount);
      }
    }
    return m;
  }
}
