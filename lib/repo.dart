import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';
import 'models.dart';

/// অ্যাপের ডেটা লেয়ার। প্রতিটি পরিবর্তন লোকাল ডাটাবেসে লেখা হয়
/// (updated_at + dirty=1) এবং তারপর সিঙ্কের জন্য onChanged ডাকা হয়।
class Repo extends ChangeNotifier {
  Repo._();
  static final Repo i = Repo._();
  static const _uuid = Uuid();

  late SharedPreferences prefs;
  List<PartyView> parties = [];
  int pending = 0;
  VoidCallback? onChanged;

  String get shopName => prefs.getString('shop') ?? 'আমার দোকান';

  Future<void> setShopName(String v) async {
    await prefs.setString('shop', v.trim().isEmpty ? 'আমার দোকান' : v.trim());
    notifyListeners();
  }

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    await load();
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;

  PartyView? find(String id) {
    for (final v in parties) {
      if (v.party.id == id) return v;
    }
    return null;
  }

  Future<void> load() async {
    final db = await LocalDb.db;
    final rows = await db.rawQuery('''
      SELECT p.*, COALESCE(SUM(t.got - t.gave), 0) AS bal, MAX(t.created_at) AS last_txn
      FROM parties p
      LEFT JOIN txns t ON t.party_id = p.id AND t.deleted = 0
      WHERE p.deleted = 0
      GROUP BY p.id
    ''');
    parties = rows.map((r) {
      final party = Party.fromMap(r);
      final bal = (r['bal'] as num).toDouble();
      final last = (r['last_txn'] as int?) ?? party.createdAt;
      return PartyView(party, bal, last);
    }).toList();

    final a = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM parties WHERE dirty = 1')) ??
        0;
    final b = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM txns WHERE dirty = 1')) ??
        0;
    pending = a + b;
    notifyListeners();
  }

  Future<void> _changed() async {
    await load();
    onChanged?.call();
  }

  // ---------- পার্টি ----------

  Future<String> addParty(String type, String name, String phone) async {
    final db = await LocalDb.db;
    final id = _uuid.v4();
    final n = _now();
    await db.insert('parties', {
      'id': id,
      'type': type,
      'name': name.trim(),
      'phone': phone.trim(),
      'created_at': n,
      'updated_at': n,
      'deleted': 0,
      'dirty': 1,
    });
    await _changed();
    return id;
  }

  Future<void> updateParty(String id, {required String name, required String phone}) async {
    final db = await LocalDb.db;
    await db.update(
      'parties',
      {'name': name.trim(), 'phone': phone.trim(), 'updated_at': _now(), 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _changed();
  }

  Future<void> deleteParty(String id) async {
    final db = await LocalDb.db;
    final n = _now();
    await db.update(
      'txns',
      {'deleted': 1, 'updated_at': n, 'dirty': 1},
      where: 'party_id = ? AND deleted = 0',
      whereArgs: [id],
    );
    await db.update(
      'parties',
      {'deleted': 1, 'updated_at': n, 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _changed();
  }

  // ---------- লেনদেন ----------

  Future<List<Txn>> txnsFor(String partyId) async {
    final db = await LocalDb.db;
    final rows = await db.query(
      'txns',
      where: 'party_id = ? AND deleted = 0',
      whereArgs: [partyId],
      orderBy: 'date ASC, created_at ASC',
    );
    return rows.map(Txn.fromMap).toList();
  }

  Future<void> addTxn({
    required String partyId,
    required double gave,
    required double got,
    required String note,
    required int date,
  }) async {
    final db = await LocalDb.db;
    final n = _now();
    await db.insert('txns', {
      'id': _uuid.v4(),
      'party_id': partyId,
      'gave': gave,
      'got': got,
      'note': note,
      'date': date,
      'created_at': n,
      'updated_at': n,
      'deleted': 0,
      'dirty': 1,
    });
    await _changed();
  }

  Future<void> updateTxn(
    String id, {
    required double gave,
    required double got,
    required String note,
    required int date,
  }) async {
    final db = await LocalDb.db;
    await db.update(
      'txns',
      {'gave': gave, 'got': got, 'note': note, 'date': date, 'updated_at': _now(), 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _changed();
  }

  Future<void> deleteTxn(String id) async {
    final db = await LocalDb.db;
    await db.update(
      'txns',
      {'deleted': 1, 'updated_at': _now(), 'dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _changed();
  }
}
