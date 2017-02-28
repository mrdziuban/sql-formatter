class T {
  String str;
  List<String> shiftArr;
  String tab;
  List<String> arr;
  int parensLevel;
  int deep;

  T(String str, List<String> shiftArr, String tab, List<String> arr, int parensLevel, int deep) {
    this.str = str;
    this.shiftArr = shiftArr;
    this.tab = tab;
    this.arr = arr;
    this.parensLevel = parensLevel;
    this.deep = deep;
  }
}

class Out {
  String str;
  int deep;

  Out(String str, int deep) {
    this.str = str;
    this.deep = deep;
  }
}

class Replacement {
  RegExp pattern;
  String replacement;

  Replacement(RegExp pattern, String replacement) {
    this.pattern = pattern;
    this.replacement = replacement;
  }
}

class SQLFormatter {
  static const sep = '~::~';

  static String format(String sql, int numSpaces) {
    String tab = ' ' * numSpaces;
    List<String> splitByQuotes = transformString(sql, [
      (s) => s.replaceAll(new RegExp(r'\s+'), ' '),
      (s) => s.replaceAll("'", "$sep'")
    ]).split(sep);
    T input = new T('', createShiftArr(tab), tab, genArray(splitByQuotes, tab), 0, 0);
    T output = new List<int>.generate(input.arr.length, (int i) => i).fold(input, updateOutput);

    return transformString(output.str, [
      (s) => s.replaceAll(new RegExp(r'\s+\n'), '\n'),
      (s) => s.replaceAll(new RegExp(r'\n+'), '\n'),
      (s) => s.trim()
    ]);
  }

  static T updateOutput(T acc, int i) {
    String originalEl = acc.arr[i];
    int parensLevel = subqueryLevel(originalEl, acc.parensLevel);
    List<String> arr = new List<String>.from(acc.arr);
    if (originalEl.contains(new RegExp(r'SELECT|SET'))) {
      arr[i] = originalEl.replaceAll(new RegExp(r'\,\s+'), ',\n${acc.tab}${acc.tab}');
    }
    String el = arr[i];
    Out out = el.contains(new RegExp(r'\(\s*SELECT'))
      ? new Out('${acc.str}${acc.shiftArr[acc.deep + 1]}${el}', acc.deep + 1)
      : new Out(
        el.contains("'") ? '${acc.str}${el}' : '${acc.str}${acc.shiftArr[acc.deep]}${el}',
        parensLevel < 1 && acc.deep != 0 ? acc.deep - 1 : acc.deep
      );

    return new T(out.str, acc.shiftArr, acc.tab, arr, parensLevel, out.deep);
  }

  static String transformString(String str, List<Function> fns) => fns.fold(str, (acc, fn) => fn(acc));

  static List<String> createShiftArr(String tab) => new List<String>.generate(100, (int i) => '\n' + (tab * i));
  static List<String> genArray(List<String> splitByQuotes, String tab) {
    return new List<List<String>>.generate(
      splitByQuotes.length,
      (int i) => splitIfEven(i, splitByQuotes[i], tab)
    ).expand((x) => x).toList();
  }

  static int subqueryLevel(String str, int level) {
    return level - (str.replaceAll('(', '').length - str.replaceAll(')', '').length);
  }

  static List<Replacement> allReplacements(String tab) {
    return [
      new Replacement(new RegExp(r' AND ', caseSensitive: false),              sep + tab + 'AND '),
      new Replacement(new RegExp(r' BETWEEN ', caseSensitive: false),          sep + tab + 'BETWEEN '),
      new Replacement(new RegExp(r' CASE ', caseSensitive: false),             sep + tab + 'CASE '),
      new Replacement(new RegExp(r' ELSE ', caseSensitive: false),             sep + tab + 'ELSE '),
      new Replacement(new RegExp(r' END ', caseSensitive: false),              sep + tab + 'END '),
      new Replacement(new RegExp(r' FROM ', caseSensitive: false),             sep + 'FROM '),
      new Replacement(new RegExp(r' GROUP\s+BY ', caseSensitive: false),       sep + 'GROUP BY '),
      new Replacement(new RegExp(r' HAVING ', caseSensitive: false),           sep + 'HAVING '),
      new Replacement(new RegExp(r' IN ', caseSensitive: false),               ' IN '),
      new Replacement(new RegExp(r' JOIN ', caseSensitive: false),             sep + 'JOIN '),
      new Replacement(new RegExp(r' CROSS(~::~)+JOIN ', caseSensitive: false), sep + 'CROSS JOIN '),
      new Replacement(new RegExp(r' INNER(~::~)+JOIN ', caseSensitive: false), sep + 'INNER JOIN '),
      new Replacement(new RegExp(r' LEFT(~::~)+JOIN ', caseSensitive: false),  sep + 'LEFT JOIN '),
      new Replacement(new RegExp(r' RIGHT(~::~)+JOIN ', caseSensitive: false), sep + 'RIGHT JOIN '),
      new Replacement(new RegExp(r' ON ', caseSensitive: false),               sep + tab + 'ON '),
      new Replacement(new RegExp(r' OR ', caseSensitive: false),               sep + tab + 'OR '),
      new Replacement(new RegExp(r' ORDER\s+BY ', caseSensitive: false),       sep + 'ORDER BY '),
      new Replacement(new RegExp(r' OVER ', caseSensitive: false),             sep + tab + 'OVER '),
      new Replacement(new RegExp(r'\(\s*SELECT ', caseSensitive: false),       sep + '(SELECT '),
      new Replacement(new RegExp(r'\)\s*SELECT ', caseSensitive: false),       ')' + sep + 'SELECT '),
      new Replacement(new RegExp(r' THEN ', caseSensitive: false),             ' THEN' + sep + tab),
      new Replacement(new RegExp(r' UNION ', caseSensitive: false),            sep + 'UNION' + sep),
      new Replacement(new RegExp(r' USING ', caseSensitive: false),            sep + 'USING '),
      new Replacement(new RegExp(r' WHEN ', caseSensitive: false),             sep + tab + 'WHEN '),
      new Replacement(new RegExp(r' WHERE ', caseSensitive: false),            sep + 'WHERE '),
      new Replacement(new RegExp(r' WITH ', caseSensitive: false),             sep + 'WITH '),
      new Replacement(new RegExp(r' SET ', caseSensitive: false),              sep + 'SET '),
      new Replacement(new RegExp(r' ALL ', caseSensitive: false),              ' ALL '),
      new Replacement(new RegExp(r' AS ', caseSensitive: false),               ' AS '),
      new Replacement(new RegExp(r' ASC ', caseSensitive: false),              ' ASC '),
      new Replacement(new RegExp(r' DESC ', caseSensitive: false),             ' DESC '),
      new Replacement(new RegExp(r' DISTINCT ', caseSensitive: false),         ' DISTINCT '),
      new Replacement(new RegExp(r' EXISTS ', caseSensitive: false),           ' EXISTS '),
      new Replacement(new RegExp(r' NOT ', caseSensitive: false),              ' NOT '),
      new Replacement(new RegExp(r' NULL ', caseSensitive: false),             ' NULL '),
      new Replacement(new RegExp(r' LIKE ', caseSensitive: false),             ' LIKE '),
      new Replacement(new RegExp(r'\s*SELECT ', caseSensitive: false),         'SELECT '),
      new Replacement(new RegExp(r'\s*UPDATE ', caseSensitive: false),         'UPDATE '),
      new Replacement(new RegExp(r'\s*DELETE ', caseSensitive: false),         'DELETE '),
      new Replacement(new RegExp('($sep)+'),                                      sep)
    ];
  }

  static List<String> splitSql(String str, String tab) {
    return allReplacements(tab).fold(str.replaceAll(new RegExp(r'\s+'), ' '), (String acc, Replacement r) {
      return acc.replaceAll(r.pattern, r.replacement);
    }).split(sep);
  }

  static List<String> splitIfEven(int i, String str, String tab) => i % 2 == 0 ? splitSql(str, tab) : [str];
}
