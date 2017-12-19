use regex_fns::{regex_match, regex_replace};
use std::iter;

const SEP: &'static str = "~::~";

#[derive(Clone)]
struct T {
    stri: String,
    shift_arr: Vec<String>,
    tab: String,
    arr: Vec<String>,
    parens_level: usize,
    deep: usize,
}

pub fn format(sql: String, num_spaces: i32) -> String {
    let tab: String = iter::repeat(" ").take(num_spaces as usize).collect();
    let split_by_quotes = regex_replace(&sql.replace("'", &format!("{}'", SEP)), r"\s+", " ");
    let split_by_quotes: Vec<&str> = split_by_quotes.split(SEP).collect();
    let mut acc = T {
        stri: String::from(""),
        shift_arr: create_shift_arr(&tab),
        tab: tab.clone(),
        arr: gen_array(split_by_quotes, &tab),
        parens_level: 0,
        deep: 0,
    };

    for (i, original_el) in acc.clone().arr.iter().enumerate() {
        let parens_level = subquery_level(original_el, &acc.parens_level) as usize;
        let mut arr = acc.arr.to_vec();
        if regex_match(&original_el, r"SELECT|SET") {
            arr[i] = regex_replace(&original_el, r",\s+", &format!(",\n{}{}", acc.tab, acc.tab));
        }
        let (stri, deep) = update_str(&arr[i], &parens_level, &acc);

        acc = T {
            stri: stri,
            shift_arr: acc.shift_arr,
            tab: acc.tab,
            arr: arr,
            parens_level: parens_level,
            deep: deep,
        };
    }

    let out = regex_replace(&acc.stri, r"\s+\n", "\n");
    String::from(regex_replace(&out, r"\n+", "\n").trim())
}

fn update_str(el: &str, parens_level: &usize, acc: &T) -> (String, usize) {
    if regex_match(el, r"\(\s*SELECT") {
        (format!("{}{}{}", acc.stri, acc.shift_arr[acc.deep + 1], el), acc.deep + 1)
    } else {
        let stri = if el.contains("'") { format!("{}{}", acc.stri, el) } else { format!("{}{}{}", acc.stri, acc.shift_arr[acc.deep], el) };
        let deep = if *parens_level < 1 && acc.deep != 0 { acc.deep - 1 } else { acc.deep };
        (stri, deep)
    }
}

fn create_shift_arr(tab: &str) -> Vec<String> {
    let mut v = vec![];
    for i in 0..100 {
        v.push(format!("\n{}", iter::repeat(tab).take(i).collect::<String>()));
    }
    v
}

fn gen_array(split_by_quotes: Vec<&str>, tab: &str) -> Vec<String> {
    let mut v: Vec<String> = vec![];
    for (i, el) in split_by_quotes.iter().enumerate() {
        v.append(&mut split_if_even(i, *el, tab));
    }
    v
}

fn subquery_level(stri: &str, parens_level: &usize) -> isize {
    *parens_level as isize - (String::from(stri).replace("(", "").len() as isize - String::from(stri).replace(")", "").len() as isize)
}

fn all_replacements<'a>(tab: &str) -> Vec<(&'a str, String)> {
    vec![
        (r"(?i) AND ",              format!("{}{}AND ", SEP, tab)),
        (r"(?i) BETWEEN ",          format!("{}{}BETWEEN ", SEP, tab)),
        (r"(?i) CASE ",             format!("{}{}CASE ", SEP, tab)),
        (r"(?i) ELSE ",             format!("{}{}ELSE ", SEP, tab)),
        (r"(?i) END ",              format!("{}{}END ", SEP, tab)),
        (r"(?i) FROM ",             format!("{}FROM ", SEP)),
        (r"(?i) GROUP\s+BY ",       format!("{}GROUP BY ", SEP)),
        (r"(?i) HAVING ",           format!("{}HAVING ", SEP)),
        (r"(?i) IN ",               String::from(" IN ")),
        (r"(?i) JOIN ",             format!("{}JOIN ", SEP)),
        (r"(?i) CROSS(~::~)+JOIN ", format!("{}CROSS JOIN ", SEP)),
        (r"(?i) INNER(~::~)+JOIN ", format!("{}INNER JOIN ", SEP)),
        (r"(?i) LEFT(~::~)+JOIN ",  format!("{}LEFT JOIN ", SEP)),
        (r"(?i) RIGHT(~::~)+JOIN ", format!("{}RIGHT JOIN ", SEP)),
        (r"(?i) ON ",               format!("{}{}ON ", SEP, tab)),
        (r"(?i) OR ",               format!("{}{}OR ", SEP, tab)),
        (r"(?i) ORDER\s+BY ",       format!("{}ORDER BY ", SEP)),
        (r"(?i) OVER ",             format!("{}{}OVER ", SEP, tab)),
        (r"(?i)\(\s*SELECT ",       format!("{}(SELECT ", SEP)),
        (r"(?i)\)\s*SELECT ",       format!("){}SELECT ", SEP)),
        (r"(?i) THEN ",             format!(" THEN{}{}", SEP, tab)),
        (r"(?i) UNION ",            format!("{}UNION{}", SEP, SEP)),
        (r"(?i) USING ",            format!("{}USING ", SEP)),
        (r"(?i) WHEN ",             format!("{}{}WHEN ", SEP, tab)),
        (r"(?i) WHERE ",            format!("{}WHERE ", SEP)),
        (r"(?i) WITH ",             format!("{}WITH ", SEP)),
        (r"(?i) SET ",              format!("{}SET ", SEP)),
        (r"(?i) ALL ",              String::from(" ALL ")),
        (r"(?i) AS ",               String::from(" AS ")),
        (r"(?i) ASC ",              String::from(" ASC ")),
        (r"(?i) DESC ",             String::from(" DESC ")),
        (r"(?i) DISTINCT ",         String::from(" DISTINCT ")),
        (r"(?i) EXISTS ",           String::from(" EXISTS ")),
        (r"(?i) NOT ",              String::from(" NOT ")),
        (r"(?i) NULL ",             String::from(" NULL ")),
        (r"(?i) LIKE ",             String::from(" LIKE ")),
        (r"(?i)\s*SELECT ",         String::from("SELECT ")),
        (r"(?i)\s*UPDATE ",         String::from("UPDATE ")),
        (r"(?i)\s*DELETE ",         String::from("DELETE ")),
        (r"(?i)(~::~)+",            String::from(SEP)),
    ]
}

fn split_sql(stri: &str, tab: &str) -> Vec<String> {
    let mut s = String::from(stri);
    for r in all_replacements(tab) {
        s = regex_replace(&s, &r.0, &r.1);
    }
    String::from(s).split(SEP).map(String::from).collect()
}

fn split_if_even(i: usize, stri: &str, tab: &str) -> Vec<String> {
    if i % 2 == 0 { split_sql(stri, tab) } else { vec![String::from(stri)] }
}

#[cfg(test)]
mod tests {
    use super::format;

    macro_rules! test_formatting {
        ($($name:ident: $value:expr,)*) => {
        $(
            #[test]
            fn $name() {
                let (input, expected, num_spaces) = $value;
                assert_eq!(expected, format(String::from(input), num_spaces));
            }
        )*
        }
    }

    test_formatting! {
        // Tabbed keywords
        formatting_of_and: ("foo AND bar", "foo\n  AND bar", 2),
        formatting_of_between: ("foo BETWEEN bar", "foo\n  BETWEEN bar", 2),
        formatting_of_case: ("foo CASE bar", "foo\n  CASE bar", 2),
        formatting_of_else: ("foo ELSE bar", "foo\n  ELSE bar", 2),
        formatting_of_end: ("foo END bar", "foo\n  END bar", 2),
        formatting_of_on: ("foo ON bar", "foo\n  ON bar", 2),
        formatting_of_or: ("foo OR bar", "foo\n  OR bar", 2),
        formatting_of_over: ("foo OVER bar", "foo\n  OVER bar", 2),
        formatting_of_when: ("foo WHEN bar", "foo\n  WHEN bar", 2),

        // Untabbed keywords
        formatting_of_from: ("foo FROM bar", "foo\nFROM bar", 2),
        formatting_of_group_by: ("foo GROUP BY bar", "foo\nGROUP BY bar", 2),
        formatting_of_having: ("foo HAVING bar", "foo\nHAVING bar", 2),
        formatting_of_join: ("foo JOIN bar", "foo\nJOIN bar", 2),
        formatting_of_cross_join: ("foo CROSS JOIN bar", "foo\nCROSS JOIN bar", 2),
        formatting_of_inner_join: ("foo INNER JOIN bar", "foo\nINNER JOIN bar", 2),
        formatting_of_left_join: ("foo LEFT JOIN bar", "foo\nLEFT JOIN bar", 2),
        formatting_of_right_join: ("foo RIGHT JOIN bar", "foo\nRIGHT JOIN bar", 2),
        formatting_of_order_by: ("foo ORDER BY bar", "foo\nORDER BY bar", 2),
        formatting_of_where: ("foo WHERE bar", "foo\nWHERE bar", 2),
        formatting_of_with: ("foo WITH bar", "foo\nWITH bar", 2),
        formatting_of_set: ("foo SET bar", "foo\nSET bar", 2),

        // Unchanged keywords
        formatting_of_in: ("foo IN bar", "foo IN bar", 2),
        formatting_of_all: ("foo ALL bar", "foo ALL bar", 2),
        formatting_of_as: ("foo AS bar", "foo AS bar", 2),
        formatting_of_asc: ("foo ASC bar", "foo ASC bar", 2),
        formatting_of_desc: ("foo DESC bar", "foo DESC bar", 2),
        formatting_of_distinct: ("foo DISTINCT bar", "foo DISTINCT bar", 2),
        formatting_of_exists: ("foo EXISTS bar", "foo EXISTS bar", 2),
        formatting_of_not: ("foo NOT bar", "foo NOT bar", 2),
        formatting_of_null: ("foo NULL bar", "foo NULL bar", 2),
        formatting_of_like: ("foo LIKE bar", "foo LIKE bar", 2),

        // SELECTs
        formatting_of_select_1: ("SELECT foo bar", "SELECT foo bar", 2),
        formatting_of_select_2: (" SELECT foo bar", "SELECT foo bar", 2),
        formatting_of_select_3: ("foo (SELECT bar", "foo\n  (SELECT bar", 2),
        formatting_of_select_4: ("foo ( SELECT bar", "foo\n  (SELECT bar", 2),
        formatting_of_select_5: ("foo) SELECT bar", "foo)\nSELECT bar", 2),
        formatting_of_select_6: ("foo)SELECT bar", "foo)\nSELECT bar", 2),

        // UPDATEs
        formatting_of_update_1: ("UPDATE foo bar", "UPDATE foo bar", 2),
        formatting_of_update_2: (" UPDATE foo bar", "UPDATE foo bar", 2),

        // DELETEs
        formatting_of_delete_1: ("DELETE foo bar", "DELETE foo bar", 2),
        formatting_of_delete_2: (" DELETE foo bar", "DELETE foo bar", 2),

        // Special case keywords
        formatting_of_then:  ("foo THEN bar", "foo THEN\n  bar", 2),
        formatting_of_union: ("foo UNION bar", "foo\nUNION\nbar", 2),
        formatting_of_using: ("foo USING bar", "foo\nUSING bar", 2),

        // Nested queries
        test_single_nested_query: ("SELECT foo FROM (SELECT bar FROM baz)", "SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)", 2),
        test_multiple_nested_queries: ("SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))", "SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))", 2),

        // Case transformations
        upcasing_of_and: (" and ", "AND", 2),
        upcasing_of_between: (" between ", "BETWEEN", 2),
        upcasing_of_case: (" case ", "CASE", 2),
        upcasing_of_else: (" else ", "ELSE", 2),
        upcasing_of_end: (" end ", "END", 2),
        upcasing_of_on: (" on ", "ON", 2),
        upcasing_of_or: (" or ", "OR", 2),
        upcasing_of_over: (" over ", "OVER", 2),
        upcasing_of_when: (" when ", "WHEN", 2),
        upcasing_of_from: (" from ", "FROM", 2),
        upcasing_of_group_by: (" GROUP by ", "GROUP BY", 2),
        upcasing_of_having: (" having ", "HAVING", 2),
        upcasing_of_join: (" join ", "JOIN", 2),
        upcasing_of_cross_join: (" cross join ", "CROSS JOIN", 2),
        upcasing_of_inner_join: (" inner join ", "INNER JOIN", 2),
        upcasing_of_left_join: (" left join ", "LEFT JOIN", 2),
        upcasing_of_right_join: (" right join ", "RIGHT JOIN", 2),
        upcasing_of_order_by: (" order by ", "ORDER BY", 2),
        upcasing_of_where: (" where ", "WHERE", 2),
        upcasing_of_with: (" with ", "WITH", 2),
        upcasing_of_set: (" set ", "SET", 2),
        upcasing_of_in: (" in ", "IN", 2),
        upcasing_of_all: (" all ", "ALL", 2),
        upcasing_of_as: (" as ", "AS", 2),
        upcasing_of_asc: (" asc ", "ASC", 2),
        upcasing_of_desc: (" desc ", "DESC", 2),
        upcasing_of_distinct: (" distinct ", "DISTINCT", 2),
        upcasing_of_exists: (" exists ", "EXISTS", 2),
        upcasing_of_not: (" not ", "NOT", 2),
        upcasing_of_null: (" null ", "NULL", 2),
        upcasing_of_like: (" like ", "LIKE", 2),
        upcasing_of_select: (" select ", "SELECT", 2),
        upcasing_of_update: (" update ", "UPDATE", 2),
        upcasing_of_then: (" then ", "THEN", 2),
        upcasing_of_union: (" union ", "UNION", 2),
        upcasing_of_using: (" using ", "USING", 2),

        // Full queries
        formatting_of_full_select: ("SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1", "SELECT a.b,\n    c.d\nFROM a\nJOIN b\n  ON a.b = c.d\nWHERE a.b = 1\n  AND c.d = 1", 2),
        formatting_of_full_update: ("UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3", "UPDATE a\nSET a.b = 1,\n    a.c = 2\nWHERE a.d = 3", 2),
        formatting_of_full_delete: ("DELETE FROM a WHERE a.b = 1 AND a.c = 2", "DELETE\nFROM a\nWHERE a.b = 1\n  AND a.c = 2", 2),

        // Full queries with 4 spaces
        formatting_of_full_select_with_4_spaces: ("SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1", "SELECT a.b,\n        c.d\nFROM a\nJOIN b\n    ON a.b = c.d\nWHERE a.b = 1\n    AND c.d = 1", 4),
        formatting_of_full_update_with_4_spaces: ("UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3", "UPDATE a\nSET a.b = 1,\n        a.c = 2\nWHERE a.d = 3", 4),
        formatting_of_full_delete_with_4_spaces: ("DELETE FROM a WHERE a.b = 1 AND a.c = 2", "DELETE\nFROM a\nWHERE a.b = 1\n    AND a.c = 2", 4),
    }
}
