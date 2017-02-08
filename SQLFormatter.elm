module SQLFormatter exposing (format)

import Array
import List
import Regex exposing (regex, caseInsensitive)
import String

sep: String
sep = "~::~"

createShiftArr: String -> List String
createShiftArr space =
  List.map (\i -> "\n" ++ String.repeat i space) (List.range 0 99)

subqueryLevel: String -> Int -> Int
subqueryLevel str level =
  let
    openLen = String.length (Regex.replace Regex.All (regex "\\(") (\_ -> "") str)
    closeLen = String.length (Regex.replace Regex.All (regex "\\)") (\_ -> "") str)
  in
    level - (openLen - closeLen)

regexReplace: String -> String -> String -> String
regexReplace pattern replacement str =
  Regex.replace Regex.All (caseInsensitive (regex pattern)) (\_ -> replacement) str

splitSql: String -> String -> List String
splitSql str tab =
  str
    |> Regex.replace Regex.All (regex "\\s+") (\_ -> " ")
    |> regexReplace " AND "                         (sep ++ tab ++ tab ++ "AND ")
    |> regexReplace " BETWEEN "                     (sep ++ tab ++ "BETWEEN ")
    |> regexReplace " CASE "                        (sep ++ tab ++ "CASE ")
    |> regexReplace " ELSE "                        (sep ++ tab ++ "ELSE ")
    |> regexReplace " END "                         (sep ++ tab ++ "END ")
    |> regexReplace " FROM "                        (sep ++ "FROM ")
    |> regexReplace " GROUP\\s+BY"                  (sep ++ "GROUP BY ")
    |> regexReplace " HAVING "                      (sep ++ "HAVING ")
    |> regexReplace " IN "                          (" IN ")
    |> regexReplace " JOIN "                        (sep ++ "JOIN ")
    |> regexReplace (" CROSS(" ++ sep ++ ")+JOIN ") (sep ++ "CROSS JOIN ")
    |> regexReplace (" INNER(" ++ sep ++ ")+JOIN ") (sep ++ "INNER JOIN ")
    |> regexReplace (" LEFT(" ++ sep ++ ")+JOIN ")  (sep ++ "LEFT JOIN ")
    |> regexReplace (" RIGHT(" ++ sep ++ ")+JOIN ") (sep ++ "RIGHT JOIN ")
    |> regexReplace " ON "                          (sep ++ tab ++ "ON ")
    |> regexReplace " OR "                          (sep ++ tab ++ tab ++ "OR ")
    |> regexReplace " ORDER\\s+BY"                  (sep ++ "ORDER BY ")
    |> regexReplace " OVER "                        (sep ++ tab ++ "OVER ")
    |> regexReplace "\\(\\s*SELECT "                (sep ++ "(SELECT ")
    |> regexReplace "\\)\\s*SELECT "                (")" ++ sep ++ "SELECT ")
    |> regexReplace " THEN "                        ("THEN" ++ sep ++ tab)
    |> regexReplace " UNION "                       (sep ++ "UNION" ++ sep)
    |> regexReplace " USING "                       (sep ++ "USING ")
    |> regexReplace " WHEN "                        (sep ++ tab ++ "WHEN ")
    |> regexReplace " WHERE "                       (sep ++ "WHERE ")
    |> regexReplace " WITH "                        (sep ++ "WITH ")
    |> regexReplace " ALL "                         (" ALL ")
    |> regexReplace " AS "                          (" AS ")
    |> regexReplace " ASC "                         (" ASC ")
    |> regexReplace " DESC "                        (" DESC ")
    |> regexReplace " DISTINCT "                    (" DISTINCT ")
    |> regexReplace " EXISTS "                      (" EXISTS ")
    |> regexReplace " NOT "                         (" NOT ")
    |> regexReplace " NULL "                        (" NULL ")
    |> regexReplace " LIKE "                        (" LIKE ")
    |> regexReplace "\\s*SELECT "                   ("SELECT ")
    |> regexReplace "\\s*UPDATE "                   ("UPDATE ")
    |> regexReplace " SET "                         (" SET ")
    |> regexReplace ("(" ++ sep ++ ")+")            (sep)
    |> String.split sep

splitIfEven: Int -> String -> String -> List String
splitIfEven i str tab =
  if i % 2 == 0 then splitSql str tab else [ str ]

toA: List a -> Array.Array a
toA l = Array.fromList l

toL: Array.Array a -> List a
toL a = Array.toList a

getOrDefault: Int -> List String -> String
getOrDefault idx list =
  Maybe.withDefault "" (Array.get idx (toA list))

type alias Out =
  {
    str: String
  , shiftArr: List String
  , arr: List String
  , parensLevel: Int
  , deep: Int }

genOutput: Int -> Int -> Out -> Out
genOutput idx max input =
  let
    originalEl = getOrDefault idx input.arr
    outParensLevel = subqueryLevel originalEl input.parensLevel
    outArr =
      if Regex.contains (regex "SELECT|SET") originalEl then
        input.arr
          |> toA
          |> Array.set idx (Regex.replace Regex.All (regex "\\,") (\_ -> ",\n    ") originalEl)
          |> toL
      else
        input.arr
    el = getOrDefault idx outArr
    (outStr, outDeep) =
      if Regex.contains (regex "\\(\\s*SELECT") el then
        (
          input.str ++ (getOrDefault (input.deep + 1) input.shiftArr) ++ el
        , input.deep + 1 )
      else
        (
          if Regex.contains (regex "'") el then input.str ++ el else input.str ++ (getOrDefault input.deep input.shiftArr) ++ el
        , if outParensLevel < 1 && input.deep /= 0 then input.deep - 1 else input.deep
        )
    out =
      {
        str = outStr
      , shiftArr = input.shiftArr
      , arr = outArr
      , parensLevel = outParensLevel
      , deep = outDeep }
  in
    if idx < max then
      genOutput (idx + 1) max out
    else
      out

format: String -> Int -> String
format sql numSpaces =
  let
    tab = String.repeat numSpaces " "
    inShiftArr = createShiftArr tab
    splitByQuotes =
      sql
        |> Regex.replace Regex.All (regex "\\s+") (\_ -> " ")
        |> Regex.replace Regex.All (caseInsensitive (regex "'")) (\_ -> (sep ++ "'"))
        |> String.split sep
    splitLen = List.length splitByQuotes
    inArr = List.concatMap (\i -> splitIfEven i (getOrDefault i splitByQuotes) tab) (List.range 0 (splitLen - 1))
    len = List.length inArr
    input =
      {
        str = ""
      , shiftArr = inShiftArr
      , arr = inArr
      , parensLevel = 0
      , deep = 0 }
  in
    (genOutput 0 len input).str
      |> Regex.replace Regex.All (regex "\\n+") (\_ -> "\n")
      |> String.trim
