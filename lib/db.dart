import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// ফোনের লোকাল SQLite ডাটাবেস। সব এন্ট্রি আগে এখানে জমা হয় (অফলাইনেও কাজ করে)।
/// dirty = 1 মানে এই রো এখনো ক্লাউডে ব্যাকআপ হয়নি।
/// deleted = 1 মানে মুছে ফেলা (soft delete), যাতে মোছার খবরও সিঙ্ক হয়।
class LocalDb {
  static Database? _db;

  static Future<Database> get db async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'hisab_khata.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE parties(
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '',
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            dirty INTEGER NOT NULL DEFAULT 1
          )''');
        await d.execute('''
          CREATE TABLE txns(
            id TEXT PRIMARY KEY,
            party_id TEXT NOT NULL,
            gave REAL NOT NULL DEFAULT 0,
            got REAL NOT NULL DEFAULT 0,
            note TEXT NOT NULL DEFAULT '',
            date INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            dirty INTEGER NOT NULL DEFAULT 1
          )''');
        await d.execute('CREATE INDEX idx_txns_party ON txns(party_id)');
      },
    );
  }
}
