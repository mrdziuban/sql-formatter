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
      test ("Formatting of '" ++ word ++ "'") <|
        \() -> Expect.equal (SQLFormatter.format ("foo " ++ word ++ " bar") 2) ("foo\n  " ++ word ++ " bar"))
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
  ]

testUntabbedKeywords: List Test
testUntabbedKeywords =
  List.map
    (\word ->
      test ("Formatting of '" ++ word ++ "'") <|
        \() -> Expect.equal (SQLFormatter.format ("foo " ++ word ++ " bar") 2) ("foo\n" ++ word ++ " bar"))
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
  , "SET"
  ]

testUnchangedKeywords: List Test
testUnchangedKeywords =
  List.map
    (\word ->
      test ("Formatting of '" ++ word ++ "'") <|
        \() -> Expect.equal (SQLFormatter.format ("foo " ++ word ++ " bar") 2) ("foo " ++ word ++ " bar"))
    unchangedKeywords

testSelects: List Test
testSelects =
  [ test "Formatting of 'SELECT'" <|
      \() -> Expect.equal (SQLFormatter.format "SELECT foo bar" 2) "SELECT foo bar"
  , test "Formatting of ' SELECT'" <|
      \() -> Expect.equal (SQLFormatter.format " SELECT foo bar" 2) "SELECT foo bar"
  , test "Formatting of '(SELECT'" <|
      \() -> Expect.equal (SQLFormatter.format "foo (SELECT bar" 2) "foo\n  (SELECT bar"
  , test "Formatting of '( SELECT'" <|
      \() -> Expect.equal (SQLFormatter.format "foo ( SELECT bar" 2) "foo\n  (SELECT bar"
  , test "Formatting of ') SELECT'" <|
      \() -> Expect.equal (SQLFormatter.format "foo) SELECT bar" 2) "foo)\nSELECT bar"
  , test "Formatting of ')SELECT'" <|
      \() -> Expect.equal (SQLFormatter.format "foo)SELECT bar" 2) "foo)\nSELECT bar"
  , test "Formatting when selecting multiple fields" <|
      \() -> Expect.equal (SQLFormatter.format "SELECT foo, bar, baz" 2) "SELECT foo,\n    bar,\n    baz"
  ]

testUpdates: List Test
testUpdates =
  [ test "Formatting of 'UPDATE'" <|
      \() -> Expect.equal (SQLFormatter.format "UPDATE foo bar" 2) "UPDATE foo bar"
  , test "Formatting of ' UPDATE'" <|
      \() -> Expect.equal (SQLFormatter.format " UPDATE foo bar" 2) "UPDATE foo bar"
  ]

testUpcasedKeywords: List Test
testUpcasedKeywords =
  List.map
    (\word ->
      test ("Upcasing of '" ++ word ++ "'") <|
        \() -> Expect.equal (String.trim (SQLFormatter.format (" " ++ (String.toLower word) ++ " ") 2)) word)
    (tabbedKeywords ++ untabbedKeywords ++ unchangedKeywords ++ [ "SELECT", "UPDATE", "THEN", "UNION", "USING" ])

all: Test
all =
  describe "SQLFormatter tests"
    [ describe "Tabbed keywords" testTabbedKeywords
    , describe "Untabbed keywords" testUntabbedKeywords
    , describe "Unchanged keywords" testUnchangedKeywords
    , describe "SELECTs" testSelects
    , describe "UPDATEs" testUpdates
    , describe "Special case keywords"
      [ test "Formatting of 'THEN'" <|
          \() -> Expect.equal (SQLFormatter.format "foo THEN bar" 2) "foo THEN\n  bar"
      , test "Formatting of 'UNION'" <|
          \() -> Expect.equal (SQLFormatter.format "foo UNION bar" 2) "foo\nUNION\nbar"
      , test "Formatting of 'USING'" <|
          \() -> Expect.equal (SQLFormatter.format "foo USING bar" 2) "foo\nUSING bar"
      ]
    , describe "Nested queries"
      [ test "Formatting of single nested query" <|
          \() -> Expect.equal
            (SQLFormatter.format "SELECT foo FROM (SELECT bar FROM baz)" 2)
            "SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)"
      , test "Formatting of multiple nested queries" <|
          \() -> Expect.equal
            (SQLFormatter.format "SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))" 2)
            "SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))"
      ]
    , describe "Case transformations" testUpcasedKeywords
    ]
