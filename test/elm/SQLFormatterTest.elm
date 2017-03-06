module SQLFormatterTest exposing (all)

import Test exposing (..)
import Expect

import SQLFormatter

tabbedKeywords: List String
tabbedKeywords =
  [ "AND"
  , "BETWEEN"
  , "CASE"
  , "ELSE"
  , "END"
  , "ON"
  , "OR"
  , "OVER"
  , "WHEN"
  ]

testTabbedKeywords: List Test
testTabbedKeywords =
  List.map
    (\word ->
      test ("formatting of '" ++ word ++ "'") <|
        \() -> Expect.equal ("foo\n  " ++ word ++ " bar") (SQLFormatter.format ("foo " ++ word ++ " bar") 2))
    tabbedKeywords

untabbedKeywords: List String
untabbedKeywords =
  [ "FROM"
  , "GROUP BY"
  , "HAVING"
  , "JOIN"
  , "CROSS JOIN"
  , "INNER JOIN"
  , "LEFT JOIN"
  , "RIGHT JOIN"
  , "ORDER BY"
  , "WHERE"
  , "WITH"
  , "SET"
  ]

testUntabbedKeywords: List Test
testUntabbedKeywords =
  List.map
    (\word ->
      test ("formatting of '" ++ word ++ "'") <|
        \() -> Expect.equal ("foo\n" ++ word ++ " bar") (SQLFormatter.format ("foo " ++ word ++ " bar") 2))
    untabbedKeywords

unchangedKeywords: List String
unchangedKeywords =
  [ "IN"
  , "ALL"
  , "AS"
  , "ASC"
  , "DESC"
  , "DISTINCT"
  , "EXISTS"
  , "NOT"
  , "NULL"
  , "LIKE"
  ]

testUnchangedKeywords: List Test
testUnchangedKeywords =
  List.map
    (\word ->
      test ("formatting of '" ++ word ++ "'") <|
        \() -> Expect.equal ("foo " ++ word ++ " bar") (SQLFormatter.format ("foo " ++ word ++ " bar") 2))
    unchangedKeywords

testSelects: List Test
testSelects =
  [ test "formatting of 'SELECT'" <|
      \() -> Expect.equal "SELECT foo bar" (SQLFormatter.format "SELECT foo bar" 2)
  , test "formatting of ' SELECT'" <|
      \() -> Expect.equal "SELECT foo bar" (SQLFormatter.format " SELECT foo bar" 2)
  , test "formatting of '(SELECT'" <|
      \() -> Expect.equal "foo\n  (SELECT bar" (SQLFormatter.format "foo (SELECT bar" 2)
  , test "formatting of '( SELECT'" <|
      \() -> Expect.equal "foo\n  (SELECT bar" (SQLFormatter.format "foo ( SELECT bar" 2)
  , test "formatting of ') SELECT'" <|
      \() -> Expect.equal "foo)\nSELECT bar" (SQLFormatter.format "foo) SELECT bar" 2)
  , test "formatting of ')SELECT'" <|
      \() -> Expect.equal "foo)\nSELECT bar" (SQLFormatter.format "foo)SELECT bar" 2)
  , test "Formatting when selecting multiple fields" <|
      \() -> Expect.equal "SELECT foo,\n    bar,\n    baz" (SQLFormatter.format "SELECT foo, bar, baz" 2)
  ]

testUpdates: List Test
testUpdates =
  [ test "formatting of 'UPDATE'" <|
      \() -> Expect.equal "UPDATE foo bar" (SQLFormatter.format "UPDATE foo bar" 2)
  , test "formatting of ' UPDATE'" <|
      \() -> Expect.equal "UPDATE foo bar" (SQLFormatter.format " UPDATE foo bar" 2)
  ]

testDeletes: List Test
testDeletes =
  [ test "formatting of 'DELETE'" <|
      \() -> Expect.equal "DELETE foo bar" (SQLFormatter.format "DELETE foo bar" 2)
  , test "formatting of ' DELETE'" <|
      \() -> Expect.equal "DELETE foo bar" (SQLFormatter.format " DELETE foo bar" 2)
  ]

testUpcasedKeywords: List Test
testUpcasedKeywords =
  List.map
    (\word ->
      test ("Upcasing of '" ++ word ++ "'") <|
        \() -> Expect.equal word (String.trim (SQLFormatter.format (" " ++ (String.toLower word) ++ " ") 2)))
    (tabbedKeywords ++ untabbedKeywords ++ unchangedKeywords ++ [ "SELECT", "UPDATE", "THEN", "UNION", "USING" ])

testFullQueries: Int -> List Test
testFullQueries numSpaces =
  let
    tab = String.repeat numSpaces " "
  in
    [ test "formatting a full SELECT query" <|
        \() -> Expect.equal
          ("SELECT a.b,\n" ++ tab ++ tab ++ "c.d\nFROM a\nJOIN b\n" ++ tab ++ "ON a.b = c.d\nWHERE a.b = 1\n" ++ tab ++ "AND c.d = 1")
          (SQLFormatter.format "SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1" numSpaces)
    , test "formatting a full UPDATE query" <|
        \() -> Expect.equal
          ("UPDATE a\nSET a.b = 1,\n" ++ tab ++ tab ++ "a.c = 2\nWHERE a.d = 3")
          (SQLFormatter.format "UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3" numSpaces)
    , test "formatting a full DELETE query" <|
        \() -> Expect.equal
          ("DELETE\nFROM a\nWHERE a.b = 1\n" ++ tab ++ "AND a.c = 2")
          (SQLFormatter.format "DELETE FROM a WHERE a.b = 1 AND a.c = 2" numSpaces)
    ]

all: Test
all =
  describe "SQLFormatter tests"
    [ describe "tabbed keywords" testTabbedKeywords
    , describe "untabbed keywords" testUntabbedKeywords
    , describe "unchanged keywords" testUnchangedKeywords
    , describe "SELECTs" testSelects
    , describe "UPDATEs" testUpdates
    , describe "DELETEs" testDeletes
    , describe "special case keywords"
      [ test "formatting of 'THEN'" <|
          \() -> Expect.equal "foo THEN\n  bar" (SQLFormatter.format "foo THEN bar" 2)
      , test "formatting of 'UNION'" <|
          \() -> Expect.equal "foo\nUNION\nbar" (SQLFormatter.format "foo UNION bar" 2)
      , test "formatting of 'USING'" <|
          \() -> Expect.equal "foo\nUSING bar" (SQLFormatter.format "foo USING bar" 2)
      ]
    , describe "Nested queries"
      [ test "formatting of single nested query" <|
          \() -> Expect.equal
            "SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)"
            (SQLFormatter.format "SELECT foo FROM (SELECT bar FROM baz)" 2)
      , test "formatting of multiple nested queries" <|
          \() -> Expect.equal
            "SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))"
            (SQLFormatter.format "SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))" 2)
      ]
    , describe "case transformations" testUpcasedKeywords
    , describe "formatting full queries" (testFullQueries 2)
    , describe "formatting queries with a different number of spaces" (testFullQueries 4)
    ]
