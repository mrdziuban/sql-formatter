require 'sql_formatter'

describe SQLFormatter do
  TABBED_KEYWORDS = [
    'AND',
    'BETWEEN',
    'CASE',
    'ELSE',
    'END',
    'ON',
    'OR',
    'OVER',
    'WHEN'
  ]

  UNTABBED_KEYWORDS = [
    'FROM',
    'GROUP BY',
    'HAVING',
    'JOIN',
    'CROSS JOIN',
    'INNER JOIN',
    'LEFT JOIN',
    'RIGHT JOIN',
    'ORDER BY',
    'WHERE',
    'WITH',
    'SET'
  ]

  UNCHANGED_KEYWORDS = [
    'IN',
    'ALL',
    'AS',
    'ASC',
    'DESC',
    'DISTINCT',
    'EXISTS',
    'NOT',
    'NULL',
    'LIKE'
  ]

  describe '#format' do
    describe 'tabbed keywords' do
      TABBED_KEYWORDS.each do |word|
        it "formatting of '#{word}'" do
          expect(SQLFormatter.format("foo #{word} bar", 2)).to equal("foo\n  #{word} bar")
        end
      end
    end

    describe 'untabbed keywords' do
      UNTABBED_KEYWORDS.each do |word|
        it "formatting of '#{word}'" do
          expect(SQLFormatter.format("foo #{word} bar", 2)).to equal("foo\n#{word} bar")
        end
      end
    end

    describe 'unchanged keywords' do
      UNCHANGED_KEYWORDS.each do |word|
        it "formatting of '#{word}'" do
          expect(SQLFormatter.format("foo #{word} bar", 2)).to equal("foo #{word} bar")
        end
      end
    end

    describe 'SELECTs' do
      it "formatting of 'SELECT'" do
        expect(SQLFormatter.format('SELECT foo bar', 2)).to equal("SELECT foo bar")
      end

      it "formatting of ' SELECT'" do
        expect(SQLFormatter.format(' SELECT foo bar', 2)).to equal("SELECT foo bar")
      end

      it "formatting of '(SELECT'" do
        expect(SQLFormatter.format('foo (SELECT bar', 2)).to equal("foo\n  (SELECT bar")
      end

      it "formatting of '( SELECT'" do
        expect(SQLFormatter.format('foo ( SELECT bar', 2)).to equal("foo\n  (SELECT bar")
      end

      it "formatting of ') SELECT'" do
        expect(SQLFormatter.format('foo) SELECT bar', 2)).to equal("foo)\nSELECT bar")
      end

      it "formatting of ')SELECT'" do
        expect(SQLFormatter.format('foo)SELECT bar', 2)).to equal("foo)\nSELECT bar")
      end

      it "Formatting when selecting multiple fields" do
        expect(SQLFormatter.format('SELECT foo, bar, baz', 2)).to equal("SELECT foo,\n    bar,\n    baz")
      end
    end

    describe 'UPDATEs' do
      it "formatting of 'UPDATE'" do
        expect(SQLFormatter.format('UPDATE foo bar', 2)).to equal('UPDATE foo bar')
      end

      it "formatting of ' UPDATE'" do
        expect(SQLFormatter.format(' UPDATE foo bar', 2)).to equal('UPDATE foo bar')
      end
    end

    describe 'DELETEs' do
      it "formatting of 'DELETE'" do
        expect(SQLFormatter.format('DELETE foo bar', 2)).to equal('DELETE foo bar')
      end

      it "formatting of ' DELETE'" do
        expect(SQLFormatter.format(' DELETE foo bar', 2)).to equal('DELETE foo bar')
      end
    end

    describe 'special case keywords' do
      it "formatting of 'THEN'" do
        expect(SQLFormatter.format('foo THEN bar', 2)).to equal("foo THEN\n  bar")
      end

      it "formatting of 'UNION'" do
        expect(SQLFormatter.format('foo UNION bar', 2)).to equal("foo\nUNION\nbar")
      end

      it "formatting of 'USING'" do
        expect(SQLFormatter.format('foo USING bar', 2)).to equal("foo\nUSING bar")
      end
    end

    describe 'nested queries' do
      it 'formatting of single nested query' do
        expect(
          SQLFormatter.format('SELECT foo FROM (SELECT bar FROM baz)', 2)
        ).to equal("SELECT foo\nFROM\n  (SELECT bar\n  FROM baz)")
      end

      it 'formatting of multiple nested queries' do
        expect(
          SQLFormatter.format('SELECT foo FROM (SELECT bar FROM (SELECT baz FROM quux))', 2)
        ).to equal("SELECT foo\nFROM\n  (SELECT bar\n  FROM\n    (SELECT baz\n    FROM quux))")
      end
    end

    describe 'case transformations' do
      (TABBED_KEYWORDS + UNTABBED_KEYWORDS + UNCHANGED_KEYWORDS + ['SELECT', 'UPDATE', 'THEN', 'UNION', 'USING']).each do |word|
        it "upcasing of #{word}" do
          expect(SQLFormatter.format(" #{word.downcase} ", 2).strip).to equal(word)
        end
      end
    end

    {
      'formatting full queries' => 2,
      'formatting queries with a different number of spaces' => 4
    }.each do |desc, num_spaces|
      tab = ' ' * num_spaces

      describe desc do
        it 'formatting a full SELECT query' do
          expect(
            SQLFormatter.format('SELECT a.b, c.d FROM a JOIN b on a.b = c.d WHERE a.b = 1 AND c.d = 1', num_spaces)
          ).to equal("SELECT a.b,\n#{tab}#{tab}c.d\nFROM a\nJOIN b\n#{tab}ON a.b = c.d\nWHERE a.b = 1\n#{tab}AND c.d = 1")
        end

        it 'formatting a full UPDATE query' do
          expect(
            SQLFormatter.format('UPDATE a SET a.b = 1, a.c = 2 WHERE a.d = 3', num_spaces)
          ).to equal("UPDATE a\nSET a.b = 1,\n#{tab}#{tab}a.c = 2\nWHERE a.d = 3")
        end

        it 'formatting a full DELETE query' do
          expect(
            SQLFormatter.format('DELETE FROM a WHERE a.b = 1 AND a.c = 2', num_spaces)
          ).to equal("DELETE\nFROM a\nWHERE a.b = 1\n#{tab}AND a.c = 2")
        end
      end
    end
  end
end
