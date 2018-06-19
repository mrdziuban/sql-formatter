open Jest;
open Expect;

let fmt = SqlFormatter.format;

let tabbedKeywords = [
  "AND",
  "BETWEEN",
  "CASE",
  "ELSE",
  "END",
  "ON",
  "OR",
  "OVER",
  "WHEN"
];

let untabbedKeywords = [
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
];

let unchangedKeywords = [
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
];

let testFullQueries = (numSpaces: int) => {
  let tab = Js.String.repeat(numSpaces, " ");

  test("formatting a full SELECT query", () =>
    expect(fmt("SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1", numSpaces)) |>
      toEqual("SELECT a.b,\n" ++ tab ++ tab ++ "c.d\nFROM a\nJOIN b\n" ++ tab ++ "ON a.b = c.d\nWHERE a.b = 1\n" ++ tab ++ "AND c.d = 1"));

  test("formatting a full UPDATE query", () =>
    expect(fmt("UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3", numSpaces)) |>
      toEqual("UPDATE a\nSET a.b = 1,\n" ++ tab ++ tab ++ "a.c = 2\nWHERE a.d = 3"));

  test("formatting a full DELETE query", () =>
    expect(fmt("DELETE FROM a WHERE a.b = 1 AND a.c = 2", numSpaces)) |>
      toEqual("DELETE\nFROM a\nWHERE a.b = 1\n" ++ tab ++ "AND a.c = 2"));
};

describe("format", () => {
  describe("formatting of tabbed keywords", () =>
    List.iter(
      word => test("formatting of '" ++ word ++ "'", () =>
        expect(fmt("foo " ++ word ++ " bar", 2)) |> toEqual("foo\n  " ++ word ++ " bar")),
      tabbedKeywords));

  describe("formatting of untabbed keywords", () =>
    List.iter(
      word => test("formatting of '" ++ word ++ "'", () =>
        expect(fmt("foo " ++ word ++ " bar", 2)) |> toEqual("foo\n" ++ word ++ " bar")),
      untabbedKeywords));

  describe("formatting of unchanged keywords", () =>
    List.iter(
      word => test("formatting of '" ++ word ++ "'", () =>
        expect(fmt("foo " ++ word ++ " bar", 2)) |> toEqual("foo " ++ word ++ " bar")),
      unchangedKeywords));

  describe("SELECTs", () => {
    test("formatting of 'SELECT'", () => expect(fmt("SELECT foo bar", 2)) |> toEqual("SELECT foo bar"));
    test("formatting of ' SELECT'", () => expect(fmt(" SELECT foo bar", 2)) |> toEqual("SELECT foo bar"));
    test("formatting of '(SELECT'", () => expect(fmt("foo (SELECT bar", 2)) |> toEqual("foo\n  (SELECT bar"));
    test("formatting of '( SELECT'", () => expect(fmt("foo ( SELECT bar", 2)) |> toEqual("foo\n  (SELECT bar"));
    test("formatting of ') SELECT'", () => expect(fmt("foo) SELECT bar", 2)) |> toEqual("foo)\nSELECT bar"));
    test("formatting of ')SELECT'", () => expect(fmt("foo)SELECT bar", 2)) |> toEqual("foo)\nSELECT bar"));
    test("Formatting when selecting multiple fields", () =>
      expect(fmt("SELECT foo, bar, baz", 2)) |> toEqual("SELECT foo,\n    bar,\n    baz"));
  });

  describe("UPDATEs", () => {
    test("formatting of 'UPDATE'", () => expect(fmt("UPDATE foo bar", 2)) |> toEqual("UPDATE foo bar"));
    test("formatting of ' UPDATE'", () => expect(fmt(" UPDATE foo bar", 2)) |> toEqual("UPDATE foo bar"));
  });

  describe("DELETEs", () => {
    test("formatting of 'DELETE'", () => expect(fmt("DELETE foo bar", 2)) |> toEqual("DELETE foo bar"));
    test("formatting of ' DELETE'", () => expect(fmt(" DELETE foo bar", 2)) |> toEqual("DELETE foo bar"));
  });

  describe("special case keywords", () => {
    test("formatting of 'THEN'", () => expect(fmt("foo THEN bar", 2)) |> toEqual("foo THEN\n  bar"));
    test("formatting of 'UNION'", () => expect(fmt("foo UNION bar", 2)) |> toEqual("foo\nUNION\nbar"));
    test("formatting of 'USING'", () => expect(fmt("foo USING bar", 2)) |> toEqual("foo\nUSING bar"));
  });

  describe("nested queries", () => {
    test("formatting of single nested query", () =>
      expect(fmt("SELECT foo FROM (SELECT bar FROM baz)", 2)) |>
        toEqual("SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)"));

    test("formatting of multiple nested queries", () =>
      expect(fmt("SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))", 2)) |>
        toEqual("SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))"));
  });

  describe("case transformations", () =>
    List.iter(
      word => test("upcasing of '" ++ word ++ "'", () =>
        expect(String.trim(fmt(" " ++ String.lowercase(word) ++ " ", 2))) |> toEqual(word)),
      List.concat([
        tabbedKeywords,
        untabbedKeywords,
        unchangedKeywords,
        ["SELECT", "UPDATE", "THEN", "UNION", "USING"]])));

  describe("formatting full queries", () => testFullQueries(2));

  describe("formatting queries with a different number of spaces", () => testFullQueries(4));
});
