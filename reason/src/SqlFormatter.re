let sep = "~::~";

let rec range = (start: int, end_: int) => start > end_ ? [] : [start, ...range(start + 1, end_)];

let createShiftArr = (space: string) => Array.map(i => "\n" ++ Js.String.repeat(i, space), Array.of_list(range(0, 99)));

let regexReplace = (pattern: Js.Re.t, replacement: string, str: string) =>
Js.String.replaceByRe(pattern, replacement, str);

let subqueryLevel = (str: string, level: int) =>
  level - (String.length(regexReplace([%bs.re "/\\(/g"], "", str)) - String.length(regexReplace([%bs.re "/\\)/g"], "", str)));

let allReplacements = tab => [
  ([%bs.re "/ AND /gi"],                              _ => sep ++ tab ++ "AND "),
  ([%bs.re "/ BETWEEN /gi"],                          _ => sep ++ tab ++ "BETWEEN "),
  ([%bs.re "/ CASE /gi"],                             _ => sep ++ tab ++ "CASE "),
  ([%bs.re "/ ELSE /gi"],                             _ => sep ++ tab ++ "ELSE "),
  ([%bs.re "/ END /gi"],                              _ => sep ++ tab ++ "END "),
  ([%bs.re "/ FROM /gi"],                             _ => sep ++ "FROM "),
  ([%bs.re "/ GROUP\\s+BY /gi"],                      _ => sep ++ "GROUP BY "),
  ([%bs.re "/ HAVING /gi"],                           _ => sep ++ "HAVING "),
  ([%bs.re "/ IN /gi"],                               _ => " IN "),
  ([%bs.re "/ ((CROSS|INNER|LEFT|RIGHT) )?JOIN /gi"], m =>
    switch (Js.Re.captures(m) |> a => Array.get(a, 1) |> Js.Nullable.toOption) {
    | None => sep ++ "JOIN ";
    | Some(t) => sep ++ String.uppercase(t) ++ "JOIN ";
    }
  ),
  ([%bs.re "/ ON /gi"],                               _ => sep ++ tab ++ "ON "),
  ([%bs.re "/ OR /gi"],                               _ => sep ++ tab ++ "OR "),
  ([%bs.re "/ ORDER\\s+BY /gi"],                      _ => sep ++ "ORDER BY "),
  ([%bs.re "/ OVER /gi"],                             _ => sep ++ tab ++ "OVER "),
  ([%bs.re "/\\(\\s*SELECT /gi"],                     _ => sep ++ "(SELECT "),
  ([%bs.re "/\\)\\s*SELECT /gi"],                     _ => ")" ++ sep ++ "SELECT "),
  ([%bs.re "/ THEN /gi"],                             _ => " THEN" ++ sep ++ tab),
  ([%bs.re "/ UNION /gi"],                            _ => sep ++ "UNION" ++ sep),
  ([%bs.re "/ USING /gi"],                            _ => sep ++ "USING "),
  ([%bs.re "/ WHEN /gi"],                             _ => sep ++ tab ++ "WHEN "),
  ([%bs.re "/ WHERE /gi"],                            _ => sep ++ "WHERE "),
  ([%bs.re "/ WITH /gi"],                             _ => sep ++ "WITH "),
  ([%bs.re "/ SET /gi"],                              _ => sep ++ "SET "),
  ([%bs.re "/ ALL /gi"],                              _ => " ALL "),
  ([%bs.re "/ AS /gi"],                               _ => " AS "),
  ([%bs.re "/ ASC /gi"],                              _ => " ASC "),
  ([%bs.re "/ DESC /gi"],                             _ => " DESC "),
  ([%bs.re "/ DISTINCT /gi"],                         _ => " DISTINCT "),
  ([%bs.re "/ EXISTS /gi"],                           _ => " EXISTS "),
  ([%bs.re "/ NOT /gi"],                              _ => " NOT "),
  ([%bs.re "/ NULL /gi"],                             _ => " NULL "),
  ([%bs.re "/ LIKE /gi"],                             _ => " LIKE "),
  ([%bs.re "/\\s*SELECT /gi"],                        _ => "SELECT "),
  ([%bs.re "/\\s*UPDATE /gi"],                        _ => "UPDATE "),
  ([%bs.re "/\\s*DELETE /gi"],                        _ => "DELETE "),
  ([%bs.re "/(~::~)+/g"],                             _ => sep),
];

let splitSql = (str: string, tab: string) => {
  List.fold_left(
    (acc: string, t: (Js.Re.t, Js.Re.result => string)) => switch (Js.Re.exec(acc, fst(t))) {
    | None => acc;
    | Some(res) => regexReplace(fst(t), snd(t)(res), acc);
    },
    regexReplace([%bs.re "/\\s+/g"], " ", str),
    allReplacements(tab))
  |> Js.String.split(sep);
};

let splitIfEven = (i: int, str: string, tab: string) => (i mod 2 == 0) ? splitSql(str, tab) : [|str|]

type out = {
  str: string,
  shiftArr: array(string),
  tab: string,
  arr: array(string),
  parensLevel: int,
  deep: int
};

let updateOutput = (el: string, parensLevel: int, input: out) =>
  Js.Re.test(el, [%bs.re "/\\(\\s*SELECT/"])
    ? (input.str ++ Array.get(input.shiftArr, input.deep + 1) ++ el, input.deep + 1)
    : (
      Js.Re.test(el, [%bs.re "/'/"]) ? input.str ++ el : input.str ++ Array.get(input.shiftArr, input.deep) ++ el,
      (parensLevel < 1 && input.deep != 0) ? input.deep - 1 : input.deep
    );

let format = (sql: string, numSpaces: int) => {
  let tab = String.make(numSpaces, ' ');
  let splitByQuotes = sql
                      |> regexReplace([%bs.re "/\\s+/g"], " ")
                      |> regexReplace([%bs.re "/'/g"], sep ++ "'")
                      |> Js.String.split(sep);
  let input: out = {
    str: "",
    shiftArr: createShiftArr(tab),
    tab: tab,
    arr: Array.concat(List.map(
      i => splitIfEven(i, Array.get(splitByQuotes, i), tab),
      range(0, Array.length(splitByQuotes) - 1))),
    parensLevel: 0,
    deep: 0
  };
  let output: out = Array.fold_left(
    (acc: out, i: int) => {
      let originalEl = Array.get(acc.arr, i);
      let parensLevel = subqueryLevel(originalEl, acc.parensLevel);
      if (Js.Re.test(originalEl, [%bs.re "/SELECT|SET/"])) {
        Array.set(acc.arr, i, regexReplace([%bs.re "/,\\s+/g"], ",\n" ++ input.tab ++ input.tab, originalEl));
      };
      let el = Array.get(acc.arr, i);
      let (str, deep) = updateOutput(el, parensLevel, acc);
      {...input, str, arr: acc.arr, parensLevel, deep};
    },
    input,
    Array.of_list(range(0, Array.length(input.arr) - 1)));
  output.str
  |> regexReplace([%bs.re "/\\s+\\n/g"], "\n")
  |> regexReplace([%bs.re "/\\n+/g"], "\n")
  |> String.trim
};
