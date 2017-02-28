var Elm = require('./src/App.elm');
var app = Elm.App.embed(document.getElementById('main'));
app.ports.selectOutput.subscribe(function() { document.getElementById('sql-output').select(); });
