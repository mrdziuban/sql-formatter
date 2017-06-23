module Test.SQLFormatter where

import Prelude (($), (<>), discard, Unit)
import Control.Monad.Free (Free)
import Data.Array (replicate)
import Data.String (fromCharArray, trim)
import Test.Unit (suite, test, TestF)
import Test.Unit.Assert as Assert

import SQLFormatter (formatSql)

testTabbedKeywords :: forall a. Free (TestF a) Unit
testTabbedKeywords = do
  test "formatting of 'AND'" $ Assert.equal "foo\n  AND bar" (formatSql "foo AND bar" 2)
  test "formatting of 'BETWEEN'" $ Assert.equal "foo\n  BETWEEN bar" (formatSql "foo BETWEEN bar" 2)
  test "formatting of 'CASE'" $ Assert.equal "foo\n  CASE bar" (formatSql "foo CASE bar" 2)
  test "formatting of 'ELSE'" $ Assert.equal "foo\n  ELSE bar" (formatSql "foo ELSE bar" 2)
  test "formatting of 'END'" $ Assert.equal "foo\n  END bar" (formatSql "foo END bar" 2)
  test "formatting of 'ON'" $ Assert.equal "foo\n  ON bar" (formatSql "foo ON bar" 2)
  test "formatting of 'OR'" $ Assert.equal "foo\n  OR bar" (formatSql "foo OR bar" 2)
  test "formatting of 'OVER'" $ Assert.equal "foo\n  OVER bar" (formatSql "foo OVER bar" 2)
  test "formatting of 'WHEN'" $ Assert.equal "foo\n  WHEN bar" (formatSql "foo WHEN bar" 2)

testUntabbedKeywords :: forall a. Free (TestF a) Unit
testUntabbedKeywords = do
  test "formatting of 'FROM'" $ Assert.equal "foo\nFROM bar" (formatSql "foo FROM bar" 2)
  test "formatting of 'GROUP BY'" $ Assert.equal "foo\nGROUP BY bar" (formatSql "foo GROUP BY bar" 2)
  test "formatting of 'HAVING'" $ Assert.equal "foo\nHAVING bar" (formatSql "foo HAVING bar" 2)
  test "formatting of 'JOIN'" $ Assert.equal "foo\nJOIN bar" (formatSql "foo JOIN bar" 2)
  test "formatting of 'CROSS JOIN'" $ Assert.equal "foo\nCROSS JOIN bar" (formatSql "foo CROSS JOIN bar" 2)
  test "formatting of 'INNER JOIN'" $ Assert.equal "foo\nINNER JOIN bar" (formatSql "foo INNER JOIN bar" 2)
  test "formatting of 'LEFT JOIN'" $ Assert.equal "foo\nLEFT JOIN bar" (formatSql "foo LEFT JOIN bar" 2)
  test "formatting of 'RIGHT JOIN'" $ Assert.equal "foo\nRIGHT JOIN bar" (formatSql "foo RIGHT JOIN bar" 2)
  test "formatting of 'ORDER BY'" $ Assert.equal "foo\nORDER BY bar" (formatSql "foo ORDER BY bar" 2)
  test "formatting of 'WHERE'" $ Assert.equal "foo\nWHERE bar" (formatSql "foo WHERE bar" 2)
  test "formatting of 'WITH'" $ Assert.equal "foo\nWITH bar" (formatSql "foo WITH bar" 2)
  test "formatting of 'SET'" $ Assert.equal "foo\nSET bar" (formatSql "foo SET bar" 2)

testUnchangedKeywords :: forall a. Free (TestF a) Unit
testUnchangedKeywords = do
  test "formatting of 'IN'" $ Assert.equal "foo IN bar" (formatSql "foo IN bar" 2)
  test "formatting of 'ALL'" $ Assert.equal "foo ALL bar" (formatSql "foo ALL bar" 2)
  test "formatting of 'AS'" $ Assert.equal "foo AS bar" (formatSql "foo AS bar" 2)
  test "formatting of 'ASC'" $ Assert.equal "foo ASC bar" (formatSql "foo ASC bar" 2)
  test "formatting of 'DESC'" $ Assert.equal "foo DESC bar" (formatSql "foo DESC bar" 2)
  test "formatting of 'DISTINCT'" $ Assert.equal "foo DISTINCT bar" (formatSql "foo DISTINCT bar" 2)
  test "formatting of 'EXISTS'" $ Assert.equal "foo EXISTS bar" (formatSql "foo EXISTS bar" 2)
  test "formatting of 'NOT'" $ Assert.equal "foo NOT bar" (formatSql "foo NOT bar" 2)
  test "formatting of 'NULL'" $ Assert.equal "foo NULL bar" (formatSql "foo NULL bar" 2)
  test "formatting of 'LIKE'" $ Assert.equal "foo LIKE bar" (formatSql "foo LIKE bar" 2)

testSelects :: forall a. Free (TestF a) Unit
testSelects = do
  test "formatting of 'SELECT'" $ Assert.equal "SELECT foo bar" (formatSql "SELECT foo bar" 2)
  test "formatting of ' SELECT'" $ Assert.equal "SELECT foo bar" (formatSql " SELECT foo bar" 2)
  test "formatting of '(SELECT'" $ Assert.equal "foo\n  (SELECT bar" (formatSql "foo (SELECT bar" 2)
  test "formatting of '( SELECT'" $ Assert.equal "foo\n  (SELECT bar" (formatSql "foo ( SELECT bar" 2)
  test "formatting of ') SELECT'" $ Assert.equal "foo)\nSELECT bar" (formatSql "foo) SELECT bar" 2)
  test "formatting of ')SELECT'" $ Assert.equal "foo)\nSELECT bar" (formatSql "foo)SELECT bar" 2)
  test "formatting when selecting multiple fields" $ Assert.equal "SELECT foo,\n    bar,\n    baz" (formatSql "SELECT foo, bar, baz" 2)

testUpdates :: forall a. Free (TestF a) Unit
testUpdates = do
  test "formatting of 'UPDATE'" $ Assert.equal "UPDATE foo bar" (formatSql "UPDATE foo bar" 2)
  test "formatting of ' UPDATE'" $ Assert.equal "UPDATE foo bar" (formatSql " UPDATE foo bar" 2)

testDeletes :: forall a. Free (TestF a) Unit
testDeletes = do
  test "formatting of 'DELETE'" $ Assert.equal "DELETE foo bar" (formatSql "DELETE foo bar" 2)
  test "formatting of ' DELETE'" $ Assert.equal "DELETE foo bar" (formatSql " DELETE foo bar" 2)

testUpcasedKeywords :: forall a. Free (TestF a) Unit
testUpcasedKeywords = do
  test "upcasing of 'AND'" $ Assert.equal "AND" (trim (formatSql (" and ") 2))
  test "upcasing of 'BETWEEN'" $ Assert.equal "BETWEEN" (trim (formatSql (" between ") 2))
  test "upcasing of 'CASE'" $ Assert.equal "CASE" (trim (formatSql (" case ") 2))
  test "upcasing of 'ELSE'" $ Assert.equal "ELSE" (trim (formatSql (" else ") 2))
  test "upcasing of 'END'" $ Assert.equal "END" (trim (formatSql (" end ") 2))
  test "upcasing of 'ON'" $ Assert.equal "ON" (trim (formatSql (" on ") 2))
  test "upcasing of 'OR'" $ Assert.equal "OR" (trim (formatSql (" or ") 2))
  test "upcasing of 'OVER'" $ Assert.equal "OVER" (trim (formatSql (" over ") 2))
  test "upcasing of 'WHEN'" $ Assert.equal "WHEN" (trim (formatSql (" when ") 2))
  test "upcasing of 'FROM'" $ Assert.equal "FROM" (trim (formatSql (" from ") 2))
  test "upcasing of 'GROUP BY'" $ Assert.equal "GROUP BY" (trim (formatSql (" group by ") 2))
  test "upcasing of 'HAVING'" $ Assert.equal "HAVING" (trim (formatSql (" having ") 2))
  test "upcasing of 'JOIN'" $ Assert.equal "JOIN" (trim (formatSql (" join ") 2))
  test "upcasing of 'CROSS JOIN'" $ Assert.equal "CROSS JOIN" (trim (formatSql (" cross join ") 2))
  test "upcasing of 'INNER JOIN'" $ Assert.equal "INNER JOIN" (trim (formatSql (" inner join ") 2))
  test "upcasing of 'LEFT JOIN'" $ Assert.equal "LEFT JOIN" (trim (formatSql (" left join ") 2))
  test "upcasing of 'RIGHT JOIN'" $ Assert.equal "RIGHT JOIN" (trim (formatSql (" right join ") 2))
  test "upcasing of 'ORDER BY'" $ Assert.equal "ORDER BY" (trim (formatSql (" order by ") 2))
  test "upcasing of 'WHERE'" $ Assert.equal "WHERE" (trim (formatSql (" where ") 2))
  test "upcasing of 'WITH'" $ Assert.equal "WITH" (trim (formatSql (" with ") 2))
  test "upcasing of 'SET'" $ Assert.equal "SET" (trim (formatSql (" set ") 2))
  test "upcasing of 'IN'" $ Assert.equal "IN" (trim (formatSql (" in ") 2))
  test "upcasing of 'ALL'" $ Assert.equal "ALL" (trim (formatSql (" all ") 2))
  test "upcasing of 'AS'" $ Assert.equal "AS" (trim (formatSql (" as ") 2))
  test "upcasing of 'ASC'" $ Assert.equal "ASC" (trim (formatSql (" asc ") 2))
  test "upcasing of 'DESC'" $ Assert.equal "DESC" (trim (formatSql (" desc ") 2))
  test "upcasing of 'DISTINCT'" $ Assert.equal "DISTINCT" (trim (formatSql (" distinct ") 2))
  test "upcasing of 'EXISTS'" $ Assert.equal "EXISTS" (trim (formatSql (" exists ") 2))
  test "upcasing of 'NOT'" $ Assert.equal "NOT" (trim (formatSql (" not ") 2))
  test "upcasing of 'NULL'" $ Assert.equal "NULL" (trim (formatSql (" null ") 2))
  test "upcasing of 'LIKE'" $ Assert.equal "LIKE" (trim (formatSql (" like ") 2))

testFullQueries :: forall a. Int -> Free (TestF a) Unit
testFullQueries numSpaces = do
  let tab = fromCharArray $ replicate numSpaces ' '
  test "formatting a full SELECT query"
    $ Assert.equal
        ("SELECT a.b,\n" <> tab <> tab <> "c.d\nFROM a\nJOIN b\n" <> tab <> "ON a.b = c.d\nWHERE a.b = 1\n" <> tab <> "AND c.d = 1")
        (formatSql "SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1" numSpaces)
  test "formatting a full UPDATE query"
    $ Assert.equal
        ("UPDATE a\nSET a.b = 1,\n" <> tab <> tab <> "a.c = 2\nWHERE a.d = 3")
        (formatSql "UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3" numSpaces)
  test "formatting a full DELETE query"
    $ Assert.equal
        ("DELETE\nFROM a\nWHERE a.b = 1\n" <> tab <> "AND a.c = 2")
        (formatSql "DELETE FROM a WHERE a.b = 1 AND a.c = 2" numSpaces)

main :: forall a. Free (TestF a) Unit
main = suite "SQLFormatter" do
  suite "format" do
    suite "tabbed keywords" testTabbedKeywords
    suite "untabbed keywords" testUntabbedKeywords
    suite "unchanged keywords" testUnchangedKeywords
    suite "SELECTs" testSelects
    suite "UPDATEs" testUpdates
    suite "DELETEs" testDeletes
    suite "special case keywords" do
      test "formatting of 'THEN'" $ Assert.equal "foo THEN\n  bar" (formatSql "foo THEN bar" 2)
      test "formatting of 'UNION'" $ Assert.equal "foo\nUNION\nbar" (formatSql "foo UNION bar" 2)
      test "formatting of 'USING'" $ Assert.equal "foo\nUSING bar" (formatSql "foo USING bar" 2)
    suite "nested queries" do
      test "formatting of single nested query"
        $ Assert.equal "SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)"
                       (formatSql "SELECT foo FROM (SELECT bar FROM baz)" 2)
      test "formatting of multiple nested queries"
        $ Assert.equal "SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))"
                       (formatSql "SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))" 2)
    suite "case transformations" testUpcasedKeywords
    suite "formatting full queries" $ testFullQueries 2
    suite "formatting queries with a different number of spaces" $ testFullQueries 4
