import 'package:flutter/material.dart';

import 'config.dart';
import 'repo.dart';
import 'sync.dart';
import 'utils.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _auth(bool signUp) async {
    if (email.text.trim().isEmpty || pass.text.length < 6) {
      _toast('ইমেইল দিন এবং পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের দিন');
      return;
    }
    setState(() => busy = true);
    final err = await SyncService.i
        .authenticate(email.text.trim(), pass.text, signUp: signUp);
    if (!mounted) return;
    setState(() => busy = false);
    if (err != null) {
      _toast(err);
    } else {
      pass.clear();
      _toast('লগইন সফল, ব্যাকআপ শুরু হচ্ছে');
    }
  }

  Future<void> _editShop() async {
    final c = TextEditingController(text: Repo.i.shopName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('দোকানের নাম'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    if (ok == true) await Repo.i.setShopName(c.text);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([Repo.i, SyncService.i]),
        builder: (context, _) {
          final sync = SyncService.i;
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('মেনু', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: kGrey,
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('দোকানের নাম'),
                subtitle: Text(Repo.i.shopName),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _editShop,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: kGrey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.cloud_outlined),
                    SizedBox(width: 10),
                    Text('ক্লাউড ব্যাকআপ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    'ফোনে অপেক্ষমান এন্ট্রি: ${bn(Repo.i.pending.toString())} টি',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  if (!cloudConfigured)
                    const Text(
                      'ক্লাউড সেটআপ করা নেই। এখন সব ডেটা শুধু এই ফোনে জমা হচ্ছে (অফলাইন)। '
                      'ক্লাউড চালু করতে README-র ধাপগুলো অনুসরণ করুন।',
                    )
                  else if (!sync.signedIn) ...[
                    const Text('লগইন করলে অনলাইন থাকলেই ডেটা অটো ব্যাকআপ হবে, '
                        'অফলাইনে করা এন্ট্রিও নেট এলে নিজে থেকে চলে যাবে।'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'ইমেইল', border: OutlineInputBorder(), filled: true,
                          fillColor: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pass,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'পাসওয়ার্ড', border: OutlineInputBorder(), filled: true,
                          fillColor: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: kRed),
                              onPressed: busy ? null : () => _auth(false),
                              child: const Text('লগইন'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: OutlinedButton(
                              onPressed: busy ? null : () => _auth(true),
                              child: const Text('নতুন একাউন্ট'))),
                    ]),
                  ] else ...[
                    Text(sync.email, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(sync.status.isEmpty ? '—' : sync.status),
                    if (sync.lastSync != null)
                      Text(
                        'শেষ সিঙ্ক: ${timeLabel(sync.lastSync!)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: kRed),
                              onPressed:
                                  sync.syncing ? null : () => sync.schedule(immediate: true),
                              icon: const Icon(Icons.sync),
                              label: const Text('এখনই সিঙ্ক'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => sync.signOut(),
                              child: const Text('লগআউট'))),
                    ]),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              elevation: 0,
              color: kGrey,
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('হিসাব খাতা'),
                subtitle: Text('সংস্করণ ১.০.০ · অফলাইনে চলে, অনলাইনে ব্যাকআপ হয়'),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
