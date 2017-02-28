module SQLFormatter (formatSql) where

import Prelude ((<>), (#), (+), (-), (==), (/=), (<), (&&), map, mod)
import Data.Array (concatMap, index, length, range, updateAt)
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.Maybe (fromMaybe)
import Data.String (length, Pattern(Pattern), split, trim) as String
import Data.String.Regex (Regex, regex, replace, test)
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

regexReplace' :: (Either String Regex) -> String -> String -> String
regexReplace' (Right rx) replacement str = replace rx replacement str
regexReplace' (Left _) _ str = str

regexReplace :: String -> String -> String -> String
regexReplace rx replacement str = regexReplace' (regex rx (global <> ignoreCase)) replacement str

regexTest' :: (Either String Regex) -> String -> Boolean
regexTest' (Right rx) str = test rx str
regexTest' (Left _) _ = false

regexTest :: String -> String -> Boolean
regexTest rx str = regexTest' (regex rx ignoreCase) str

allReplacements :: String -> Array (Tuple String String)
allReplacements tab =
  [ Tuple " AND "                              (sep <> tab <> "AND ")
  , Tuple " BETWEEN "                          (sep <> tab <> "BETWEEN ")
  , Tuple " CASE "                             (sep <> tab <> "CASE ")
  , Tuple " ELSE "                             (sep <> tab <> "ELSE ")
  , Tuple " END "                              (sep <> tab <> "END ")
  , Tuple " FROM "                             (sep <> "FROM ")
  , Tuple " GROUP\\s+BY "                      (sep <> "GROUP BY ")
  , Tuple " HAVING "                           (sep <> "HAVING ")
  , Tuple " IN "                               " IN "
  , Tuple " ((CROSS|INNER|LEFT|RIGHT) )?JOIN " " $1JOIN "
  , Tuple " ON "                               (sep <> tab <> "ON ")
  , Tuple " OR "                               (sep <> tab <> "OR ")
  , Tuple " ORDER\\s+BY "                      (sep <> "ORDER BY ")
  , Tuple " OVER "                             (sep <> tab <> "OVER ")
  , Tuple "\\(\\s*SELECT "                     (sep <> "(SELECT ")
  , Tuple "\\)\\s*SELECT "                     (")" <> sep <> "SELECT ")
  , Tuple " THEN "                             (" THEN" <> sep <> tab)
  , Tuple " UNION "                            (sep <> "UNION" <> sep)
  , Tuple " USING "                            (sep <> "USING ")
  , Tuple " WHEN "                             (sep <> tab <> "WHEN ")
  , Tuple " WHERE "                            (sep <> "WHERE ")
  , Tuple " WITH "                             (sep <> "WITH ")
  , Tuple " SET "                              (sep <> "SET ")
  , Tuple " ALL "                              " ALL "
  , Tuple " AS "                               " AS "
  , Tuple " ASC "                              " ASC "
  , Tuple " DESC "                             " DESC "
  , Tuple " DISTINCT "                         " DISTINCT "
  , Tuple " EXISTS "                           " EXISTS "
  , Tuple " NOT "                              " NOT "
  , Tuple " NULL "                             " NULL "
  , Tuple " LIKE "                             " LIKE "
  , Tuple "\\s*SELECT "                        "SELECT "
  , Tuple "\\s*UPDATE "                        "UPDATE "
  , Tuple "\\s*DELETE "                        "DELETE "
  , Tuple ("(" <> sep <> ")+")                 sep
  ]

splitSql :: String -> String -> (Array String)
splitSql str tab =
  allReplacements tab # foldl (\acc t -> regexReplace (fst t) (snd t) acc) (regexReplace "\\s+" " " str)
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
