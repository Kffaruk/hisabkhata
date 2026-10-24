import 'package:flutter/material.dart';

import 'models.dart';

const kRed = Color(0xFFB91414);
const kPink = Color(0xFFFCE4E4);
const kGreen = Color(0xFF43A855);
const kDebit = Color(0xFFB5202F);
const kGrey = Color(0xFFF2F2F2);

const _bnDigits = '০১২৩৪৫৬৭৮৯';

String bn(String s) =>
    s.replaceAllMapped(RegExp(r'\d'), (m) => _bnDigits[int.parse(m[0]!)]);

String _group(String intPart) {
  final b = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) b.write(',');
    b.write(intPart[i]);
  }
  return b.toString();
}

/// ১০,১৯০.০০
String money(double v) {
  final parts = v.abs().toStringAsFixed(2).split('.');
  return bn('${_group(parts[0])}.${parts[1]}');
}

/// বাংলা সংখ্যাকে ইংরেজি সংখ্যায় বদলায় (খোঁজার সময় কাজে লাগে)।
String toAscii(String s) {
  var t = s;
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(_bnDigits[i], '$i');
  }
  return t;
}

/// কীবোর্ডের ইংরেজি বা বাংলা দুই ধরনের সংখ্যাই পড়ে।
double parseAmount(String s) {
  var t = s.trim().replaceAll(',', '');
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(_bnDigits[i], '$i');
  }
  return double.tryParse(t) ?? 0;
}

const _months = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];

String dateShort(DateTime d) => bn('${d.day} ${_months[d.month - 1]}');
String dateLong(DateTime d) => bn('${d.day} ${_months[d.month - 1]}, ${d.year}');

String timeLabel(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '${bn('$h:$m')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String ago(int ms) {
  final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (diff.inMinutes < 1) return 'এইমাত্র';
  if (diff.inMinutes < 60) return '${bn(diff.inMinutes.toString())} মিনিট';
  if (diff.inHours < 24) return '${bn(diff.inHours.toString())} ঘণ্টা';
  return '${bn(diff.inDays.toString())} দিন';
}

/// balance > 0 → দেবো (সবুজ), balance < 0 → পাবো (লাল)
String balanceWord(double b) => b > 0 ? 'দেবো' : (b < 0 ? 'পাবো' : '');
Color balanceColor(double b) => b > 0 ? kGreen : (b < 0 ? kDebit : Colors.black87);

String statementText(PartyView v, List<Txn> txns, String shop) {
  final b = StringBuffer()
    ..writeln(shop)
    ..writeln('${v.party.typeLabel}: ${v.party.name}'
        '${v.party.phone.isEmpty ? '' : ' (${bn(v.party.phone)})'}')
    ..writeln('------------------------');
  var run = 0.0;
  for (final t in txns) {
    run += t.got - t.gave;
    final what = t.gave > 0
        ? 'দিলাম ${money(t.gave)}'
        : 'পেলাম ${money(t.got)}';
    b.writeln('${dateLong(t.dateTime)} ${timeLabel(t.dateTime)}');
    b.writeln('  $what${t.note.isEmpty ? '' : ' | ${t.note}'}');
    b.writeln('  ${run == 0 ? 'হিসাব শূন্য' : '${balanceWord(run)} ${money(run)}'}');
  }
  b.writeln('------------------------');
  final bal = v.balance;
  b.writeln(bal == 0 ? 'মোট হিসাব শূন্য' : 'মোট ${balanceWord(bal)} ${money(bal)}');
  return b.toString();
}

class PartyAvatar extends StatelessWidget {
  final String name;
  final double size;
  const PartyAvatar(this.name, {super.key, this.size = 44});

  static const _colors = [
    Color(0xFFD5F6D5),
    Color(0xFFFFF4C9),
    Color(0xFFE4ECFB),
    Color(0xFFF9D6D6),
    Color(0xFFFFE0B8),
  ];

  @override
  Widget build(BuildContext context) {
    var sum = 0;
    for (final c in name.codeUnits) {
      sum += c;
    }
    final text = name.trim().isEmpty
        ? '?'
        : name.trim().characters.take(2).toString().toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _colors[sum % _colors.length],
      child: Text(text,
          style: TextStyle(color: Colors.black87, fontSize: size * 0.34)),
    );
  }
}

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const BigButton(this.label, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: kRed,
          disabledBackgroundColor: const Color(0xFFF5DCDC),
          disabledForegroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
