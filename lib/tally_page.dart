import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';
import 'models.dart';
import 'party_form_page.dart';
import 'party_page.dart';
import 'repo.dart';
import 'sync.dart';
import 'utils.dart';

class TallyPage extends StatefulWidget {
  const TallyPage({super.key});

  @override
  State<TallyPage> createState() => _TallyPageState();
}

class _TallyPageState extends State<TallyPage> {
  String q = '';
  bool fCustomer = false;
  bool fSupplier = false;
  int amountSort = 0; // ১ = কম→বেশি, ২ = বেশি→কম
  int dateSort = 0; // ১ = নতুন→পুরাতন, ২ = পুরাতন→নতুন

  List<PartyView> _visible(List<PartyView> all) {
    final l = all.where((v) {
      if (fCustomer != fSupplier) {
        if (fCustomer && v.party.isSupplier) return false;
        if (fSupplier && !v.party.isSupplier) return false;
      }
      if (q.isNotEmpty) {
        final s = q.toLowerCase();
        return v.party.name.toLowerCase().contains(s) || v.party.phone.contains(s);
      }
      return true;
    }).toList();
    if (amountSort != 0) {
      l.sort((a, b) => amountSort == 1
          ? a.balance.abs().compareTo(b.balance.abs())
          : b.balance.abs().compareTo(a.balance.abs()));
    } else {
      l.sort((a, b) => dateSort == 2
          ? a.lastActivity.compareTo(b.lastActivity)
          : b.lastActivity.compareTo(a.lastActivity));
    }
    return l;
  }

  Future<void> _openFilter() async {
    var c = fCustomer, s = fSupplier, a = amountSort, d = dateSort;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        Widget check(String label, bool val, ValueChanged<bool> on) => InkWell(
              onTap: () => setS(() => on(!val)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: kGrey, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600))),
                  Icon(val ? Icons.check_box : Icons.check_box_outline_blank,
                      color: val ? kRed : Colors.grey),
                ]),
              ),
            );
        Widget radio(String label, bool sel, VoidCallback on) => Expanded(
              child: InkWell(
                onTap: () => setS(on),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  decoration: BoxDecoration(
                      color: kGrey, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: sel ? kRed : Colors.grey, size: 22),
                    const SizedBox(width: 6),
                    Flexible(child: Text(label, style: const TextStyle(fontSize: 14))),
                  ]),
                ),
              ),
            );
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  const Expanded(
                      child: Text('ফিল্টার',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 8),
                check('কাস্টমার', c, (v) => c = v),
                check('সাপ্লায়ার', s, (v) => s = v),
                const Divider(height: 28),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('দেবো/পাবোর পরিমাণ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                const SizedBox(height: 10),
                Row(children: [
                  radio('কম → বেশি', a == 1, () {
                    a = 1;
                    d = 0;
                  }),
                  radio('বেশি → কম', a == 2, () {
                    a = 2;
                    d = 0;
                  }),
                ]),
                const Divider(height: 28),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('সর্বশেষ লেনদেন',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                const SizedBox(height: 10),
                Row(children: [
                  radio('নতুন → পুরাতন', d == 1, () {
                    d = 1;
                    a = 0;
                  }),
                  radio('পুরাতন → নতুন', d == 2, () {
                    d = 2;
                    a = 0;
                  }),
                ]),
                const SizedBox(height: 20),
                BigButton('নিশ্চিত', onTap: () => Navigator.pop(ctx, true)),
              ]),
            ),
          ),
        );
      }),
    );
    if (ok == true) {
      setState(() {
        fCustomer = c;
        fSupplier = s;
        amountSort = a;
        dateSort = d;
      });
    }
  }

  Future<void> _copyAll(List<PartyView> all) async {
    final b = StringBuffer()..writeln(Repo.i.shopName)..writeln('------------------------');
    for (final v in all) {
      final w = v.balance == 0 ? '০.০০' : '${balanceWord(v.balance)} ${money(v.balance)}';
      b.writeln('${v.party.name} (${v.party.typeLabel}): $w');
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('সব হিসাব কপি হয়েছে')));
  }

  Widget _syncButton() {
    final sync = SyncService.i;
    IconData icon;
    String label;
    if (!cloudConfigured || !sync.signedIn) {
      icon = Icons.cloud_off_outlined;
      label = 'অফলাইন';
    } else if (sync.syncing) {
      icon = Icons.sync;
      label = 'সিঙ্ক…';
    } else if (Repo.i.pending > 0) {
      icon = Icons.cloud_upload_outlined;
      label = '${bn(Repo.i.pending.toString())} বাকি';
    } else {
      icon = Icons.cloud_done_outlined;
      label = 'ব্যাকআপ ✓';
    }
    return InkWell(
      onTap: () {
        if (cloudConfigured && sync.signedIn) {
          sync.schedule(immediate: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('মেনু থেকে ক্লাউড ব্যাকআপ চালু করুন')));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Repo.i, SyncService.i]),
      builder: (context, _) {
        final all = Repo.i.parties;
        final list = _visible(all);
        var toGet = 0.0, toGive = 0.0;
        var cust = 0, sup = 0;
        for (final v in all) {
          if (v.balance < 0) toGet += -v.balance;
          if (v.balance > 0) toGive += v.balance;
          v.party.isSupplier ? sup++ : cust++;
        }
        return Scaffold(
          backgroundColor: kRed,
          floatingActionButton: FloatingActionButton(
            backgroundColor: kRed,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: () async {
              final id = await Navigator.push<String>(context,
                  MaterialPageRoute(builder: (_) => const PartyFormPage()));
              if (id != null && context.mounted) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PartyPage(partyId: id)));
              }
            },
            child: const Icon(Icons.person_add_alt_1),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(children: [
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: kPink, borderRadius: BorderRadius.circular(24)),
                      child: Text(Repo.i.shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _syncButton(),
                ]),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(children: [
                        Expanded(
                            child: Column(children: [
                          Text(money(toGet).replaceAll('.০০', ''),
                              style: const TextStyle(
                                  color: kDebit,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          const Text('মোট পাবো'),
                        ])),
                        Container(width: 1, height: 44, color: Colors.black12),
                        Expanded(
                            child: Column(children: [
                          Text(money(toGive).replaceAll('.০০', ''),
                              style: const TextStyle(
                                  color: Color(0xFF1B7A4A),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          const Text('মোট দেবো'),
                        ])),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => q = v),
                            decoration: InputDecoration(
                              hintText: 'খোঁজ',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: kGrey,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _roundBtn(Icons.tune, _openFilter),
                        const SizedBox(width: 8),
                        _roundBtn(Icons.download, () => _copyAll(all)),
                      ]),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                            'কাস্টমার ${bn('$cust')} / সাপ্লায়ার ${bn('$sup')}',
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'কোনো কাস্টমার/সাপ্লায়ার নেই।\nনিচের লাল বাটনে চেপে যোগ করুন।',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 90),
                              itemCount: list.length,
                              itemBuilder: (_, i) => _row(list[i]),
                            ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(color: kGrey, shape: BoxShape.circle),
          child: Icon(icon),
        ),
      );

  Widget _row(PartyView v) {
    final bal = v.balance;
    final sub = v.party.isSupplier
        ? 'সাপ্লায়ার | ${ago(v.lastActivity)}'
        : ago(v.lastActivity);
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PartyPage(partyId: v.party.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          PartyAvatar(v.party.name, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.party.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
              Text(sub, style: const TextStyle(color: Colors.black54)),
            ]),
          ),
          Text(money(bal),
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: balanceColor(bal))),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }
}
