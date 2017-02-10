module SQLFormatter exposing (format)

import Array.Hamt as Array
import Regex exposing (regex, caseInsensitive)


sep : String
sep =
    "~::~"


createShiftArr : String -> List String
createShiftArr space =
    List.map (\i -> "\n" ++ String.repeat i space) (List.range 0 99)


regexReplace : String -> String -> String -> String
regexReplace pattern replacement str =
    Regex.replace Regex.All (caseInsensitive (regex pattern)) (\_ -> replacement) str


subqueryLevel : String -> Int -> Int
subqueryLevel str level =
    level - (String.length (regexReplace "\\(" "" str) - String.length (regexReplace "\\)" "" str))


allReplacements : String -> List ( String, String )
allReplacements tab =
    [ ( " AND ", (sep ++ tab ++ "AND ") )
    , ( " BETWEEN ", (sep ++ tab ++ "BETWEEN ") )
    , ( " CASE ", (sep ++ tab ++ "CASE ") )
    , ( " ELSE ", (sep ++ tab ++ "ELSE ") )
    , ( " END ", (sep ++ tab ++ "END ") )
    , ( " FROM ", (sep ++ "FROM ") )
    , ( " GROUP\\s+BY", (sep ++ "GROUP BY ") )
    , ( " HAVING ", (sep ++ "HAVING ") )
    , ( " IN ", (" IN ") )
    , ( " JOIN ", (sep ++ "JOIN ") )
    , ( (" CROSS(" ++ sep ++ ")+JOIN "), (sep ++ "CROSS JOIN ") )
    , ( (" INNER(" ++ sep ++ ")+JOIN "), (sep ++ "INNER JOIN ") )
    , ( (" LEFT(" ++ sep ++ ")+JOIN "), (sep ++ "LEFT JOIN ") )
    , ( (" RIGHT(" ++ sep ++ ")+JOIN "), (sep ++ "RIGHT JOIN ") )
    , ( " ON ", (sep ++ tab ++ "ON ") )
    , ( " OR ", (sep ++ tab ++ "OR ") )
    , ( " ORDER\\s+BY", (sep ++ "ORDER BY ") )
    , ( " OVER ", (sep ++ tab ++ "OVER ") )
    , ( "\\(\\s*SELECT ", (sep ++ "(SELECT ") )
    , ( "\\)\\s*SELECT ", (")" ++ sep ++ "SELECT ") )
    , ( " THEN ", ("THEN" ++ sep ++ tab) )
    , ( " UNION ", (sep ++ "UNION" ++ sep) )
    , ( " USING ", (sep ++ "USING ") )
    , ( " WHEN ", (sep ++ tab ++ "WHEN ") )
    , ( " WHERE ", (sep ++ "WHERE ") )
    , ( " WITH ", (sep ++ "WITH ") )
    , ( " ALL ", (" ALL ") )
    , ( " AS ", (" AS ") )
    , ( " ASC ", (" ASC ") )
    , ( " DESC ", (" DESC ") )
    , ( " DISTINCT ", (" DISTINCT ") )
    , ( " EXISTS ", (" EXISTS ") )
    , ( " NOT ", (" NOT ") )
    , ( " NULL ", (" NULL ") )
    , ( " LIKE ", (" LIKE ") )
    , ( "\\s*SELECT ", ("SELECT ") )
    , ( "\\s*UPDATE ", ("UPDATE ") )
    , ( " SET ", (" SET ") )
    , ( ("(" ++ sep ++ ")+"), (sep) )
    ]


splitSql : String -> String -> List String
splitSql str tab =
    let
        input =
            regexReplace "\\s+" " " str
    in
        List.foldr (\t acc -> regexReplace (Tuple.first t) (Tuple.second t) acc) input (allReplacements tab)
            |> String.split sep


splitIfEven : Int -> String -> String -> List String
splitIfEven i str tab =
    if i % 2 == 0 then
        splitSql str tab
    else
        [ str ]


getOrDefault : Int -> List String -> String
getOrDefault idx list =
    Maybe.withDefault "" (Array.get idx (Array.fromList list))


type alias Out =
    { str : String
    , shiftArr : List String
    , tab : String
    , arr : List String
    , parensLevel : Int
    , deep : Int
    }


genOutput : Int -> Int -> Out -> Out
genOutput idx max input =
    let
        originalEl =
            getOrDefault idx input.arr

        outParensLevel =
            subqueryLevel originalEl input.parensLevel

        outArr =
            case Regex.contains (regex "SELECT|SET") originalEl of
                True ->
                    input.arr
                        |> Array.fromList
                        |> Array.set idx (regexReplace "\\," (",\n" ++ (String.repeat 2 input.tab)) originalEl)
                        |> Array.toList

                False ->
                    input.arr

        el =
            getOrDefault idx outArr

        ( outStr, outDeep ) =
            case Regex.contains (regex "\\(\\s*SELECT") el of
                True ->
                    ( input.str ++ (getOrDefault (input.deep + 1) input.shiftArr) ++ el
                    , input.deep + 1
                    )

                False ->
                    ( case Regex.contains (regex "'") el of
                        True ->
                            input.str ++ el

                        False ->
                            input.str ++ (getOrDefault input.deep input.shiftArr) ++ el
                    , case outParensLevel < 1 && input.deep /= 0 of
                        True ->
                            input.deep - 1

                        False ->
                            input.deep
                    )

        out =
            { str = outStr
            , shiftArr = input.shiftArr
            , tab = input.tab
            , arr = outArr
            , parensLevel = outParensLevel
            , deep = outDeep
            }
    in
        case idx < max of
            True ->
                genOutput (idx + 1) max out

            False ->
                out


format : String -> Int -> String
format sql numSpaces =
    let
        tab =
            String.repeat numSpaces " "

        inShiftArr =
            createShiftArr tab

        splitByQuotes =
            sql
                |> regexReplace "\\s+" " "
                |> regexReplace "'" (sep ++ "'")
                |> String.split sep

        splitLen =
            List.length splitByQuotes

        inArr =
            List.concatMap (\i -> splitIfEven i (getOrDefault i splitByQuotes) tab) (List.range 0 (splitLen - 1))

        len =
            List.length inArr

        input =
            { str = ""
            , shiftArr = inShiftArr
            , tab = tab
            , arr = inArr
            , parensLevel = 0
            , deep = 0
            }
    in
        (genOutput 0 len input).str
            |> regexReplace "\\n+" "\n"
            |> String.trim
