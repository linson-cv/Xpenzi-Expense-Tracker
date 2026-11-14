// native.dart
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'dart:io';

Future<FinanceDatabase> constructDb(String dbName,
    {Uint8List? initialDataWeb}) async {
  // the LazyDatabase util lets us find the right location for the file async.
  final db = LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '$dbName.sqlite'));
    void setupDb(dynamic database) {
      try {
        database.execute('PRAGMA journal_mode = WAL;');
        database.execute('PRAGMA busy_timeout = 5000;');
        database.execute('PRAGMA synchronous = NORMAL;');
      } catch (e) {
        print("Error setting PRAGMA for SQLite: $e");
      }
    }

    QueryExecutor foregroundExecutor = NativeDatabase(file, setup: setupDb);
    QueryExecutor backgroundExecutor = NativeDatabase.createInBackground(file, setup: setupDb);
    return MultiExecutor(read: foregroundExecutor, write: backgroundExecutor);
  });
  return FinanceDatabase(db);
}

Future<DBFileInfo> getCurrentDBFileInfo() async {
  Uint8List dbFileBytes;
  late Stream<List<int>> mediaStream;

  try {
    await database.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
  } catch (e) {
    print("Error checkpointing WAL before export: $e");
  }

  final dbFolder = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));
  //print("FILE SIZE:" + (dbFile.lengthSync() / 1e+6).toString());
  dbFileBytes = await dbFile.readAsBytes();
  mediaStream = Stream.value(List<int>.from(dbFileBytes));

  return DBFileInfo(dbFileBytes, mediaStream);
}

Future overwriteDefaultDB(Uint8List dataStore) async {
  const List<int> sqliteHeader = [
    0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66,
    0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00,
  ];
  bool isValidSqlite = dataStore.length >= sqliteHeader.length;
  if (isValidSqlite) {
    for (int i = 0; i < sqliteHeader.length; i++) {
      if (dataStore[i] != sqliteHeader[i]) {
        isValidSqlite = false;
        break;
      }
    }
  }
  if (!isValidSqlite) {
    throw const FormatException(
        "Selected file is not a valid SQLite database backup.");
  }

  try {
    await database.close();
  } catch (e) {
    print("Error closing database before overwrite: $e");
  }

  final dbFolder = await getApplicationDocumentsDirectory();
  for (final suffix in ['-wal', '-shm', '-journal']) {
    final auxFile = File(p.join(dbFolder.path, 'db.sqlite$suffix'));
    if (await auxFile.exists()) {
      await auxFile.delete();
    }
  }

  final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));
  await dbFile.writeAsBytes(dataStore, flush: true);
  // we need to be able to sync with others after the restore
  await sharedPreferences.setString("dateOfLastSyncedWithClient", "{}");
}
