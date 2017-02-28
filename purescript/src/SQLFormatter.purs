module SQLFormatter (formatSql) where

import Prelude ((<>), (#), ($), (+), (-), (==), (/=), (<), (&&), map, mod, not)
import Data.Array (concatMap, filter, index, length, range, updateAt)
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.Foreign (isUndefined, toForeign)
import Data.Maybe (fromMaybe)
import Data.String (length, Pattern(Pattern), split, toUpper, trim) as String
import Data.String.Regex (Regex, regex, replace', test)
import Data.String.Regex.Flags (global, ignoreCase)
import Data.Tuple (fst, snd, Tuple(..))

type T =
  { str :: String
  , shiftArr :: (Array String)
  , tab :: String
  , arr :: (Array String)
  , parensLevel :: Int
  , deep :: Int
  }

sep :: String
sep = "~::~"

strRepeat :: Int -> String -> String
strRepeat 0 str = ""
strRepeat n str = foldl (\acc _ -> acc <> str) "" (range 1 n)

getOrDefault :: Int -> (Array String) -> String
getOrDefault i list = fromMaybe "" (index list i)

createShiftArr :: String -> (Array String)
createShiftArr tab =
  map (\i -> "\n" <> (strRepeat i tab)) (range 0 99)

regexReplaceFn' :: (Either String Regex) -> (String -> Array String -> String) -> String -> String
regexReplaceFn' (Right rx) replacementFn str = replace' rx replacementFn str
regexReplaceFn' (Left _) _ str = str

regexReplaceFn :: String -> (String -> Array String -> String) -> String -> String
regexReplaceFn rx replacementFn str = regexReplaceFn' (regex rx (global <> ignoreCase)) replacementFn str

regexReplace :: String -> String -> String -> String
regexReplace rx replacement str = regexReplaceFn rx (\_ _ -> replacement) str

regexTest' :: (Either String Regex) -> String -> Boolean
regexTest' (Right rx) str = test rx str
regexTest' (Left _) _ = false

regexTest :: String -> String -> Boolean
regexTest rx str = regexTest' (regex rx ignoreCase) str

allReplacements :: String -> Array (Tuple String (String -> Array String -> String))
allReplacements tab =
  [ Tuple " AND "                              (\_ _ -> sep <> tab <> "AND ")
  , Tuple " BETWEEN "                          (\_ _ -> sep <> tab <> "BETWEEN ")
  , Tuple " CASE "                             (\_ _ -> sep <> tab <> "CASE ")
  , Tuple " ELSE "                             (\_ _ -> sep <> tab <> "ELSE ")
  , Tuple " END "                              (\_ _ -> sep <> tab <> "END ")
  , Tuple " FROM "                             (\_ _ -> sep <> "FROM ")
  , Tuple " GROUP\\s+BY "                      (\_ _ -> sep <> "GROUP BY ")
  , Tuple " HAVING "                           (\_ _ -> sep <> "HAVING ")
  , Tuple " IN "                               (\_ _ -> " IN ")
  , Tuple " ((CROSS|INNER|LEFT|RIGHT) )?JOIN "
          (\_ m -> String.toUpper $ sep <> (getOrDefault 0 (filter (\s -> not (isUndefined (toForeign s))) m)) <> "JOIN ")
  , Tuple " ON "                               (\_ _ -> sep <> tab <> "ON ")
  , Tuple " OR "                               (\_ _ -> sep <> tab <> "OR ")
  , Tuple " ORDER\\s+BY "                      (\_ _ -> sep <> "ORDER BY ")
  , Tuple " OVER "                             (\_ _ -> sep <> tab <> "OVER ")
  , Tuple "\\(\\s*SELECT "                     (\_ _ -> sep <> "(SELECT ")
  , Tuple "\\)\\s*SELECT "                     (\_ _ -> ")" <> sep <> "SELECT ")
  , Tuple " THEN "                             (\_ _ -> " THEN" <> sep <> tab)
  , Tuple " UNION "                            (\_ _ -> sep <> "UNION" <> sep)
  , Tuple " USING "                            (\_ _ -> sep <> "USING ")
  , Tuple " WHEN "                             (\_ _ -> sep <> tab <> "WHEN ")
  , Tuple " WHERE "                            (\_ _ -> sep <> "WHERE ")
  , Tuple " WITH "                             (\_ _ -> sep <> "WITH ")
  , Tuple " SET "                              (\_ _ -> sep <> "SET ")
  , Tuple " ALL "                              (\_ _ -> " ALL ")
  , Tuple " AS "                               (\_ _ -> " AS ")
  , Tuple " ASC "                              (\_ _ -> " ASC ")
  , Tuple " DESC "                             (\_ _ -> " DESC ")
  , Tuple " DISTINCT "                         (\_ _ -> " DISTINCT ")
  , Tuple " EXISTS "                           (\_ _ -> " EXISTS ")
  , Tuple " NOT "                              (\_ _ -> " NOT ")
  , Tuple " NULL "                             (\_ _ -> " NULL ")
  , Tuple " LIKE "                             (\_ _ -> " LIKE ")
  , Tuple "\\s*SELECT "                        (\_ _ -> "SELECT ")
  , Tuple "\\s*UPDATE "                        (\_ _ -> "UPDATE ")
  , Tuple "\\s*DELETE "                        (\_ _ -> "DELETE ")
  , Tuple ("(" <> sep <> ")+")                 (\_ _ -> sep)
  ]

splitSql :: String -> String -> (Array String)
splitSql str tab =
  allReplacements tab # foldl (\acc t -> regexReplaceFn (fst t) (snd t) acc) (regexReplace "\\s+" " " str)
                      # String.split (String.Pattern sep)

splitIfEven :: Int -> String -> String -> (Array String)
splitIfEven i str tab = if i `mod` 2 == 0 then splitSql str tab else [str]

subqueryLevel :: String -> Int -> Int
subqueryLevel str level =
  level - ((String.length (regexReplace "\\(" "" str)) - (String.length (regexReplace "\\)" "" str)))

genOutput :: T -> Int -> T
genOutput acc i = do
  let originalEl = getOrDefault i acc.arr
  let parensLevel = subqueryLevel originalEl acc.parensLevel
  let arr = if regexTest "SELECT|SET" originalEl then
              acc.arr # updateAt i (regexReplace ",\\s+" (",\n" <> acc.tab <> acc.tab) originalEl)
                      # fromMaybe acc.arr
            else
              acc.arr
  let el = getOrDefault i arr
  let t = if regexTest "\\(\\s*SELECT" el then
            Tuple (acc.str <> (getOrDefault (acc.deep + 1) acc.shiftArr) <> el) (acc.deep + 1)
          else
            Tuple
              (if regexTest "'" el then acc.str <> el else acc.str <> (getOrDefault acc.deep acc.shiftArr) <> el)
              (if parensLevel < 1 && acc.deep /= 0 then acc.deep - 1 else acc.deep)
  acc { str = fst t
      , arr = arr
      , parensLevel = parensLevel
      , deep = snd t }

formatSql :: String -> Int -> String
formatSql sql numSpaces = do
  let tab = strRepeat numSpaces " "
  let splitByQuotes = sql # regexReplace "\\s+" " "
                          # regexReplace "'" (sep <> "'")
                          # String.split (String.Pattern sep)
  let input = { str: ""
              , shiftArr: createShiftArr tab
              , tab: tab
              , arr: concatMap (\i -> splitIfEven i (getOrDefault i splitByQuotes) tab) (range 0 ((length splitByQuotes) - 1))
              , parensLevel: 0
              , deep: 0 }
  let output = foldl genOutput input (range 0 ((length input.arr) - 1))
  output.str # regexReplace "\\s+\\n" "\n"
             # regexReplace "\\n+" "\n"
             # String.trim
