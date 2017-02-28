require('../css/index.scss');
var Elm = require('./src/App.elm');
var app = Elm.App.embed(document.getElementById('elm'));
app.ports.selectOutput.subscribe(function() { document.getElementById('sql-output').select(); });
