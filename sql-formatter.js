function createShiftArr(space) {
  const shift = ['\n'];
  for (let i = 0; i < 100; i += 1) {
    shift.push(shift[i] + space);
  }

  return shift;
}

function isSubquery(str, parenthesisLevel) {
  return parenthesisLevel - (str.replace(/\(/g,'').length - str.replace(/\)/g,'').length );
}

function splitSql(str, tab) {
  return str.replace(/\s{1,}/g," ")
    .replace(/ AND /ig,"~::~"+tab+tab+"AND ")
    .replace(/ BETWEEN /ig,"~::~"+tab+"BETWEEN ")
    .replace(/ CASE /ig,"~::~"+tab+"CASE ")
    .replace(/ ELSE /ig,"~::~"+tab+"ELSE ")
    .replace(/ END /ig,"~::~"+tab+"END ")
    .replace(/ FROM /ig,"~::~FROM ")
    .replace(/ GROUP\s{1,}BY/ig,"~::~GROUP BY ")
    .replace(/ HAVING /ig,"~::~HAVING ")
    //.replace(/ SET /ig," SET~::~")
    .replace(/ IN /ig," IN ")

    .replace(/ JOIN /ig,"~::~JOIN ")
    .replace(/ CROSS~::~{1,}JOIN /ig,"~::~CROSS JOIN ")
    .replace(/ INNER~::~{1,}JOIN /ig,"~::~INNER JOIN ")
    .replace(/ LEFT~::~{1,}JOIN /ig,"~::~LEFT JOIN ")
    .replace(/ RIGHT~::~{1,}JOIN /ig,"~::~RIGHT JOIN ")

    .replace(/ ON /ig,"~::~"+tab+"ON ")
    .replace(/ OR /ig,"~::~"+tab+tab+"OR ")
    .replace(/ ORDER\s{1,}BY/ig,"~::~ORDER BY ")
    .replace(/ OVER /ig,"~::~"+tab+"OVER ")

    .replace(/\(\s{0,}SELECT /ig,"~::~(SELECT ")
    .replace(/\)\s{0,}SELECT /ig,")~::~SELECT ")

    .replace(/ THEN /ig," THEN~::~"+tab+"")
    .replace(/ UNION /ig,"~::~UNION~::~")
    .replace(/ USING /ig,"~::~USING ")
    .replace(/ WHEN /ig,"~::~"+tab+"WHEN ")
    .replace(/ WHERE /ig,"~::~WHERE ")
    .replace(/ WITH /ig,"~::~WITH ")

    //.replace(/\,\s{0,}\(/ig,",~::~( ")
    //.replace(/\,/ig,",~::~"+tab+tab+"")

    .replace(/ ALL /ig," ALL ")
    .replace(/ AS /ig," AS ")
    .replace(/ ASC /ig," ASC ")
    .replace(/ DESC /ig," DESC ")
    .replace(/ DISTINCT /ig," DISTINCT ")
    .replace(/ EXISTS /ig," EXISTS ")
    .replace(/ NOT /ig," NOT ")
    .replace(/ NULL /ig," NULL ")
    .replace(/ LIKE /ig," LIKE ")
    .replace(/\s{0,}SELECT /ig,"SELECT ")
    .replace(/\s{0,}UPDATE /ig,"UPDATE ")
    .replace(/ SET /ig," SET ")

    .replace(/~::~{1,}/g,"~::~")
    .split('~::~');
}

class SQLFormatter {
  static format(text) {
    let arByQuote = text.replace(/\s{1,}/g," ").replace(/\'/ig,"~::~\'").split('~::~');
    let len = arByQuote.length;
    let ar = [];
    let deep = 0;
    let tab = '  ';
    let parenthesisLevel = 0;
    let str = '';
    let ix = 0;
    let shift = createShiftArr(tab);

    for(ix=0;ix<len;ix++) {
      if(ix%2) {
        ar = ar.concat(arByQuote[ix]);
      } else {
        ar = ar.concat(splitSql(arByQuote[ix], tab) );
      }
    }

    len = ar.length;
    for(ix=0;ix<len;ix++) {

      parenthesisLevel = isSubquery(ar[ix], parenthesisLevel);

      if( /\s{0,}\s{0,}SELECT\s{0,}/.exec(ar[ix]))  {
        ar[ix] = ar[ix].replace(/\,/g,",\n"+tab+tab+"")
      }

      if( /\s{0,}\s{0,}SET\s{0,}/.exec(ar[ix]))  {
        ar[ix] = ar[ix].replace(/\,/g,",\n"+tab+tab+"")
      }

      if( /\s{0,}\(\s{0,}SELECT\s{0,}/.exec(ar[ix]))  {
        deep++;
        str += shift[deep]+ar[ix];
      } else
      if( /\'/.exec(ar[ix]) )  {
        if(parenthesisLevel<1 && deep) {
          deep--;
        }
        str += ar[ix];
      }
      else  {
        str += shift[deep]+ar[ix];
        if(parenthesisLevel<1 && deep) {
          deep--;
        }
      }
    }

    str = str.replace(/^\n{1,}/,'').replace(/\n{1,}/g,"\n");
    return str;
  }
}

export default SQLFormatter;
