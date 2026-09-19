import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('build sqlite3 yang dibundel adalah SQLCipher', () {
    final db = sqlite3.openInMemory();
    expect(db.select('PRAGMA cipher_version'), isNotEmpty);
    db.close();
  });

  test('file DB berkunci tidak bisa dibuka tanpa kunci', () {
    final dir = Directory.systemTemp.createTempSync('gemi');
    final path = '${dir.path}/enc.db';
    final a = sqlite3.open(path)
      ..execute("PRAGMA key = \"x'${'ab' * 32}'\"")
      ..execute('CREATE TABLE t (x INTEGER)')
      ..execute('INSERT INTO t VALUES (1)');
    a.close();

    final b = sqlite3.open(path);
    expect(() => b.select('SELECT * FROM t'), throwsA(isA<SqliteException>()));
    b.close();

    final c = sqlite3.open(path)..execute("PRAGMA key = \"x'${'ab' * 32}'\"");
    expect(c.select('SELECT x FROM t').single['x'], 1);
    c.close();
    dir.deleteSync(recursive: true);
  });
}
