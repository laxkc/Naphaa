import 'package:sme_digital/core/storage/local_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _ffiInitialized = false;

Future<LocalDatabase> createTestDb(String name) async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _ffiInitialized = true;
  }
  final db = LocalDatabase(dbName: 'test_$name.db');
  await db.reset();
  await db.database;
  return db;
}
