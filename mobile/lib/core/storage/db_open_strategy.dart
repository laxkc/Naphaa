import 'package:sqflite/sqflite.dart';

typedef DbOnCreate = Future<void> Function(Database db, int version);
typedef DbOnUpgrade =
    Future<void> Function(Database db, int oldVersion, int newVersion);

abstract class DatabaseOpenStrategy {
  Future<Database> open({
    required String path,
    required int version,
    required DbOnCreate onCreate,
    required DbOnUpgrade onUpgrade,
  });
}

class SqfliteDatabaseOpenStrategy implements DatabaseOpenStrategy {
  const SqfliteDatabaseOpenStrategy();

  @override
  Future<Database> open({
    required String path,
    required int version,
    required DbOnCreate onCreate,
    required DbOnUpgrade onUpgrade,
  }) {
    return openDatabase(
      path,
      version: version,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }
}

