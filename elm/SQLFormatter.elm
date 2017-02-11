module SQLFormatter exposing (format)

import Array.Hamt as Array
import Regex exposing (caseInsensitive, regex)


sep : String
sep =
    "~::~"


createShiftArr : String -> List String
createShiftArr space =
    List.map (\i -> "\n" ++ String.repeat i space) (List.range 0 99)


regexReplace : String -> String -> String -> String
regexReplace rx replacement str =
    Regex.replace Regex.All (caseInsensitive (regex rx)) (\_ -> replacement) str


subqueryLevel : String -> Int -> Int
subqueryLevel str level =
    let
        t =
            ( (regexReplace "\\(" "" str), (regexReplace "\\)" "" str) )
    in
        level - (String.length (Tuple.first t) - String.length (Tuple.second t))


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


performReplacement : ( String, String ) -> String -> String
performReplacement tup str =
    regexReplace (Tuple.first tup) (Tuple.second tup) str


splitSql : String -> String -> List String
splitSql str tab =
    let
        input =
            regexReplace "\\s+" " " str
    in
        List.foldr performReplacement input (allReplacements tab)
            |> String.split sep


splitIfEven : Int -> String -> String -> List String
splitIfEven i str tab =
    if i % 2 == 0 then
        splitSql str tab
    else
        [ str ]


getOrElse : Int -> List String -> String
getOrElse idx list =
    Maybe.withDefault "" (Array.get idx (Array.fromList list))


type alias Out =
    { str : String
    , shifts : List String
    , tab : String
    , arr : List String
    , parensLevel : Int
    , deep : Int
    }


replaceEl : Int -> String -> String -> Array.Array String -> Array.Array String
replaceEl idx tab str arr =
    Array.set idx (regexReplace "\\," (",\n" ++ (String.repeat 2 tab)) str) arr


genOutput : Int -> Int -> Out -> Out
genOutput idx max input =
    let
        originalEl =
            getOrElse idx input.arr

        outParensLevel =
            subqueryLevel originalEl input.parensLevel

        outArr =
            case Regex.contains (regex "SELECT|SET") originalEl of
                True ->
                    input.arr
                        |> Array.fromList
                        |> replaceEl idx input.tab originalEl
                        |> Array.toList

                False ->
                    input.arr

        el =
            getOrElse idx outArr

        ( outStr, outDeep ) =
            if Regex.contains (regex "\\(\\s*SELECT") el then
                ( input.str ++ (getOrElse (input.deep + 1) input.shifts) ++ el
                , input.deep + 1
                )
            else
                ( (if Regex.contains (regex "'") el then
                    input.str ++ el
                   else
                    input.str ++ (getOrElse input.deep input.shifts) ++ el
                  )
                , (if outParensLevel < 1 && input.deep /= 0 then
                    input.deep - 1
                   else
                    input.deep
                  )
                )

        out =
            { str = outStr
            , shifts = input.shifts
            , tab = input.tab
            , arr = outArr
            , parensLevel = outParensLevel
            , deep = outDeep
            }
    in
        if idx < max then
            genOutput (idx + 1) max out
        else
            out


genPart : String -> List String -> Int -> List String
genPart tab parts idx =
    splitIfEven idx (getOrElse idx parts) tab


format : String -> Int -> String
format sql numSpaces =
    let
        tab =
            String.repeat numSpaces " "

        inShiftArr =
            createShiftArr tab

        parts =
            sql
                |> regexReplace "\\s+" " "
                |> regexReplace "'" (sep ++ "'")
                |> String.split sep

        splitLen =
            List.length parts

        inArr =
            List.concatMap (genPart tab parts) (List.range 0 (splitLen - 1))

        len =
            List.length inArr

        input =
            { str = ""
            , shifts = inShiftArr
            , tab = tab
            , arr = inArr
            , parensLevel = 0
            , deep = 0
            }
    in
        (genOutput 0 len input).str
            |> regexReplace "\\n+" "\n"
            |> String.trim
