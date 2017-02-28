package main

import (
	"strings"
	"testing"
)

var tabbedKeywords = []string{
	"AND",
	"BETWEEN",
	"CASE",
	"ELSE",
	"END",
	"ON",
	"OR",
	"OVER",
	"WHEN",
}

var untabbedKeywords = []string{
	"FROM",
	"GROUP BY",
	"HAVING",
	"JOIN",
	"CROSS JOIN",
	"INNER JOIN",
	"LEFT JOIN",
	"RIGHT JOIN",
	"ORDER BY",
	"WHERE",
	"WITH",
	"SET",
}

var unchangedKeywords = []string{
	"IN",
	"ALL",
	"AS",
	"ASC",
	"DESC",
	"DISTINCT",
	"EXISTS",
	"NOT",
	"NULL",
	"LIKE",
}

func assertEqual(t *testing.T, expected string, actual string) {
	if expected != actual {
		t.Errorf("Expected:\n\n \033[0;32m%s\033[0m\n\n, got\n\n \033[0;31m%s\033[0m", expected, actual)
	}
}

func assertFullQueries(t *testing.T, numSpaces int) {
	tab := strings.Repeat(" ", numSpaces)

	queries := map[string]string{
		"SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1": strings.Join([]string{"SELECT a.b,\n", tab, tab, "c.d\nFROM a\nJOIN b\n", tab, "ON a.b = c.d\nWHERE a.b = 1\n", tab, "AND c.d = 1"}, ""),
		"UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3":                          strings.Join([]string{"UPDATE a\nSET a.b = 1,\n", tab, tab, "a.c = 2\nWHERE a.d = 3"}, ""),
		"DELETE FROM a WHERE a.b = 1 AND a.c = 2":                              strings.Join([]string{"DELETE\nFROM a\nWHERE a.b = 1\n", tab, "AND a.c = 2"}, ""),
	}

	for input, expected := range queries {
		assertEqual(t, expected, formatSql(input, numSpaces))
	}
}

func TestTabbedKeywords(t *testing.T) {
	for _, word := range tabbedKeywords {
		expected := strings.Join([]string{"foo\n  ", word, " bar"}, "")
		actual := formatSql(strings.Join([]string{"foo", word, "bar"}, " "), 2)
		assertEqual(t, expected, actual)
	}
}

func TestUntabbedKeywords(t *testing.T) {
	for _, word := range untabbedKeywords {
		expected := strings.Join([]string{"foo\n", word, " bar"}, "")
		actual := formatSql(strings.Join([]string{"foo", word, "bar"}, " "), 2)
		assertEqual(t, expected, actual)
	}
}

func TestUnchangedKeywords(t *testing.T) {
	for _, word := range unchangedKeywords {
		expected := strings.Join([]string{"foo", word, "bar"}, " ")
		actual := formatSql(strings.Join([]string{"foo", word, "bar"}, " "), 2)
		assertEqual(t, expected, actual)
	}
}

func TestSELECTs(t *testing.T) {
	selects := map[string]string{
		"SELECT foo bar":   "SELECT foo bar",
		" SELECT foo bar":  "SELECT foo bar",
		"foo (SELECT bar":  "foo\n  (SELECT bar",
		"foo ( SELECT bar": "foo\n  (SELECT bar",
		"foo) SELECT bar":  "foo)\nSELECT bar",
		"foo)SELECT bar":   "foo)\nSELECT bar",
	}
	for input, expected := range selects {
		assertEqual(t, expected, formatSql(input, 2))
	}
}

func TestUPDATEs(t *testing.T) {
	updates := map[string]string{
		"UPDATE foo bar":  "UPDATE foo bar",
		" UPDATE foo bar": "UPDATE foo bar",
	}
	for input, expected := range updates {
		assertEqual(t, expected, formatSql(input, 2))
	}
}

func TestDELETEs(t *testing.T) {
	deletes := map[string]string{
		"DELETE foo bar":  "DELETE foo bar",
		" DELETE foo bar": "DELETE foo bar",
	}
	for input, expected := range deletes {
		assertEqual(t, expected, formatSql(input, 2))
	}
}

func TestSpecialCaseKeywords(t *testing.T) {
	words := map[string]string{
		"THEN":  "foo THEN\n  bar",
		"UNION": "foo\nUNION\nbar",
		"USING": "foo\nUSING bar",
	}
	for word, expected := range words {
		assertEqual(t, expected, formatSql(strings.Join([]string{"foo", word, "bar"}, " "), 2))
	}
}

func TestNestedQueries(t *testing.T) {
	queries := map[string]string{
		"SELECT foo FROM (SELECT bar FROM baz)":                    "SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)",
		"SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))": "SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))",
	}
	for input, expected := range queries {
		assertEqual(t, expected, formatSql(input, 2))
	}
}

func TestCaseTransformations(t *testing.T) {
	words := append(
		append(append(tabbedKeywords, untabbedKeywords...), unchangedKeywords...),
		[]string{"SELECT", "UPDATE", "THEN", "UNION", "USING"}...,
	)
	for _, word := range words {
		expected := word
		actual := strings.TrimSpace(formatSql(strings.Join([]string{" ", strings.ToLower(word), " "}, ""), 2))
		assertEqual(t, expected, actual)
	}
}

func TestFullQueries(t *testing.T)                             { assertFullQueries(t, 2) }
func TestFullQueriesWithADifferentNumberOfSpaces(t *testing.T) { assertFullQueries(t, 4) }
