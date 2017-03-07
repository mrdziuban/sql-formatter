module SQLFormatter

open System
open System.Text.RegularExpressions

type T = { str: string; shiftArr: string[]; tab: string; arr: string[]; parensLevel: int; deep: int }

let sep = "~::~"

let createShiftArr tab =
  Array.map (fun i -> "\n" + (String.replicate i tab)) [|0..99|]

let subqueryLevel (str: string) level =
  level - (str.Replace("(", "").Length - str.Replace(")", "").Length)

let allReplacements tab: (Regex * string)[] =
  [|
    (new Regex(" AND ", RegexOptions.IgnoreCase),                     sep + tab + "AND ");
    (new Regex(" BETWEEN ", RegexOptions.IgnoreCase),                 sep + tab + "BETWEEN ");
    (new Regex(" CASE ", RegexOptions.IgnoreCase),                    sep + tab + "CASE ");
    (new Regex(" ELSE ", RegexOptions.IgnoreCase),                    sep + tab + "ELSE ");
    (new Regex(" END ", RegexOptions.IgnoreCase),                     sep + tab + "END ");
    (new Regex(" FROM ", RegexOptions.IgnoreCase),                    sep + "FROM ");
    (new Regex(" GROUP\\s+BY ", RegexOptions.IgnoreCase),             sep + "GROUP BY ");
    (new Regex(" HAVING ", RegexOptions.IgnoreCase),                  sep + "HAVING ");
    (new Regex(" IN ", RegexOptions.IgnoreCase),                      " IN ");
    (new Regex(" JOIN ", RegexOptions.IgnoreCase),                    sep + "JOIN ");
    (new Regex(" CROSS(" + sep + ")+JOIN ", RegexOptions.IgnoreCase), sep + "CROSS JOIN ");
    (new Regex(" INNER(" + sep + ")+JOIN ", RegexOptions.IgnoreCase), sep + "INNER JOIN ");
    (new Regex(" LEFT(" + sep + ")+JOIN ", RegexOptions.IgnoreCase),  sep + "LEFT JOIN ");
    (new Regex(" RIGHT(" + sep + ")+JOIN ", RegexOptions.IgnoreCase), sep + "RIGHT JOIN ");
    (new Regex(" ON ", RegexOptions.IgnoreCase),                      sep + tab + "ON ");
    (new Regex(" OR ", RegexOptions.IgnoreCase),                      sep + tab + "OR ");
    (new Regex(" ORDER\s+BY ", RegexOptions.IgnoreCase),              sep + "ORDER BY ");
    (new Regex(" OVER ", RegexOptions.IgnoreCase),                    sep + tab + "OVER ");
    (new Regex("\\(\\s*SELECT ", RegexOptions.IgnoreCase),            sep + "(SELECT ");
    (new Regex("\\)\\s*SELECT ", RegexOptions.IgnoreCase),            ")" + sep + "SELECT ");
    (new Regex(" THEN ", RegexOptions.IgnoreCase),                    " THEN" + sep + tab);
    (new Regex(" UNION ", RegexOptions.IgnoreCase),                   sep + "UNION" + sep);
    (new Regex(" USING ", RegexOptions.IgnoreCase),                   sep + "USING ");
    (new Regex(" WHEN ", RegexOptions.IgnoreCase),                    sep + tab + "WHEN ");
    (new Regex(" WHERE ", RegexOptions.IgnoreCase),                   sep + "WHERE ");
    (new Regex(" WITH ", RegexOptions.IgnoreCase),                    sep + "WITH ");
    (new Regex(" SET ", RegexOptions.IgnoreCase),                     sep + "SET ");
    (new Regex(" ALL ", RegexOptions.IgnoreCase),                     " ALL ");
    (new Regex(" AS ", RegexOptions.IgnoreCase),                      " AS ");
    (new Regex(" ASC ", RegexOptions.IgnoreCase),                     " ASC ");
    (new Regex(" DESC ", RegexOptions.IgnoreCase),                    " DESC ");
    (new Regex(" DISTINCT ", RegexOptions.IgnoreCase),                " DISTINCT ");
    (new Regex(" EXISTS ", RegexOptions.IgnoreCase),                  " EXISTS ");
    (new Regex(" NOT ", RegexOptions.IgnoreCase),                     " NOT ");
    (new Regex(" NULL ", RegexOptions.IgnoreCase),                    " NULL ");
    (new Regex(" LIKE ", RegexOptions.IgnoreCase),                    " LIKE ");
    (new Regex("\\s*SELECT ", RegexOptions.IgnoreCase),               "SELECT ");
    (new Regex("\\s*UPDATE ", RegexOptions.IgnoreCase),               "UPDATE ");
    (new Regex("\\s*DELETE ", RegexOptions.IgnoreCase),               "DELETE ");
    (new Regex("(" + sep + ")+", RegexOptions.IgnoreCase),            sep);
  |]

let splitSql str tab =
  tab
  |> allReplacements
  |> Array.fold (fun acc ((p: Regex, r: string)) -> p.Replace(acc, r)) ((new Regex("\\s+")).Replace(str, " "))
  |> (fun s -> s.Split([|sep|], StringSplitOptions.None))

let splitIfEven i str tab =
  if i % 2 = 0 then splitSql str tab else [|str|]

let updateOutput el parensLevel acc i =
  if Regex.IsMatch(el, "\\(\\s*SELECT") then
    (acc.str + acc.shiftArr.[acc.deep + 1] + el, acc.deep + 1)
  else
    (
      (if el.Contains("'") then acc.str + el else acc.str + acc.shiftArr.[acc.deep] + el),
      (if parensLevel < 1 && acc.deep <> 0 then acc.deep - 1 else acc.deep)
    )

let genOutput (acc: T) i: T =
  let originalEl = acc.arr.[i]
  let parensLevel = subqueryLevel originalEl acc.parensLevel
  let arr = acc.arr
  if Regex.IsMatch(originalEl, "SELECT|SET") then
    Array.set arr i ((new Regex(",\\s+")).Replace(originalEl, ",\n" + acc.tab + acc.tab))
  let el = arr.[i]
  let (str, deep) = updateOutput el parensLevel acc i
  { acc with str = str; arr = arr; parensLevel = parensLevel; deep = deep }

let format sql numSpaces =
  let tab = String.replicate numSpaces " "
  let splitByQuotes = sql
                      |> (fun s -> (new Regex("\\s+")).Replace(s, " "))
                      |> (fun s -> s.Replace("'", sep + "'"))
                      |> (fun s -> s.Split([|sep|], StringSplitOptions.None))
  let input = {
    str = "";
    shiftArr = (createShiftArr tab);
    tab = tab;
    arr = (Array.collect (fun i -> splitIfEven i splitByQuotes.[i] tab) [|0..(splitByQuotes.Length - 1)|]);
    parensLevel = 0;
    deep = 0
  }

  let output = Array.fold genOutput input [|0..(input.arr.Length - 1)|]
  output.str
  |> (fun s -> (new Regex("\\s+\\n")).Replace(s, "\n"))
  |> (fun s -> (new Regex("\\n+")).Replace(s, "\n"))
  |> (fun s -> s.Trim())
