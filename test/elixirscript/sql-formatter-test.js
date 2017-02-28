import assert from 'assert';
import {execSync} from 'child_process';
import {readFileSync, writeFileSync} from 'fs';
import path from 'path';

const src = path.resolve(path.join(__dirname), '..', '..', 'elixirscript', 'src');
const out = path.join(__dirname, 'out');

// Compile ElixirScript code
execSync(`rm -rf ${out}`);
execSync(`elixirscript ${src} -o ${out}`);

const Elixir = require(path.join(out, 'Elixir.App.js')).default;
const SQLFormatter = Elixir.SQLFormatter.__load(Elixir);

const tabbedKeywords = [
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

const untabbedKeywords = [
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

const unchangedKeywords = [
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

const testFullQueries = (numSpaces) => {
  const tab = ' '.repeat(numSpaces);
  it('formatting a full SELECT query', () => {
    assert.equal(
      SQLFormatter.format('SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1', numSpaces),
      `SELECT a.b,\n${tab}${tab}c.d\nFROM a\nJOIN b\n${tab}ON a.b = c.d\nWHERE a.b = 1\n${tab}AND c.d = 1`
    );
  });

  it('formatting a full UPDATE query', () => {
    assert.equal(
      SQLFormatter.format('UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3', numSpaces),
      `UPDATE a\nSET a.b = 1,\n${tab}${tab}a.c = 2\nWHERE a.d = 3`
    );
  });

  it('formatting a full DELETE query', () => {
    assert.equal(
      SQLFormatter.format('DELETE FROM a WHERE a.b = 1 AND a.c = 2', numSpaces),
      `DELETE\nFROM a\nWHERE a.b = 1\n${tab}AND a.c = 2`
    );
  });
};

describe('SQLFormatter.format', () => {
  describe('formatting of tabbed keywords', () => {
    tabbedKeywords.forEach((word) => {
      it(`formatting of '${word}'`, () => assert.equal(SQLFormatter.format(`foo ${word} bar`, 2), `foo\n  ${word} bar`));
    });
  });

  describe('formatting of untabbed keywords', () => {
    untabbedKeywords.forEach((word) => {
      it(`formatting of '${word}'`, () => assert.equal(SQLFormatter.format(`foo ${word} bar`, 2), `foo\n${word} bar`));
    });
  });

  describe('formatting of unchanged keywords', () => {
    unchangedKeywords.forEach((word) => {
      it(`formatting of '${word}'`, () => assert.equal(SQLFormatter.format(`foo ${word} bar`, 2), `foo ${word} bar`));
    });
  });

  describe('SELECTs', () => {
    it("formatting of 'SELECT'", () => assert.equal(SQLFormatter.format('SELECT foo bar', 2), 'SELECT foo bar'));
    it("formatting of ' SELECT'", () => assert.equal(SQLFormatter.format(' SELECT foo bar', 2), 'SELECT foo bar'));
    it("formatting of '(SELECT'", () => assert.equal(SQLFormatter.format('foo (SELECT bar', 2), 'foo\n  (SELECT bar'));
    it("formatting of '( SELECT'", () => assert.equal(SQLFormatter.format('foo ( SELECT bar', 2), 'foo\n  (SELECT bar'));
    it("formatting of ') SELECT'", () => assert.equal(SQLFormatter.format('foo) SELECT bar', 2), 'foo)\nSELECT bar'));
    it("formatting of ')SELECT'", () => assert.equal(SQLFormatter.format('foo)SELECT bar', 2), 'foo)\nSELECT bar'));
    it("Formatting when selecting multiple fields", () => assert.equal(SQLFormatter.format('SELECT foo, bar, baz', 2), 'SELECT foo,\n    bar,\n    baz'));
  });

  describe('UPDATEs', () => {
    it("formatting of 'UPDATE'", () => assert.equal(SQLFormatter.format('UPDATE foo bar', 2), 'UPDATE foo bar'));
    it("formatting of ' UPDATE'", () => assert.equal(SQLFormatter.format(' UPDATE foo bar', 2), 'UPDATE foo bar'));
  });

  describe('DELETEs', () => {
    it("formatting of 'DELETE'", () => assert.equal(SQLFormatter.format('DELETE foo bar', 2), 'DELETE foo bar'));
    it("formatting of ' DELETE'", () => assert.equal(SQLFormatter.format(' DELETE foo bar', 2), 'DELETE foo bar'));
  });

  describe('special case keywords', () => {
    it("formatting of 'THEN'", () => assert.equal(SQLFormatter.format('foo THEN bar', 2), 'foo THEN\n  bar'));
    it("formatting of 'UNION'", () => assert.equal(SQLFormatter.format('foo UNION bar', 2), 'foo\nUNION\nbar'));
    it("formatting of 'USING'", () => assert.equal(SQLFormatter.format('foo USING bar', 2), 'foo\nUSING bar'));
  });

  describe('nested queries', () => {
    it('formatting of single nested query', () => {
      assert.equal(
        SQLFormatter.format('SELECT foo FROM (SELECT bar FROM baz)', 2),
        'SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)'
      );
    });

    it('formatting of multiple nested queries', () => {
      assert.equal(
        SQLFormatter.format('SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))', 2),
        'SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))'
      );
    });
  });

  describe('case transformations', () => {
    [].concat.apply(
      tabbedKeywords,
      untabbedKeywords,
      unchangedKeywords,
      ['SELECT', 'UPDATE', 'THEN', 'UNION', 'USING']
    ).forEach(word => {
      it(`upcasing of '${word}'`, () => assert.equal(SQLFormatter.format(` ${word.toLowerCase()} `, 2).trim(), word));
    });
  });

  describe('formatting full queries', () => testFullQueries(2));

  describe('formatting queries with a different number of spaces', () => testFullQueries(4));
});
