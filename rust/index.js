const waitForOutput = cb => {
  let interval;

  const retry = () => {
    const output = document.getElementById('sql-output');
    if (!!output) {
      cancelAnimationFrame(interval);
      cb(output);
    } else {
      interval = requestAnimationFrame(retry);
    }
  };

  interval = requestAnimationFrame(retry);
};

if (typeof WebAssembly === 'object') {
  require('./target/wasm32-unknown-unknown/release/sql-formatter');

  waitForOutput(output => {
    const selectOutput = () => document.getElementById('sql-output').select();
    output.onclick = selectOutput;
    output.onfocus = selectOutput;
  });
} else {
  document.getElementById('main').innerHTML =
    '<div class="container text-center">' +
      '<h2 class="text-danger mt-3 mb-4">Your browser doesn\'t support WebAssembly!</h2>' +
      '<h5 class="text-center">' +
        'Check out the ' +
        '<a href="http://webassembly.org/roadmap/" target="_blank">WebAssembly roadmap</a> ' +
        'and the <a href="http://caniuse.com/#feat=wasm" target="_blank">currently supported browsers</a>.'
      '</h5>' +
    '</div>';
}
