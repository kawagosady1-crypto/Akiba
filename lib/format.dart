import 'i18n.dart';

String num0(num v) {
  final n = v.round();
  final neg = n < 0;
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return neg ? '-$b' : b.toString();
}

String money(num v) => 'TZS ${num0(v)}';

/// Targets are rounded up to the next whole shilling.
String moneyUp(num v) => money(v.ceil());

String fmtDate(DateTime d) => '${d.day} ${monthShort(d.month)} ${d.year}';

String shortDate(DateTime d) => '${d.day} ${monthShort(d.month)}';
