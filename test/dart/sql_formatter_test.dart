import 'package:test/test.dart';

import '../../dart/src/sql_formatter.dart';

List<String> tabbedKeywords = [
  'AND',
  'BETWEEN',
  'CASE',
  'ELSE',
  'END',
  'ON',
  'OR',
  'OVER',
  'WHEN'
];

List<String> untabbedKeywords = [
  'FROM',
  'GROUP BY',
  'HAVING',
  'JOIN',
  'CROSS JOIN',
  'INNER JOIN',
  'LEFT JOIN',
  'RIGHT JOIN',
  'ORDER BY',
  'WHERE',
  'WITH',
  'SET'
];

List<String> unchangedKeywords = [
  'IN',
  'ALL',
  'AS',
  'ASC',
  'DESC',
  'DISTINCT',
  'EXISTS',
  'NOT',
  'NULL',
  'LIKE'
];

void testFullQueries(int numSpaces) {
  String tab = ' ' * numSpaces;

  test('formatting a full SELECT query', () {
    expect(
      SQLFormatter.format('SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1', numSpaces),
      equals('SELECT a.b,\n${tab}${tab}c.d\nFROM a\nJOIN b\n${tab}ON a.b = c.d\nWHERE a.b = 1\n${tab}AND c.d = 1')
    );
  });

  test('formatting a full UPDATE query', () {
    expect(
      SQLFormatter.format('UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3', numSpaces),
      equals('UPDATE a\nSET a.b = 1,\n${tab}${tab}a.c = 2\nWHERE a.d = 3')
    );
  });

  test('formatting a full DELETE query', () {
    expect(
      SQLFormatter.format('DELETE FROM a WHERE a.b = 1 AND a.c = 2', numSpaces),
      equals('DELETE\nFROM a\nWHERE a.b = 1\n${tab}AND a.c = 2')
    );
  });
}

void main() {
  group('SQLFormatter.format', () {
    group('tabbed keywords', () {
      tabbedKeywords.forEach((String word) {
        test("formatting of '$word'", () => expect(SQLFormatter.format('foo $word bar', 2), equals('foo\n  $word bar')));
      });
    });

    group('untabbed keywords', () {
      untabbedKeywords.forEach((String word) {
        test("formatting of '$word'", () => expect(SQLFormatter.format('foo $word bar', 2), equals('foo\n$word bar')));
      });
    });

    group('unchanged keywords', () {
      unchangedKeywords.forEach((String word) {
        test("formatting of '$word'", () => expect(SQLFormatter.format('foo $word bar', 2), equals('foo $word bar')));
      });
    });

    group('SELECTs', () {
      test("formatting of 'SELECT'", () => expect(SQLFormatter.format('SELECT foo bar', 2), equals('SELECT foo bar')));
      test("formatting of ' SELECT'", () => expect(SQLFormatter.format(' SELECT foo bar', 2), equals('SELECT foo bar')));
      test("formatting of '(SELECT'", () => expect(SQLFormatter.format('foo (SELECT bar', 2), equals('foo\n  (SELECT bar')));
      test("formatting of '( SELECT'", () => expect(SQLFormatter.format('foo ( SELECT bar', 2), equals('foo\n  (SELECT bar')));
      test("formatting of ') SELECT'", () => expect(SQLFormatter.format('foo) SELECT bar', 2), equals('foo)\nSELECT bar')));
      test("formatting of ')SELECT'", () => expect(SQLFormatter.format('foo)SELECT bar', 2), equals('foo)\nSELECT bar')));
      test("Formatting when selecting multiple fields", () => expect(SQLFormatter.format('SELECT foo, bar, baz', 2), equals('SELECT foo,\n    bar,\n    baz')));
    });

    group('UPDATEs', () {
      test("formatting of 'UPDATE'", () => expect(SQLFormatter.format('UPDATE foo bar', 2), equals('UPDATE foo bar')));
      test("formatting of ' UPDATE'", () => expect(SQLFormatter.format(' UPDATE foo bar', 2), equals('UPDATE foo bar')));
    });

    group('DELETEs', () {
      test("formatting of 'DELETE'", () => expect(SQLFormatter.format('DELETE foo bar', 2), equals('DELETE foo bar')));
      test("formatting of ' DELETE'", () => expect(SQLFormatter.format(' DELETE foo bar', 2), equals('DELETE foo bar')));
    });

    group('special case keywords', () {
      test("formatting of 'THEN'", () => expect(SQLFormatter.format('foo THEN bar', 2), equals('foo THEN\n  bar')));
      test("formatting of 'UNION'", () => expect(SQLFormatter.format('foo UNION bar', 2), equals('foo\nUNION\nbar')));
      test("formatting of 'USING'", () => expect(SQLFormatter.format('foo USING bar', 2), equals('foo\nUSING bar')));
    });

    group('nested queries', () {
      test('formatting of single nested query', () {
        expect(
          SQLFormatter.format('SELECT foo FROM (SELECT bar FROM baz)', 2),
          equals('SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)')
        );
      });

      test('formatting of multiple nested queries', () {
        expect(
          SQLFormatter.format('SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))', 2),
          equals('SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))')
        );
      });
    });

    group('case transformations', () {
      [
        tabbedKeywords,
        untabbedKeywords,
        unchangedKeywords,
        ['SELECT', 'UPDATE', 'THEN', 'UNION', 'USING']
      ].expand((x) => x).toList().forEach((String word) {
        test('upcasing of $word', () => expect(SQLFormatter.format(' ${word.toLowerCase()} ', 2).trim(), equals(word)));
      });
    });

    group('formatting full queries', () => testFullQueries(2));
    group('formatting queries with a different number of spaces', () => testFullQueries(4));
  });
}
