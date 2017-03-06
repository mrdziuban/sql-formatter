package mrdziuban.sqlFormatter

import org.scalatest.FunSpec

class SQLFormatterSpec extends FunSpec {
  object keywords {
    val tabbedKeywords = List(
      "AND",
      "BETWEEN",
      "CASE",
      "ELSE",
      "END",
      "ON",
      "OR",
      "OVER",
      "WHEN"
    )

    val untabbedKeywords = List(
      "FROM",
      "GROUP BY",
      "HAVING",
      "JOIN",
      "CROSS JOIN",
      "INNER JOIN",
      "LEFT JOIN",
      "RIGHT JOIN",
      "ORDER BY",
      "WHERE",
      "WITH",
      "SET"
    )

    val unchangedKeywords = List(
      "IN",
      "ALL",
      "AS",
      "ASC",
      "DESC",
      "DISTINCT",
      "EXISTS",
      "NOT",
      "NULL",
      "LIKE"
    )
  }

  import keywords._

  describe("format") {
    describe("tabbed keywords")(tabbedKeywords.foreach(word =>
      it(s"formatting of '$word'")(assertResult(s"foo\n  $word bar")(SQLFormatter.format(s"foo $word bar", 2)))))

    describe("untabbed keywords")(untabbedKeywords.foreach(word =>
      it(s"formatting of '$word'")(assertResult(s"foo\n$word bar")(SQLFormatter.format(s"foo $word bar", 2)))))

    describe("unchanged keywords")(unchangedKeywords.foreach(word =>
      it(s"formatting of '$word'")(assertResult(s"foo $word bar")(SQLFormatter.format(s"foo $word bar", 2)))))

    describe("SELECTs") {
      it("formatting of 'SELECT'")(assertResult("SELECT foo bar")(SQLFormatter.format("SELECT foo bar", 2)))
      it("formatting of ' SELECT'")(assertResult("SELECT foo bar")(SQLFormatter.format(" SELECT foo bar", 2)))
      it("formatting of '(SELECT'")(assertResult("foo\n  (SELECT bar")(SQLFormatter.format("foo (SELECT bar", 2)))
      it("formatting of '( SELECT'")(assertResult("foo\n  (SELECT bar")(SQLFormatter.format("foo ( SELECT bar", 2)))
      it("formatting of ') SELECT'")(assertResult("foo)\nSELECT bar")(SQLFormatter.format("foo) SELECT bar", 2)))
      it("formatting of ')SELECT'")(assertResult("foo)\nSELECT bar")(SQLFormatter.format("foo)SELECT bar", 2)))
      it("formatting when selecting multiple fields")(
        assertResult("SELECT foo,\n    bar,\n    baz")(SQLFormatter.format("SELECT foo, bar, baz", 2)))
    }

    describe("UPDATEs") {
      it("formatting of 'UPDATE'")(assertResult("UPDATE foo bar")(SQLFormatter.format("UPDATE foo bar", 2)))
      it("formatting of ' UPDATE'")(assertResult("UPDATE foo bar")(SQLFormatter.format(" UPDATE foo bar", 2)))
    }

    describe("DELETEs") {
      it("formatting of 'DELETE'")(assertResult("DELETE foo bar")(SQLFormatter.format("DELETE foo bar", 2)))
      it("formatting of ' DELETE'")(assertResult("DELETE foo bar")(SQLFormatter.format(" DELETE foo bar", 2)))
    }

    describe("special case keywords") {
      it("formatting of 'THEN'")(assertResult("foo THEN\n  bar")(SQLFormatter.format("foo THEN bar", 2)))
      it("formatting of 'UNION'")(assertResult("foo\nUNION\nbar")(SQLFormatter.format("foo UNION bar", 2)))
      it("formatting of 'USING'")(assertResult("foo\nUSING bar")(SQLFormatter.format("foo USING bar", 2)))
    }

    describe("nested queries") {
      it("formatting of single nested query")(
        assertResult("SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)")(
          SQLFormatter.format("SELECT foo FROM (SELECT bar FROM baz)", 2)))

      it("formatting of multiple nested queries")(
        assertResult("SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))")(
          SQLFormatter.format("SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))", 2)))
    }

    describe("case transformations")(
      (tabbedKeywords ++ untabbedKeywords ++ unchangedKeywords ++ List("SELECT", "UPDATE", "THEN", "UNION", "USING")).foreach(word =>
        it(s"upcasing of $word")(assertResult(word)(SQLFormatter.format(s" ${word.toLowerCase} ", 2).trim))))

    Map("formatting full queries" -> 1, "formatting queries with a different number of spaces" -> 4).foreach(t =>
      describe(t._1) {
        val tab = " " * t._2

        it("formatting a full SELECT query")(
          assertResult(s"SELECT a.b,\n${tab}${tab}c.d\nFROM a\nJOIN b\n${tab}ON a.b = c.d\nWHERE a.b = 1\n${tab}AND c.d = 1")(
            SQLFormatter.format("SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1", t._2)))

        it("formatting a full UPDATE query")(
          assertResult(s"UPDATE a\nSET a.b = 1,\n${tab}${tab}a.c = 2\nWHERE a.d = 3")(
            SQLFormatter.format("UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3", t._2)))

        it("formatting a full DELETE query")(
          assertResult(s"DELETE\nFROM a\nWHERE a.b = 1\n${tab}AND a.c = 2")(
            SQLFormatter.format("DELETE FROM a WHERE a.b = 1 AND a.c = 2", t._2)))
      })
  }
}
