import 'package:flutter/material.dart';

import 'contact_picker.dart';
import 'repo.dart';
import 'utils.dart';

/// নতুন কাস্টমার/সাপ্লায়ার যোগ। সফল হলে নতুন পার্টির id নিয়ে ফিরে যায়।
class PartyFormPage extends StatefulWidget {
  const PartyFormPage({super.key});

  @override
  State<PartyFormPage> createState() => _PartyFormPageState();
}

class _PartyFormPageState extends State<PartyFormPage> {
  String type = 'customer';
  final name = TextEditingController();
  final phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নতুন কাস্টমার/সাপ্লায়ার')),
      body: SafeArea(
        child: Padding(
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
            const Spacer(),
            BigButton(
              'নিশ্চিত',
              onTap: name.text.trim().isEmpty
                  ? null
                  : () async {
                      final id =
                          await Repo.i.addParty(type, name.text, phone.text);
                      if (context.mounted) Navigator.pop(context, id);
                    },
            ),
          ]),
        ),
      ),
    );
  }
}
