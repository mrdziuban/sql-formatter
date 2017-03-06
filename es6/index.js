import 'babel-polyfill';
import formatSql from './sql-formatter';

const defaultSpaces = 2;

(() => {
  document.getElementById('main').innerHTML = `
    <div class="container">
      <div class="form-inline mb-3">
        <label for="sql-spaces" class="h4 mr-3">Spaces</label>
        <input id="sql-spaces" class="form-control" type="number" value="${defaultSpaces}" min="0">
      </div>
      <div class="form-group">
        <label for="sql-input" class="d-flex h4 mb-3">Input</label>
        <textarea id="sql-input" class="form-control code" placeholder="Enter SQL" rows="9"></textarea>
      </div>
      <div class="form-group">
        <label for="sql-output" class="d-flex h4 mb-3">Output</label>
        <textarea id="sql-output" class="form-control code" rows="20" readonly></textarea>
      </div>
    </div>
  `;

  const input = document.getElementById('sql-input');
  const output = document.getElementById('sql-output');
  const spaces = document.getElementById('sql-spaces');

  const updateOutput = () => output.value = formatSql(input.value, parseInt(spaces.value) || defaultSpaces);
  const selectOutput = () => output.select();

  input.addEventListener('input', updateOutput);
  spaces.addEventListener('input', updateOutput);

  output.onclick = selectOutput;
  output.onfocus = selectOutput;
})();
