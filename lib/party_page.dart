import 'package:flutter/material.dart';

import 'models.dart';
import 'repo.dart';
import 'report_page.dart';
import 'utils.dart';

/// লেনদেন এন্ট্রির স্ক্রিন: দিলাম / পেলাম-কেনা, বিবরণ, তারিখ।
class PartyPage extends StatefulWidget {
  final String partyId;
  const PartyPage({super.key, required this.partyId});

  @override
  State<PartyPage> createState() => _PartyPageState();
}

class _PartyPageState extends State<PartyPage> {
  final gave = TextEditingController();
  final got = TextEditingController();
  final note = TextEditingController();
  DateTime date = DateTime.now();
  bool saving = false;

  bool get valid => parseAmount(gave.text) > 0 || parseAmount(got.text) > 0;

  @override
  void initState() {
    super.initState();
    gave.addListener(() => setState(() {}));
    got.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    gave.dispose();
    got.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => date = d);
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final when = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
    await Repo.i.addTxn(
      partyId: widget.partyId,
      gave: parseAmount(gave.text),
      got: parseAmount(got.text),
      note: note.text.trim(),
      date: when.millisecondsSinceEpoch,
    );
    gave.clear();
    got.clear();
    note.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    setState(() {
      date = DateTime.now();
      saving = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('লেনদেন সংরক্ষিত হয়েছে'),
      duration: Duration(seconds: 2),
    ));
    // ১ সেকেন্ড বার্তা দেখিয়ে নিজে থেকে ড্যাশবোর্ডে ফিরে যায়
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _editParty(Party p) async {
    final n = TextEditingController(text: p.name);
    final ph = TextEditingController(text: p.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('তথ্য পরিবর্তন'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: 'নাম')),
          TextField(
              controller: ph,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'মোবাইল নম্বর')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    if (ok == true && n.text.trim().isNotEmpty) {
      await Repo.i.updateParty(p.id, name: n.text, phone: ph.text);
    }
  }

  Future<void> _deleteParty(Party p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${p.name} মুছবেন?'),
        content: const Text('এর সব লেনদেনও মুছে যাবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('মুছুন', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok == true) {
      await Repo.i.deleteParty(p.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _amountField(TextEditingController c, String hint) => Expanded(
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('৳', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Repo.i,
      builder: (context, _) {
        final v = Repo.i.find(widget.partyId);
        if (v == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final bal = v.balance;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(children: [
              PartyAvatar(v.party.name, size: 40),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(v.party.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            actions: [
              PopupMenuButton<String>(
                onSelected: (s) =>
                    s == 'edit' ? _editParty(v.party) : _deleteParty(v.party),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('তথ্য পরিবর্তন')),
                  PopupMenuItem(value: 'delete', child: Text('মুছে ফেলুন')),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(children: [
                  Expanded(
                    child: bal == 0
                        ? const Text('হিসাব শূন্য', style: TextStyle(fontSize: 18))
                        : Text.rich(TextSpan(children: [
                            TextSpan(
                                text: '${balanceWord(bal)} ',
                                style: const TextStyle(fontSize: 18)),
                            TextSpan(
                                text: '৳ ${money(bal)}',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: balanceColor(bal))),
                          ])),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.description_outlined, size: 20),
                    label: const Text('রিপোর্ট'),
                    backgroundColor: const Color(0xFFF2F4F9),
                    shape: const StadiumBorder(),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ReportPage(partyId: widget.partyId))),
                  ),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Row(children: [
                    _amountField(gave, 'দিলাম'),
                    const SizedBox(width: 12),
                    _amountField(got, 'পেলাম/কেনা'),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: note,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.edit_note, size: 30),
                      hintText: 'বিবরণ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(Icons.calendar_month_outlined, size: 20),
                      label: Text(dateShort(date)),
                      backgroundColor: const Color(0xFFF2F4F9),
                      shape: const StadiumBorder(),
                      onPressed: _pickDate,
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: BigButton('নিশ্চিত', onTap: valid && !saving ? _save : null),
              ),
            ]),
          ),
        );
      },
    );
  }
}
