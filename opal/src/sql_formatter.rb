class SQLFormatter
  SEP = '~::~'

  class << self
    def format(sql, num_spaces)
      tab = ' ' * num_spaces
      split_by_quotes = sql.gsub(/\s+/, ' ').gsub(/'/, "#{SEP}'").split(SEP)
      input = {
        str: '',
        shift_arr: create_shift_arr(tab),
        tab: tab,
        arr: (0...split_by_quotes.length).flat_map { |i| split_if_even(i, split_by_quotes[i], tab) },
        parens_level: 0,
        deep: 0
      }

      len = input[:arr].length
      output = (0...len).reduce(input) do |acc, i|
        original_el = acc[:arr][i]
        parens_level = subquery_level(original_el, acc[:parens_level])
        arr = !!(original_el =~ /SELECT|SET/) ?
                (acc[:arr][0...i] << original_el.gsub(/,\s+/, ",\n#{acc[:tab] * 2}")) + acc[:arr][(i + 1)..-1] :
                acc[:arr].dup
        el = arr[i]
        out = update_output(el, parens_level, acc, i)

        acc.merge(str: out[0], arr: arr, parens_level: parens_level, deep: out[1])
      end

      output[:str].gsub(/\s+\n/, "\n").gsub(/\n+/, "\n").strip
    end

    def update_output(el, parens_level, acc, i)
      !!(el =~ /\(\s*SELECT/) ?
        [acc[:str] + acc[:shift_arr][acc[:deep] + 1] + el, acc[:deep] + 1] :
        [
          !!(el =~ /'/) ? acc[:str] + el : acc[:str] + acc[:shift_arr][acc[:deep]] + el,
          (parens_level < 1 && acc[:deep] != 0) ? acc[:deep] - 1 : acc[:deep]
        ]
    end

    def create_shift_arr(space)
      (0..99).reduce([]) { |acc, i| acc << "\n#{space * i}" }
    end

    def subquery_level(str, level)
      level - (str.gsub(/\(/, '').length - str.gsub(/\)/, '').length)
    end

    def all_replacements(tab)
      [
        [/ AND /i,                              SEP + tab + 'AND '],
        [/ BETWEEN /i,                          SEP + tab + 'BETWEEN '],
        [/ CASE /i,                             SEP + tab + 'CASE '],
        [/ ELSE /i,                             SEP + tab + 'ELSE '],
        [/ END /i,                              SEP + tab + 'END '],
        [/ FROM /i,                             SEP + 'FROM '],
        [/ GROUP\s+BY /i,                       SEP + 'GROUP BY '],
        [/ HAVING /i,                           SEP + 'HAVING '],
        [/ IN /i,                               ' IN '],
        [/ ((CROSS|INNER|LEFT|RIGHT) )?JOIN /i, lambda { |_| (SEP + ($1 || '') + 'JOIN ').upcase }],
        [/ ON /i,                               SEP + tab + 'ON '],
        [/ OR /i,                               SEP + tab + 'OR '],
        [/ ORDER\s+BY /i,                       SEP + 'ORDER BY '],
        [/ OVER /i,                             SEP + tab + 'OVER '],
        [/\(\s*SELECT /i,                       SEP + '(SELECT '],
        [/\)\s*SELECT /i,                       ')' + SEP + 'SELECT '],
        [/ THEN /i,                             ' THEN' + SEP + tab],
        [/ UNION /i,                            SEP + 'UNION' + SEP],
        [/ USING /i,                            SEP + 'USING '],
        [/ WHEN /i,                             SEP + tab + 'WHEN '],
        [/ WHERE /i,                            SEP + 'WHERE '],
        [/ WITH /i,                             SEP + 'WITH '],
        [/ SET /i,                              SEP + 'SET '],
        [/ ALL /i,                              ' ALL '],
        [/ AS /i,                               ' AS '],
        [/ ASC /i,                              ' ASC '],
        [/ DESC /i,                             ' DESC '],
        [/ DISTINCT /i,                         ' DISTINCT '],
        [/ EXISTS /i,                           ' EXISTS '],
        [/ NOT /i,                              ' NOT '],
        [/ NULL /i,                             ' NULL '],
        [/ LIKE /i,                             ' LIKE '],
        [/\s*SELECT /i,                         'SELECT '],
        [/\s*UPDATE /i,                         'UPDATE '],
        [/\s*DELETE /i,                         'DELETE '],
        [Regexp.new("(#{SEP})+"),               SEP]
      ]
    end

    def split_sql(str, tab)
      all_replacements(tab).reduce(str.gsub(/\s+/, ' ')) do |acc, r|
        acc.gsub(r[0]) { |m| r[1].is_a?(Proc) ? r[1].call(m) : r[1] }
      end.split(SEP)
    end

    def split_if_even(i, str, tab)
      i % 2 == 0 ? split_sql(str, tab) : [str]
    end
  end
end
