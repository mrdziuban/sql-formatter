import SQLFormatter from './sql-formatter';

(function() {
  document.addEventListener('DOMContentLoaded', () => {
    const input = document.getElementById('sql-input');
    const output = document.getElementById('sql-output');
    input.oninput = () => output.value = SQLFormatter.format(input.value);
  });
})();
