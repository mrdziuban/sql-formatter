namespace Test

#r "../../node_modules/fable-core/Fable.Core.dll"

#load "../../fable/src/SQLFormatter.fsx"

open System
open Fable.Core.Testing
open Fable.Import.Node

[<TestFixture>]
module SQLFormatter =
  let tabbedKeywords = [|
    "AND";
    "BETWEEN";
    "CASE";
    "ELSE";
    "END";
    "ON";
    "OR";
    "OVER";
    "WHEN";
  |]

  let untabbedKeywords = [|
    "FROM";
    "GROUP BY";
    "HAVING";
    "JOIN";
    "CROSS JOIN";
    "INNER JOIN";
    "LEFT JOIN";
    "RIGHT JOIN";
    "ORDER BY";
    "WHERE";
    "WITH";
    "SET";
  |]

  let unchangedKeywords = [|
    "IN";
    "ALL";
    "AS";
    "ASC";
    "DESC";
    "DISTINCT";
    "EXISTS";
    "NOT";
    "NULL";
    "LIKE";
  |]

  let assertEqual (expected: 'T) (actual: 'T) =
    Assert.AreEqual(expected, actual)

  let printTest (msg: string) fn =
    ``process``.stdout.write(msg) |> ignore
    fn()
    printfn " \x1b[0;32m✔\x1b[0m"

  [<Test>]
  let formattingOfTabbedKeywords =
    tabbedKeywords
    |> Array.map (fun word ->
      printTest ("formatting of '" + word + "'") (fun () -> assertEqual ("foo\n  " + word + " bar") (SQLFormatter.format ("foo " + word + " bar") 2))
    )

  [<Test>]
  let formattingOfUntabbedKeywords  =
    untabbedKeywords
    |> Array.map (fun word ->
      printTest ("formatting of '" + word + "'") (fun () -> assertEqual ("foo\n" + word + " bar") (SQLFormatter.format ("foo " + word + " bar") 2))
    )

  [<Test>]
  let formattingOfUnchangedKeywords =
    unchangedKeywords
    |> Array.map (fun word ->
      printTest ("formatting of '" + word + "'") (fun () -> assertEqual ("foo " + word + " bar") (SQLFormatter.format ("foo " + word + " bar") 2))
    )

  [<Test>]
  let formattingOfSelects =
    printTest "formatting of 'SELECT'" (fun () -> assertEqual "SELECT foo bar" (SQLFormatter.format "SELECT foo bar" 2))
    printTest "formatting of ' SELECT'" (fun () -> assertEqual "SELECT foo bar" (SQLFormatter.format " SELECT foo bar" 2))
    printTest "formatting of '(SELECT'" (fun () -> assertEqual "foo\n  (SELECT bar" (SQLFormatter.format "foo (SELECT bar" 2))
    printTest "formatting of '( SELECT'" (fun () -> assertEqual "foo\n  (SELECT bar" (SQLFormatter.format "foo ( SELECT bar" 2))
    printTest "formatting of ') SELECT'" (fun () -> assertEqual "foo)\nSELECT bar" (SQLFormatter.format "foo) SELECT bar" 2))
    printTest "formatting of ')SELECT'" (fun () -> assertEqual "foo)\nSELECT bar" (SQLFormatter.format "foo)SELECT bar" 2))
    printTest "formatting when selecting multiple fields" (fun () -> assertEqual "SELECT foo,\n    bar,\n    baz" (SQLFormatter.format "SELECT foo, bar, baz" 2))

  [<Test>]
  let formattingOfUpdates =
    printTest "formatting of 'UPDATE'" (fun () -> assertEqual "UPDATE foo bar" (SQLFormatter.format "UPDATE foo bar" 2))
    printTest "formatting of ' UPDATE'" (fun () -> assertEqual "UPDATE foo bar" (SQLFormatter.format " UPDATE foo bar" 2))

  [<Test>]
  let formattingOfDeletes =
    printTest "formatting of 'DELETE'" (fun () -> assertEqual "DELETE foo bar" (SQLFormatter.format "DELETE foo bar" 2))
    printTest "formatting of ' DELETE'" (fun () -> assertEqual "DELETE foo bar" (SQLFormatter.format " DELETE foo bar" 2))

  let upcasingOfKeywords =
    Array.concat [tabbedKeywords; untabbedKeywords; unchangedKeywords; [|"SELECT"; "UPDATE"; "THEN"; "UNION"; "USING"|]]
    |> Array.map (fun word ->
      printTest ("upcasing of '" + word + "'") (fun () -> assertEqual word (SQLFormatter.format (" " + word.ToLower() + " ") 2))
    )

  let formattingOfFullQueries numSpaces =
    let tab = String.replicate numSpaces " "

    printTest ("formatting a full SELECT query with " + numSpaces.ToString() + " spaces") (fun () ->
      assertEqual ("SELECT a.b,\n" + tab + tab + "c.d\nFROM a\nJOIN b\n" + tab + "ON a.b = c.d\nWHERE a.b = 1\n" + tab + "AND c.d = 1")
                  (SQLFormatter.format "SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1" numSpaces))

    printTest ("formatting a full UPDATE query with " + numSpaces.ToString() + " spaces") (fun () ->
      assertEqual ("UPDATE a\nSET a.b = 1,\n" + tab + tab + "a.c = 2\nWHERE a.d = 3")
                  (SQLFormatter.format "UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3" numSpaces))

    printTest ("formatting a full DELETE query with " + numSpaces.ToString() + " spaces") (fun () ->
      assertEqual ("DELETE\nFROM a\nWHERE a.b = 1\n" + tab + "AND a.c = 2")
                  (SQLFormatter.format "DELETE FROM a WHERE a.b = 1 AND a.c = 2" numSpaces))

  formattingOfFullQueries 2
  formattingOfFullQueries 4
