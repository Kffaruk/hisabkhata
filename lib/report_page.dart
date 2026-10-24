import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'repo.dart';
import 'utils.dart';

/// লেনদেনের খতিয়ান (দিলাম / পেলাম কলাম)। কোনো লেনদেনে ট্যাপ করলে এডিট/ডিলিট।
class ReportPage extends StatefulWidget {
  final String partyId;
  const ReportPage({super.key, required this.partyId});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<Txn> txns = [];
  bool showHint = true;

  @override
  void initState() {
    super.initState();
    Repo.i.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    Repo.i.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final l = await Repo.i.txnsFor(widget.partyId);
    if (mounted) setState(() => txns = l);
  }

  Future<void> _copy(PartyView v) async {
    await Clipboard.setData(
        ClipboardData(text: statementText(v, txns, Repo.i.shopName)));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('হিসাবের বিবরণ কপি হয়েছে')));
  }

  @override
  Widget build(BuildContext context) {
    final v = Repo.i.find(widget.partyId);
    if (v == null) return const Scaffold(body: SizedBox());
    final bal = v.balance;

    // পুরোনো থেকে নতুন ধরে চলতি ব্যালেন্স হিসাব, দেখানো হয় নতুন আগে।
    final rows = <MapEntry<Txn, double>>[];
    var run = 0.0;
    var sumGave = 0.0, sumGot = 0.0;
    for (final t in txns) {
      run += t.got - t.gave;
      sumGave += t.gave;
      sumGot += t.got;
      rows.add(MapEntry(t, run));
    }
    final shown = rows.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          PartyAvatar(v.party.name, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.party.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                bal == 0 ? 'হিসাব শূন্য' : '${balanceWord(bal)} ${money(bal)}',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: balanceColor(bal)),
              ),
            ]),
          ),
        ]),
        actions: [
          TextButton.icon(
            onPressed: () => _copy(v),
            icon: const Icon(Icons.download, color: Colors.black54),
            label: const Text('কপি', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
      body: Column(children: [
        if (showHint)
          Container(
            color: const Color(0xFFE6F0FA),
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Color(0xFF1976D2)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('লেনদেন রেকর্ড এডিট/ডিলিট করতে লেনদেনের উপর ট্যাপ করুন।')),
              IconButton(
                  onPressed: () => setState(() => showHint = false),
                  icon: const Icon(Icons.cancel, color: Colors.black54)),
            ]),
          ),
        Container(
          color: const Color(0xFFF2F2F2),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: const Row(children: [
            Expanded(
                flex: 5,
                child: Text('লেনদেনের বিবরণ',
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
            Expanded(
                flex: 3,
                child: Center(
                    child: Text('দিলাম',
                        style: TextStyle(
                            color: Colors.black54, fontWeight: FontWeight.w600)))),
            Expanded(
                flex: 3,
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('পেলাম',
                        style: TextStyle(
                            color: Colors.black54, fontWeight: FontWeight.w600)))),
          ]),
        ),
        const Divider(height: 1, thickness: 2),
        Expanded(
          child: shown.isEmpty
              ? const Center(
                  child: Text('এখনো কোনো লেনদেন নেই', style: TextStyle(color: Colors.black54)))
              : ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1.5),
                  itemBuilder: (_, i) => _row(shown[i].key, shown[i].value),
                ),
        ),
        const Divider(height: 1, thickness: 2),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(children: [
            const Expanded(flex: 5, child: Text('মোট', style: TextStyle(fontSize: 17))),
            Expanded(
                flex: 3,
                child: Center(
                    child: Text(money(sumGave),
                        style: const TextStyle(
                            color: kDebit, fontWeight: FontWeight.bold, fontSize: 16)))),
            Expanded(
                flex: 3,
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(money(sumGot),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
          ]),
        ),
      ]),
    );
  }

  Widget _row(Txn t, double running) {
    final d = t.dateTime;
    return InkWell(
      onTap: () => editTxnDialog(context, t),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dateLong(d),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(timeLabel(d), style: const TextStyle(color: Colors.black54)),
                if (t.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(t.note, style: const TextStyle(color: Colors.black45)),
                  ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    running == 0
                        ? 'হিসাব শূন্য'
                        : '${balanceWord(running)} ${money(running)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFFDEEEE),
              alignment: Alignment.center,
              child: t.gave > 0
                  ? Text(money(t.gave),
                      style: const TextStyle(
                          color: kDebit, fontSize: 16, fontWeight: FontWeight.w500))
                  : null,
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 12),
              child: t.got > 0
                  ? Text(money(t.got),
                      style: const TextStyle(
                          color: kGreen, fontSize: 16, fontWeight: FontWeight.w500))
                  : null,
            ),
          ),
        ]),
      ),
    );
  }
}

/// লেনদেন এডিট বা মুছে ফেলার ডায়ালগ।
Future<void> editTxnDialog(BuildContext context, Txn t) async {
  String show(double v) => v == 0 ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
  final gave = TextEditingController(text: show(t.gave));
  final got = TextEditingController(text: show(t.got));
  final note = TextEditingController(text: t.note);
  var date = t.dateTime;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      return AlertDialog(
        title: const Text('লেনদেন এডিট'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: gave,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'দিলাম', prefixText: '৳ '),
            ),
            TextField(
              controller: got,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'পেলাম/কেনা', prefixText: '৳ '),
            ),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'বিবরণ')),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.calendar_month_outlined, size: 20),
                label: Text(dateLong(date)),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) {
                    setS(() => date = DateTime(
                        d.year, d.month, d.day, date.hour, date.minute, date.second));
                  }
                },
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: ctx,
                builder: (c2) => AlertDialog(
                  title: const Text('এই লেনদেন মুছবেন?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c2, false), child: const Text('না')),
                    TextButton(
                        onPressed: () => Navigator.pop(c2, true),
                        child: const Text('মুছুন', style: TextStyle(color: kRed))),
                  ],
                ),
              );
              if (ok == true) {
                await Repo.i.deleteTxn(t.id);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('মুছুন', style: TextStyle(color: kRed)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          TextButton(
            onPressed: () async {
              final g = parseAmount(gave.text), r = parseAmount(got.text);
              if (g <= 0 && r <= 0) return;
              await Repo.i.updateTxn(t.id,
                  gave: g,
                  got: r,
                  note: note.text.trim(),
                  date: date.millisecondsSinceEpoch);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      );
    }),
  );
}
