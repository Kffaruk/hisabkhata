import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'db.dart';
import 'repo.dart';

/// অফলাইন-ফার্স্ট সিঙ্ক।
///  1. PULL: ক্লাউডে যা নতুন/বদলেছে তা আনা। দুই জায়গায় একই রো বদলালে updated_at
///     যেটা নতুন সেটাই জেতে।
///  2. PUSH: ফোনে dirty=1 রো গুলো ক্লাউডে আপলোড। সফল হলে dirty=0।
/// ইন্টারনেট না থাকলে কিছুই হারায় না, dirty চিহ্ন থেকে যায় এবং নেট এলে অটো সিঙ্ক হয়।
class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService i = SyncService._();

  bool _ready = false;
  bool syncing = false;
  bool _again = false;
  String status = '';
  DateTime? lastSync;
  Timer? _timer;

  bool get ready => _ready;
  User? get _user => _ready ? Supabase.instance.client.auth.currentUser : null;
  bool get signedIn => _user != null;
  String get email => _user?.email ?? '';

  Future<void> init() async {
    if (!cloudConfigured) return;
    try {
      await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
      _ready = true;
      Connectivity().onConnectivityChanged.listen((results) {
        if (!results.contains(ConnectivityResult.none)) schedule();
      });
      notifyListeners();
      schedule();
    } catch (e) {
      status = 'ক্লাউড চালু করা যায়নি';
      notifyListeners();
    }
  }

  void schedule({bool immediate = false}) {
    if (!_ready || !signedIn) return;
    _timer?.cancel();
    _timer = Timer(Duration(seconds: immediate ? 0 : 2), sync);
  }

  Future<String?> authenticate(String email, String password, {required bool signUp}) async {
    if (!_ready) return 'ক্লাউড সেটিং করা নেই (lib/config.dart দেখুন)';
    try {
      final c = Supabase.instance.client;
      if (signUp) {
        final r = await c.auth.signUp(email: email, password: password);
        if (r.session == null) {
          return 'ইমেইল যাচাই চালু আছে। Supabase-এ "Confirm email" বন্ধ করে আবার চেষ্টা করুন।';
        }
      } else {
        await c.auth.signInWithPassword(email: email, password: password);
      }
      notifyListeners();
      schedule(immediate: true);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'ইন্টারনেট সংযোগ দেখুন';
    }
  }

  Future<void> signOut() async {
    if (!_ready) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    status = '';
    notifyListeners();
  }

  Future<void> sync() async {
    if (!_ready) return;
    final user = _user;
    if (user == null) return;
    if (syncing) {
      _again = true;
      return;
    }
    syncing = true;
    status = 'সিঙ্ক হচ্ছে…';
    notifyListeners();
    try {
      final c = Supabase.instance.client;
      await _pullTable(c, user.id, 'parties');
      await _pullTable(c, user.id, 'txns');
      await _push(c, user.id, 'parties');
      await _push(c, user.id, 'txns');
      lastSync = DateTime.now();
      status = 'সিঙ্ক সম্পন্ন';
    } catch (e) {
      status = 'সিঙ্ক হয়নি (ইন্টারনেট বা সেটিং দেখুন)';
      if (kDebugMode) debugPrint('sync error: $e');
    } finally {
      syncing = false;
      await Repo.i.load();
      notifyListeners();
      if (_again) {
        _again = false;
        schedule();
      }
    }
  }

  // ---------- PULL ----------

  Future<void> _pullTable(SupabaseClient c, String uid, String table) async {
    final prefs = Repo.i.prefs;
    final key = 'cursor_${uid}_$table';
    final since = prefs.getInt(key) ?? 0;
    // কয়েক সেকেন্ড পিছিয়ে শুরু করি, যাতে একই মিলিসেকেন্ডের রো মিস না হয়।
    final start = since > 10000 ? since - 10000 : 0;
    final db = await LocalDb.db;

    var offset = 0;
    var maxTs = since;
    const page = 500;
    while (true) {
      final rows = await c
          .from(table)
          .select()
          .eq('user_id', uid)
          .gte('server_ts', start)
          .order('server_ts', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + page - 1);

      await db.transaction((txn) async {
        for (final r in rows) {
          final remoteUpdated = (r['updated_at'] as num).toInt();
          final local = await txn.query(
            table,
            columns: ['updated_at'],
            where: 'id = ?',
            whereArgs: [r['id']],
          );
          if (local.isNotEmpty && (local.first['updated_at'] as int) >= remoteUpdated) {
            continue; // ফোনের কপি নতুন বা সমান, রেখে দিই
          }
          await txn.insert(
            table,
            _toLocal(table, r),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      for (final r in rows) {
        final ts = (r['server_ts'] as num).toInt();
        if (ts > maxTs) maxTs = ts;
      }
      if (rows.length < page) break;
      offset += page;
    }
    await prefs.setInt(key, maxTs);
  }

  Map<String, Object?> _toLocal(String table, Map<String, dynamic> r) {
    if (table == 'parties') {
      return {
        'id': r['id'],
        'type': r['type'],
        'name': r['name'],
        'phone': r['phone'] ?? '',
        'created_at': (r['created_at'] as num).toInt(),
        'updated_at': (r['updated_at'] as num).toInt(),
        'deleted': r['deleted'] == true ? 1 : 0,
        'dirty': 0,
      };
    }
    return {
      'id': r['id'],
      'party_id': r['party_id'],
      'gave': (r['gave'] as num).toDouble(),
      'got': (r['got'] as num).toDouble(),
      'note': r['note'] ?? '',
      'date': (r['date'] as num).toInt(),
      'created_at': (r['created_at'] as num).toInt(),
      'updated_at': (r['updated_at'] as num).toInt(),
      'deleted': r['deleted'] == true ? 1 : 0,
      'dirty': 0,
    };
  }

  // ---------- PUSH ----------

  Future<void> _push(SupabaseClient c, String uid, String table) async {
    final db = await LocalDb.db;
    while (true) {
      final rows = await db.query(table, where: 'dirty = 1', limit: 200);
      if (rows.isEmpty) break;
      final payload = rows.map((r) => _toRemote(table, r, uid)).toList();
      await c.from(table).upsert(payload, onConflict: 'id');
      // আপলোডের সময় যে রো আবার বদলেছে (updated_at আলাদা) সেটা dirty থেকে যাবে।
      final batch = db.batch();
      for (final r in rows) {
        batch.update(
          table,
          {'dirty': 0},
          where: 'id = ? AND updated_at = ?',
          whereArgs: [r['id'], r['updated_at']],
        );
      }
      await batch.commit(noResult: true);
    }
  }

  Map<String, dynamic> _toRemote(String table, Map<String, Object?> r, String uid) {
    if (table == 'parties') {
      return {
        'id': r['id'],
        'user_id': uid,
        'type': r['type'],
        'name': r['name'],
        'phone': r['phone'],
        'created_at': r['created_at'],
        'updated_at': r['updated_at'],
        'deleted': r['deleted'] == 1,
      };
    }
    return {
      'id': r['id'],
      'user_id': uid,
      'party_id': r['party_id'],
      'gave': r['gave'],
      'got': r['got'],
      'note': r['note'],
      'date': r['date'],
      'created_at': r['created_at'],
      'updated_at': r['updated_at'],
      'deleted': r['deleted'] == 1,
    };
  }
}
