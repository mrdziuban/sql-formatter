const sep = '~::~';

const transform = (val, ...fns) => {
  return fns.reduce((acc, fn) => fn(acc), val);
};

const createShiftArr = (space) => {
  return [...Array(100).keys()].reduce((acc, i) => acc.concat(`\n${space.repeat(i)}`), []);
};

const subqueryLevel = (str, level) => {
  return level - (str.replace(/\(/g, '').length - str.replace(/\)/g, '').length)
};

const allReplacements = (tab) => {
  return [
    [/ AND /gi,                              sep + tab + 'AND '],
    [/ BETWEEN /gi,                          sep + tab + 'BETWEEN '],
    [/ CASE /gi,                             sep + tab + 'CASE '],
    [/ ELSE /gi,                             sep + tab + 'ELSE '],
    [/ END /gi,                              sep + tab + 'END '],
    [/ FROM /gi,                             sep + 'FROM '],
    [/ GROUP\s+BY /gi,                       sep + 'GROUP BY '],
    [/ HAVING /gi,                           sep + 'HAVING '],
    [/ IN /gi,                               ' IN '],
    [/ ((CROSS|INNER|LEFT|RIGHT) )?JOIN /gi, ' $1JOIN '],
    [/ ON /gi,                               sep + tab + 'ON '],
    [/ OR /gi,                               sep + tab + 'OR '],
    [/ ORDER\s+BY /gi,                       sep + 'ORDER BY '],
    [/ OVER /gi,                             sep + tab + 'OVER '],
    [/\(\s*SELECT /gi,                       sep + '(SELECT '],
    [/\)\s*SELECT /gi,                       ')' + sep + 'SELECT '],
    [/ THEN /gi,                             ' THEN' + sep + tab],
    [/ UNION /gi,                            sep + 'UNION' + sep],
    [/ USING /gi,                            sep + 'USING '],
    [/ WHEN /gi,                             sep + tab + 'WHEN '],
    [/ WHERE /gi,                            sep + 'WHERE '],
    [/ WITH /gi,                             sep + 'WITH '],
    [/ SET /gi,                              sep + 'SET '],
    [/ ALL /gi,                              ' ALL '],
    [/ AS /gi,                               ' AS '],
    [/ ASC /gi,                              ' ASC '],
    [/ DESC /gi,                             ' DESC '],
    [/ DISTINCT /gi,                         ' DISTINCT '],
    [/ EXISTS /gi,                           ' EXISTS '],
    [/ NOT /gi,                              ' NOT '],
    [/ NULL /gi,                             ' NULL '],
    [/ LIKE /gi,                             ' LIKE '],
    [/\s*SELECT /gi,                         'SELECT '],
    [/\s*UPDATE /gi,                         'UPDATE '],
    [/\s*DELETE /gi,                         'DELETE '],
    [new RegExp(`(${sep})+`),                sep]
  ];
};

const splitSql = (str, tab) => {
  return allReplacements(tab).reduce((acc, r) => {
    return acc.replace(r[0], r[1]);
  }, str.replace(/\s+/g, ' ')).split(sep);
};

const splitIfEven = (i, str, tab) => {
  return i % 2 === 0 ? splitSql(str, tab) : [ str ];
};

const updateOutput = (el, parensLevel, input, i) => {
  return /\(\s*SELECT/.test(el)
    ? [`${input.str}${input.shiftArr[input.deep + 1]}${el}`, input.deep + 1]
    : [
      /'/.test(el) ? `${input.str}${el}` : `${input.str}${input.shiftArr[input.deep]}${el}`,
      (parensLevel < 1 && input.deep !== 0) ? input.deep - 1 : input.deep
    ];
};

export default (sql, numSpaces) => {
  const tab = ' '.repeat(numSpaces);
  const splitByQuotes = transform(sql,
    str => str.replace(/\s+/g, ' '),
    str => str.replace(/'/g, `${sep}'`),
    str => str.split(sep));
  const input = {
    str: '',
    shiftArr: createShiftArr(tab),
    arr: Array.prototype.concat(
      ...[...Array(splitByQuotes.length).keys()].map(i => splitIfEven(i, splitByQuotes[i], tab))
    ),
    parensLevel: 0,
    deep: 0
  };

  const len = input.arr.length;
  return [...Array(len).keys()].reduce((acc, i) => {
    const originalEl = acc.arr[i];
    const parensLevel = subqueryLevel(originalEl, acc.parensLevel);
    const arr = /SELECT|SET/.test(originalEl)
      ? acc.arr.slice(0, i).concat(originalEl.replace(/\,\s+/, `,\n${acc.tab}${acc.tab}`)).concat(acc.arr.slice(i + 1))
      : acc.arr;
    const el = arr[i]
    const [str, deep] = updateOutput(el, parensLevel, acc, i);
    return Object.assign(acc, {
      str,
      arr,
      parensLevel,
      deep
    });
  }, input).str.trim();
};
