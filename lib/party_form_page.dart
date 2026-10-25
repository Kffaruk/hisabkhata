import 'package:flutter/material.dart';

import 'contact_picker.dart';
import 'repo.dart';
import 'utils.dart';

/// নতুন কাস্টমার/সাপ্লায়ার যোগ।
/// - নাম না থাকলে (শুধু নম্বর দিলেও) "পূর্বের বাকি" ঘর আসে না এবং নিশ্চিত হয় না।
/// - নাম থাকলে (ফোনবুক থেকে নিলে বা হাতে লিখলে) "পূর্বের বাকি (জের)" ঘর আসে।
///   নম্বর না দিলেও নিশ্চিত করা যায়।
/// - কাস্টমারের জের = পাবো, সাপ্লায়ারের জের = দেবো।
class PartyFormPage extends StatefulWidget {
  const PartyFormPage({super.key});

  @override
  State<PartyFormPage> createState() => _PartyFormPageState();
}

class _PartyFormPageState extends State<PartyFormPage> {
  String type = 'customer';
  final name = TextEditingController();
  final phone = TextEditingController();
  final opening = TextEditingController();
  DateTime date = DateTime.now();
  bool saving = false;

  bool get hasName => name.text.trim().isNotEmpty;
  bool get receivable => type == 'customer';

  @override
  void initState() {
    super.initState();
    name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    opening.dispose();
    super.dispose();
  }

  Widget _typeBox(String value, String label) {
    final sel = type == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? kRed : Colors.black12, width: sel ? 1.6 : 1),
          ),
          child: Row(children: [
            Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                color: sel ? kRed : Colors.black54),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 17, color: sel ? kRed : Colors.black87)),
          ]),
        ),
      ),
    );
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
    if (!hasName || saving) return;
    setState(() => saving = true);
    final id = await Repo.i.addParty(type, name.text, phone.text);
    final amount = parseAmount(opening.text);
    if (amount > 0) {
      final now = DateTime.now();
      final when = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
      await Repo.i.addTxn(
        partyId: id,
        gave: receivable ? amount : 0,
        got: receivable ? 0 : amount,
        note: 'পূর্বের বাকি (জের)',
        date: when.millisecondsSinceEpoch,
      );
    }
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নতুন কাস্টমার/সাপ্লায়ার')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              _typeBox('customer', 'কাস্টমার'),
              const SizedBox(width: 12),
              _typeBox('supplier', 'সাপ্লায়ার'),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kGrey,
                  foregroundColor: Colors.black87,
                  shape: const StadiumBorder(),
                ),
                onPressed: () async {
                  final c = await pickContact(context);
                  if (c != null) {
                    name.text = c.name;
                    phone.text = c.phone;
                  }
                },
                icon: const Icon(Icons.contact_phone_outlined),
                label: const Text('ফোনবুক থেকে যোগ করি', style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                labelText: 'নাম',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
                labelText: 'মোবাইল নম্বর',
                border: OutlineInputBorder(),
              ),
            ),
            // নাম থাকলে তবেই "পূর্বের বাকি" ও তারিখ দেখায়
            if (hasName) ...[
              const SizedBox(height: 20),
              TextField(
                controller: opening,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('৳', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  labelText: 'পূর্বের বাকি (জের)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
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
            ],
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: BigButton('নিশ্চিত', onTap: hasName && !saving ? _save : null),
        ),
      ),
    );
  }
}
