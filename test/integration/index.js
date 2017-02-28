var system = require('system');

var langOverrides = { dart: 'google' };
var lang = system.env.SQL_FORMATTER_LANG.toLowerCase().trim();
lang = langOverrides[lang] || lang;

var input = "select * from users as u join roles as r on u.id = r.user_id where u.email like '%gmail.com' and u.first_name = 'John';";
var output = "SELECT *\nFROM users AS u\nJOIN roles AS r\n  ON u.id = r.user_id\nWHERE u.email LIKE '%gmail.com'\n  AND u.first_name = 'John';"

casper.test.begin('SQL formatting using ' + lang, 1, function(test) {
  casper.on('page.error', function(msg, trace) {
    casper.echo('Error: ' + msg, 'ERROR');
    casper.echo(trace.map(function(t) {
      return '' + t.file + ':' + t.line + ' in ' + t.function;
    }).join('\n'), 'ERROR');
  });

  casper.start('http://localhost:8000/?lang=' + lang, function() {
    casper.waitForSelector('#sql-input', function() {
      casper.evaluate(function(input) {
        document.getElementById('sql-input').value = input;
        document.getElementById('sql-input').dispatchEvent(new Event('input'));
      }, input);

      casper.waitFor(function() {
        return casper.evaluate(function() {
          return document.getElementById('sql-output').value !== '';
        });
      }, function() {
        test.assertEvalEquals(function() {
          return document.getElementById('sql-output').value;
        }, output, 'SQL is formatted correctly');
      });
    });
  });

  casper.run(function() { test.done(); });
});
