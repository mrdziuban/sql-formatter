var system = require('system');

var langOverrides = { dart: 'google', rust: 'rust-asmjs' };
var lang = system.env.SQL_FORMATTER_LANG.toLowerCase().trim();
lang = langOverrides[lang] || lang;

var input = "select * from users as u join roles as r on u.id = r.user_id where u.email like '%gmail.com' and u.first_name = 'John';";
var output = function(numSpaces) {
  var tab = Array(numSpaces + 1).join(' ');
  return 'SELECT *\nFROM users AS u\nJOIN roles AS r\n' + tab + 'ON u.id = r.user_id\n' +
         "WHERE u.email LIKE '%gmail.com'\n" + tab + "AND u.first_name = 'John';";
};

casper.test.begin('SQL formatting using ' + lang, 2, function(test) {
  casper.on('page.error', function(msg, trace) {
    casper.echo('Error: ' + msg, 'ERROR');
    casper.echo(trace.map(function(t) {
      return '' + t.file + ':' + t.line + ' in ' + t.function;
    }).join('\n'), 'ERROR');
  });

  var setInput = function(val, id) {
    id = id || 'sql-input';
    casper.evaluate(function(id, val) {
      document.getElementById(id).value = val;
      document.getElementById(id).dispatchEvent(new Event('input'));
    }, id, val);
  };

  var waitForOutput = function(empty, callback) {
    return casper.waitFor(function() {
      return casper.evaluate(function(empty) {
        return empty
          ? document.getElementById('sql-output').value === ''
          : document.getElementById('sql-output').value !== '';
      }, empty);
    }, callback);
  };

  var testOutput = function(msg, expected) {
    test.assertEvalEquals(function() {
      return document.getElementById('sql-output').value;
    }, expected, msg);
  };

  // Test basic SQL formatting
  casper.start('http://localhost:8000/?lang=' + lang, function() {
    casper.waitForSelector('#sql-input', function() {
      setInput(input);
      waitForOutput(false, function() { testOutput('SQL is formatted correctly', output(2)); });
    });
  });

  // Test formatting with 4 spaces
  casper.then(function() {
    setInput('');
    waitForOutput(true, function() {
      setInput(4, 'sql-spaces');
      setInput(input);
      waitForOutput(false, function() { testOutput('SQL is formatted correctly with 4 spaces', output(4)); });
    });
  })

  casper.run(function() { test.done(); });
});
