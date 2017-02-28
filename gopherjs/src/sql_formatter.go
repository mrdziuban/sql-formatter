package main

import (
	"regexp"
	"strings"
)

var sep = "~::~"

type T struct {
	str         string
	shiftArr    []string
	tab         string
	arr         []string
	parensLevel int
	deep        int
}

type Replacement struct {
	pattern     *regexp.Regexp
	replacement string
}

func formatSql(sql string, numSpaces int) string {
	tab := strings.Repeat(" ", numSpaces)
	splitByQuotes := strings.Split(transformString(sql, []func(s string) string{
		func(s string) string { return regexp.MustCompile("\\s+").ReplaceAllString(s, " ") },
		func(s string) string { return strings.Replace(s, "'", strings.Join([]string{sep, "'"}, ""), -1) },
	}), sep)
	input := T{str: "", shiftArr: createShiftArr(tab), tab: tab, arr: genArray(splitByQuotes, tab), parensLevel: 0, deep: 0}
	output := input
	for i := 0; i < len(input.arr); i++ {
		output = genOutput(output, i)
	}

	return transformString(output.str, []func(s string) string{
		func(s string) string { return regexp.MustCompile("\\s+\\n").ReplaceAllString(s, "\n") },
		func(s string) string { return regexp.MustCompile("\\n+").ReplaceAllString(s, "\n") },
		func(s string) string { return strings.TrimSpace(s) },
	})
}

func genOutput(acc T, i int) T {
	originalEl := acc.arr[i]
	parensLevel := subqueryLevel(originalEl, acc.parensLevel)
	arr := make([]string, len(acc.arr))
	copy(arr, acc.arr)
	if regexp.MustCompile("SELECT|SET").MatchString(originalEl) {
		arr[i] = regexp.MustCompile(",\\s+").ReplaceAllString(originalEl, strings.Join([]string{",\n", acc.tab, acc.tab}, ""))
	}
	str, deep := updateStr(arr[i], parensLevel, acc, i)

	return T{
		str:         str,
		shiftArr:    acc.shiftArr,
		tab:         acc.tab,
		arr:         arr,
		parensLevel: parensLevel,
		deep:        deep,
	}
}

func updateStr(el string, parensLevel int, acc T, i int) (string, int) {
	if regexp.MustCompile("\\(\\s*SELECT").MatchString(el) {
		return strings.Join([]string{acc.str, acc.shiftArr[acc.deep+1], el}, ""), acc.deep + 1
	} else {
		var str string
		var deep int
		if strings.Contains(el, "'") {
			str = strings.Join([]string{acc.str, el}, "")
		} else {
			str = strings.Join([]string{acc.str, acc.shiftArr[acc.deep], el}, "")
		}

		if parensLevel < 1 && acc.deep != 0 {
			deep = acc.deep - 1
		} else {
			deep = acc.deep
		}

		return str, deep
	}
}

func transformString(str string, fns []func(s string) string) string {
	for _, fn := range fns {
		str = fn(str)
	}
	return str
}

func createShiftArr(tab string) []string {
	var a []string
	for i := 0; i < 100; i++ {
		a = append(a, strings.Join([]string{"\n", strings.Repeat(tab, i)}, ""))
	}
	return a
}

func genArray(splitByQuotes []string, tab string) []string {
	var a []string
	for i, _ := range splitByQuotes {
		a = append(a, splitIfEven(i, splitByQuotes[i], tab)...)
	}
	return a
}

func subqueryLevel(str string, level int) int {
	return level - (len(strings.Replace(str, "(", "", -1)) - len(strings.Replace(str, ")", "", -1)))
}

func allReplacements(tab string) []Replacement {
	return []Replacement{
		Replacement{regexp.MustCompile("(?i) AND "), sep + tab + "AND "},
		Replacement{regexp.MustCompile("(?i) BETWEEN "), sep + tab + "BETWEEN "},
		Replacement{regexp.MustCompile("(?i) CASE "), sep + tab + "CASE "},
		Replacement{regexp.MustCompile("(?i) ELSE "), sep + tab + "ELSE "},
		Replacement{regexp.MustCompile("(?i) END "), sep + tab + "END "},
		Replacement{regexp.MustCompile("(?i) FROM "), sep + "FROM "},
		Replacement{regexp.MustCompile("(?i) GROUP\\s+BY "), sep + "GROUP BY "},
		Replacement{regexp.MustCompile("(?i) HAVING "), sep + "HAVING "},
		Replacement{regexp.MustCompile("(?i) IN "), " IN "},
		Replacement{regexp.MustCompile("(?i) JOIN "), sep + "JOIN "},
		Replacement{regexp.MustCompile("(?i) CROSS(~::~)+JOIN "), sep + "CROSS JOIN "},
		Replacement{regexp.MustCompile("(?i) INNER(~::~)+JOIN "), sep + "INNER JOIN "},
		Replacement{regexp.MustCompile("(?i) LEFT(~::~)+JOIN "), sep + "LEFT JOIN "},
		Replacement{regexp.MustCompile("(?i) RIGHT(~::~)+JOIN "), sep + "RIGHT JOIN "},
		Replacement{regexp.MustCompile("(?i) ON "), sep + tab + "ON "},
		Replacement{regexp.MustCompile("(?i) OR "), sep + tab + "OR "},
		Replacement{regexp.MustCompile("(?i) ORDER\\s+BY "), sep + "ORDER BY "},
		Replacement{regexp.MustCompile("(?i) OVER "), sep + tab + "OVER "},
		Replacement{regexp.MustCompile("(?i)\\(\\s*SELECT "), sep + "(SELECT "},
		Replacement{regexp.MustCompile("(?i)\\)\\s*SELECT "), ")" + sep + "SELECT "},
		Replacement{regexp.MustCompile("(?i) THEN "), " THEN" + sep + tab},
		Replacement{regexp.MustCompile("(?i) UNION "), sep + "UNION" + sep},
		Replacement{regexp.MustCompile("(?i) USING "), sep + "USING "},
		Replacement{regexp.MustCompile("(?i) WHEN "), sep + tab + "WHEN "},
		Replacement{regexp.MustCompile("(?i) WHERE "), sep + "WHERE "},
		Replacement{regexp.MustCompile("(?i) WITH "), sep + "WITH "},
		Replacement{regexp.MustCompile("(?i) SET "), sep + "SET "},
		Replacement{regexp.MustCompile("(?i) ALL "), " ALL "},
		Replacement{regexp.MustCompile("(?i) AS "), " AS "},
		Replacement{regexp.MustCompile("(?i) ASC "), " ASC "},
		Replacement{regexp.MustCompile("(?i) DESC "), " DESC "},
		Replacement{regexp.MustCompile("(?i) DISTINCT "), " DISTINCT "},
		Replacement{regexp.MustCompile("(?i) EXISTS "), " EXISTS "},
		Replacement{regexp.MustCompile("(?i) NOT "), " NOT "},
		Replacement{regexp.MustCompile("(?i) NULL "), " NULL "},
		Replacement{regexp.MustCompile("(?i) LIKE "), " LIKE "},
		Replacement{regexp.MustCompile("(?i)\\s*SELECT "), "SELECT "},
		Replacement{regexp.MustCompile("(?i)\\s*UPDATE "), "UPDATE "},
		Replacement{regexp.MustCompile("(?i)\\s*DELETE "), "DELETE "},
		Replacement{regexp.MustCompile(strings.Join([]string{"(?i)(", sep, ")+"}, "")), sep},
	}
}

func splitSql(str string, tab string) []string {
	acc := str
	for _, r := range allReplacements(tab) {
		acc = r.pattern.ReplaceAllString(acc, r.replacement)
	}
	return strings.Split(acc, sep)
}

func splitIfEven(i int, str string, tab string) []string {
	if i%2 == 0 {
		return splitSql(str, tab)
	} else {
		return []string{str}
	}
}
