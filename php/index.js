import PHP from 'phpvm';
import sqlFormatter from './src/SQLFormatter';

const defaultSpaces = 2;

(() => {
  document.getElementById('main').innerHTML = new PHP(require('./src/App'), { cfgFile: false }).vm.OUTPUT_BUFFER;

  const input = document.getElementById('sql-input');
  const output = document.getElementById('sql-output');
  const spaces = document.getElementById('sql-spaces');

  let updTimeout;
  const updateOutput = () => {
    clearInterval(updTimeout);
    updTimeout = setTimeout(() => {
      const sql = input.value.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
      const numSpaces = parseInt(spaces.value) || defaultSpaces;
      const php = new PHP(
        `${sqlFormatter}\n\necho (new SQLFormatter)->format('${sql}', ${numSpaces});`,
        { cfgFile: false }
      );
      output.value = php.vm.OUTPUT_BUFFER;
    }, 50);
  };
  const selectOutput = () => output.select();

  input.addEventListener('input', updateOutput);
  spaces.addEventListener('input', updateOutput);

  output.onclick = selectOutput;
  output.onfocus = selectOutput;
})();
