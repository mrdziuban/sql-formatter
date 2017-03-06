module SQLFormatter exposing (format)

import Array.Hamt as Array
import Regex exposing (regex, caseInsensitive)

sep: String
sep = "~::~"

getOrDefault: Int -> List String -> String
getOrDefault idx list =
  Maybe.withDefault "" (Array.get idx (Array.fromList list))

createShiftArr: String -> List String
createShiftArr space =
  List.map (\i -> "\n" ++ String.repeat i space) (List.range 0 99)

regexReplaceFn: String -> (Regex.Match -> String) -> String -> String
regexReplaceFn pattern replacementFn str =
  Regex.replace Regex.All (caseInsensitive (regex pattern)) replacementFn str

regexReplace: String -> String -> String -> String
regexReplace pattern replacement str =
  regexReplaceFn pattern (\_ -> replacement) str

subqueryLevel: String -> Int -> Int
subqueryLevel str level =
  level - (String.length (regexReplace "\\(" "" str) - String.length (regexReplace "\\)" "" str))

extractJoin: Regex.Match -> String
extractJoin {submatches} =
  sep ++ (String.toUpper (getOrDefault 0 (List.map (Maybe.withDefault "") submatches))) ++ "JOIN "

allReplacements: String -> List (String, Regex.Match -> String)
allReplacements tab =
  [
    (" AND "                        , (\_ -> (sep ++ tab ++ "AND ")))
  , (" BETWEEN "                    , (\_ -> (sep ++ tab ++ "BETWEEN ")))
  , (" CASE "                       , (\_ -> (sep ++ tab ++ "CASE ")))
  , (" ELSE "                       , (\_ -> (sep ++ tab ++ "ELSE ")))
  , (" END "                        , (\_ -> (sep ++ tab ++ "END ")))
  , (" FROM "                       , (\_ -> (sep ++ "FROM ")))
  , (" GROUP\\s+BY "                , (\_ -> (sep ++ "GROUP BY ")))
  , (" HAVING "                     , (\_ -> (sep ++ "HAVING ")))
  , (" IN "                         , (\_ -> (" IN ")))
  , (" ((CROSS|INNER|LEFT|RIGHT) )?JOIN ", extractJoin)
  , (" ON "                         , (\_ -> (sep ++ tab ++ "ON ")))
  , (" OR "                         , (\_ -> (sep ++ tab ++ "OR ")))
  , (" ORDER\\s+BY "                , (\_ -> (sep ++ "ORDER BY ")))
  , (" OVER "                       , (\_ -> (sep ++ tab ++ "OVER ")))
  , ("\\(\\s*SELECT "               , (\_ -> (sep ++ "(SELECT ")))
  , ("\\)\\s*SELECT "               , (\_ -> (")" ++ sep ++ "SELECT ")))
  , (" THEN "                       , (\_ -> (" THEN" ++ sep ++ tab)))
  , (" UNION "                      , (\_ -> (sep ++ "UNION" ++ sep)))
  , (" USING "                      , (\_ -> (sep ++ "USING ")))
  , (" WHEN "                       , (\_ -> (sep ++ tab ++ "WHEN ")))
  , (" WHERE "                      , (\_ -> (sep ++ "WHERE ")))
  , (" WITH "                       , (\_ -> (sep ++ "WITH ")))
  , (" SET "                        , (\_ -> (sep ++ "SET ")))
  , (" ALL "                        , (\_ -> (" ALL ")))
  , (" AS "                         , (\_ -> (" AS ")))
  , (" ASC "                        , (\_ -> (" ASC ")))
  , (" DESC "                       , (\_ -> (" DESC ")))
  , (" DISTINCT "                   , (\_ -> (" DISTINCT ")))
  , (" EXISTS "                     , (\_ -> (" EXISTS ")))
  , (" NOT "                        , (\_ -> (" NOT ")))
  , (" NULL "                       , (\_ -> (" NULL ")))
  , (" LIKE "                       , (\_ -> (" LIKE ")))
  , ("\\s*SELECT "                  , (\_ -> ("SELECT ")))
  , ("\\s*UPDATE "                  , (\_ -> ("UPDATE ")))
  , ("\\s*DELETE "                  , (\_ -> ("DELETE ")))
  , (("(" ++ sep ++ ")+")           , (\_ -> (sep)))
  ]

splitSql: String -> String -> List String
splitSql str tab =
  let
    input = regexReplace "\\s+" " " str
  in
    List.foldr (\t acc -> regexReplaceFn (Tuple.first t) (Tuple.second t) acc) input (allReplacements tab)
      |> String.split sep

splitIfEven: Int -> String -> String -> List String
splitIfEven i str tab =
  if i % 2 == 0 then splitSql str tab else [ str ]

type alias Out =
  {
    str: String
  , shiftArr: List String
  , tab: String
  , arr: List String
  , parensLevel: Int
  , deep: Int }

genOutput: Int -> Int -> Out -> Out
genOutput idx max input =
  let
    originalEl = getOrDefault idx input.arr
    outParensLevel = subqueryLevel originalEl input.parensLevel
    outArr =
      case Regex.contains (regex "SELECT|SET") originalEl of
        True ->
          input.arr
            |> Array.fromList
            |> Array.set idx (regexReplace "\\,\\s+" (",\n" ++ input.tab ++ input.tab) originalEl)
            |> Array.toList
        False -> input.arr
    el = getOrDefault idx outArr
    (outStr, outDeep) =
      case Regex.contains (regex "\\(\\s*SELECT") el of
        True ->
          (
            input.str ++ (getOrDefault (input.deep + 1) input.shiftArr) ++ el
          , input.deep + 1
          )
        False ->
          (
            case Regex.contains (regex "'") el of
              True -> input.str ++ el
              False -> input.str ++ (getOrDefault input.deep input.shiftArr) ++ el
          , case outParensLevel < 1 && input.deep /= 0 of
              True -> input.deep - 1
              False -> input.deep
          )
    out =
      {
        str = outStr
      , shiftArr = input.shiftArr
      , tab = input.tab
      , arr = outArr
      , parensLevel = outParensLevel
      , deep = outDeep }
  in
    case idx < max of
      True -> genOutput (idx + 1) max out
      False -> out

format: String -> Int -> String
format sql numSpaces =
  let
    tab = String.repeat numSpaces " "
    inShiftArr = createShiftArr tab
    splitByQuotes =
      sql
        |> regexReplace "\\s+" " "
        |> regexReplace "'" (sep ++ "'")
        |> String.split sep
    splitLen = List.length splitByQuotes
    inArr = List.concatMap (\i -> splitIfEven i (getOrDefault i splitByQuotes) tab) (List.range 0 (splitLen - 1))
    len = List.length inArr
    input =
      {
        str = ""
      , shiftArr = inShiftArr
      , tab = tab
      , arr = inArr
      , parensLevel = 0
      , deep = 0 }
  in
    (genOutput 0 len input).str
      |> regexReplace "\\s+\\n" "\n"
      |> regexReplace "\\n+" "\n"
      |> String.trim
