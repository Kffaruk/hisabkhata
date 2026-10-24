import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'utils.dart';

class PickedContact {
  final String name;
  final String phone;
  const PickedContact(this.name, this.phone);
}

String _normalize(String raw) {
  var p = raw.replaceAll(RegExp(r'[\s\-()]'), '');
  if (p.startsWith('+880')) {
    p = '0${p.substring(4)}';
  } else if (p.startsWith('880') && p.length == 13) {
    p = '0${p.substring(3)}';
  }
  return p;
}

/// ফোনবুক খুলে একটা কন্টাক্ট বেছে নেওয়ার ডায়ালগ। প্রতিটি নম্বর আলাদা সারিতে দেখায়।
Future<PickedContact?> pickContact(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  bool granted;
  try {
    granted = await FlutterContacts.requestPermission(readonly: true);
  } catch (_) {
    granted = false;
  }
  if (!granted) {
    messenger.showSnackBar(const SnackBar(
        content: Text('ফোনবুক দেখার অনুমতি দেওয়া হয়নি। ফোনের Settings থেকে অনুমতি দিন।')));
    return null;
  }

  List<Contact> contacts;
  try {
    contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: false);
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('ফোনবুক পড়া যায়নি')));
    return null;
  }

  final entries = <PickedContact>[];
  for (final c in contacts) {
    for (final ph in c.phones) {
      final n = _normalize(ph.number);
      if (n.isEmpty) continue;
      entries.add(PickedContact(c.displayName.trim().isEmpty ? n : c.displayName.trim(), n));
    }
  }
  entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  if (!context.mounted) return null;
  return showDialog<PickedContact>(
    context: context,
    builder: (_) => _ContactDialog(entries),
  );
}

class _ContactDialog extends StatefulWidget {
  final List<PickedContact> all;
  const _ContactDialog(this.all);

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final s = q.toLowerCase();
    final list = q.isEmpty
        ? widget.all
        : widget.all
            .where((e) => e.name.toLowerCase().contains(s) || e.phone.contains(s))
            .toList();
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => q = v),
              decoration: InputDecoration(
                hintText: 'খোঁজ',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: kGrey,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('কোনো কন্টাক্ট পাওয়া যায়নি'))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 80, endIndent: 16),
                    itemBuilder: (_, i) {
                      final e = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFFF8A2B),
                          child: Text(
                            e.name.characters.take(2).toString().toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(e.phone),
                        onTap: () => Navigator.pop(context, e),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
