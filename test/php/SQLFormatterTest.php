<?php

use PHPUnit\Framework\TestCase;

class SQLFormatterTest extends TestCase {
  protected $formatter;

  private $tabbedKeywords = array(
    'AND',
    'BETWEEN',
    'CASE',
    'ELSE',
    'END',
    'ON',
    'OR',
    'OVER',
    'WHEN'
  );

  private $untabbedKeywords = array(
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
  );

  private $unchangedKeywords = array(
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
  );

  protected function setUp() {
    $this->formatter = new SQLFormatter;
  }

  public function testTabbedKeywords() {
    foreach($this->tabbedKeywords as $word) {
      $this->assertEquals("foo\n  $word bar", $this->formatter->format("foo $word bar", 2), "formatting of $word");
    }
  }

  public function testUntabbedKeywords() {
    foreach($this->untabbedKeywords as $word) {
      $this->assertEquals("foo\n$word bar", $this->formatter->format("foo $word bar", 2), "formatting of $word");
    }
  }

  public function testUnchangedKeywords() {
    foreach($this->unchangedKeywords as $word) {
      $this->assertEquals("foo $word bar", $this->formatter->format("foo $word bar", 2), "formatting of $word");
    }
  }

  public function testSelects() {
    $this->assertEquals("SELECT foo bar", $this->formatter->format('SELECT foo bar', 2) ,"formatting of 'SELECT'");
    $this->assertEquals("SELECT foo bar", $this->formatter->format(' SELECT foo bar', 2) ,"formatting of ' SELECT'");
    $this->assertEquals("foo\n  (SELECT bar", $this->formatter->format('foo (SELECT bar', 2) ,"formatting of '(SELECT'");
    $this->assertEquals("foo\n  (SELECT bar", $this->formatter->format('foo ( SELECT bar', 2) ,"formatting of '( SELECT'");
    $this->assertEquals("foo)\nSELECT bar", $this->formatter->format('foo) SELECT bar', 2) ,"formatting of ') SELECT'");
    $this->assertEquals("foo)\nSELECT bar", $this->formatter->format('foo)SELECT bar', 2) ,"formatting of ')SELECT'");
    $this->assertEquals("SELECT foo,\n    bar,\n    baz", $this->formatter->format('SELECT foo, bar, baz', 2) ,"Formatting when selecting multiple fields");
  }

  public function testUpdates() {
    $this->assertEquals('UPDATE foo bar', $this->formatter->format('UPDATE foo bar', 2), "formatting of 'UPDATE'");
    $this->assertEquals('UPDATE foo bar', $this->formatter->format(' UPDATE foo bar', 2), "formatting of ' UPDATE'");
  }

  public function testDeletes() {
    $this->assertEquals('DELETE foo bar', $this->formatter->format('DELETE foo bar', 2), "formatting of 'DELETE'");
    $this->assertEquals('DELETE foo bar', $this->formatter->format(' DELETE foo bar', 2), "formatting of ' DELETE'");
  }

  public function testSpecialCaseKeywords() {
    $this->assertEquals("foo THEN\n  bar", $this->formatter->format('foo THEN bar', 2), "formatting of 'THEN'");
    $this->assertEquals("foo\nUNION\nbar", $this->formatter->format('foo UNION bar', 2), "formatting of 'UNION'");
    $this->assertEquals("foo\nUSING bar", $this->formatter->format('foo USING bar', 2), "formatting of 'USING'");
  }

  public function testNestedQueries() {
    $this->assertEquals(
      "SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)",
      $this->formatter->format('SELECT foo FROM (SELECT bar FROM baz)', 2),
      'formatting of single nested query'
    );

    $this->assertEquals(
      "SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))",
      $this->formatter->format('SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))', 2),
      'formatting of multiple nested queries'
    );
  }

  public function testCaseTransformations() {
    $words = array_merge(
      $this->tabbedKeywords,
      $this->untabbedKeywords,
      $this->unchangedKeywords,
      array('SELECT', 'UPDATE', 'THEN', 'UNION', 'USING')
    );
    foreach($words as $word) {
      $lowercase = strtolower($word);
      $this->assertEquals($word, trim($this->formatter->format(" $lowercase ", 2)), "upcasing of $word");
    }
  }

  public function testFullQueries() {
    foreach(array(2, 4) as $numSpaces) {
      $tab = str_repeat(' ', $numSpaces);

      $this->assertEquals(
        "SELECT a.b,\n${tab}${tab}c.d\nFROM a\nJOIN b\n${tab}ON a.b = c.d\nWHERE a.b = 1\n${tab}AND c.d = 1",
        $this->formatter->format('SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1', $numSpaces),
        "formatting a full SELECT query with $numSpaces spaces"
      );

      $this->assertEquals(
        "UPDATE a\nSET a.b = 1,\n${tab}${tab}a.c = 2\nWHERE a.d = 3",
        $this->formatter->format('UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3', $numSpaces),
        "formatting a full UPDATE query with $numSpaces spaces"
      );

      $this->assertEquals(
        "DELETE\nFROM a\nWHERE a.b = 1\n${tab}AND a.c = 2",
        $this->formatter->format('DELETE FROM a WHERE a.b = 1 AND a.c = 2', $numSpaces),
        "formatting a full DELETE query with $numSpaces spaces"
      );
    }
  }
}
