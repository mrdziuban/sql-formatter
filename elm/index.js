const Elm = require('./src/App');
const app = Elm.App.embed(document.getElementById('main'));
app.ports.selectOutput.subscribe(function() { document.getElementById('sql-output').select(); });
