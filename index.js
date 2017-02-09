const Elm = require('./App.elm');
const app = Elm.App.embed(document.getElementById('elm'));
app.ports.selectOutput.subscribe(function() { document.getElementById('sql-output').select(); });
