var Elm = require('./App.elm');
var app = Elm.App.embed(document.getElementById('elm'));
app.ports.selectOutput.subscribe(function() { document.getElementById('sql-output').select(); });
