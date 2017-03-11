require('rust-emscripten-loader?target=wasm&outName=js/rust-wasm/out!./src/main');

const script = document.createElement('script');
script.text = `
  if (typeof WebAssembly === 'object') {
    var Module = {};
    var req = new XMLHttpRequest();
    req.open('GET', '/js/rust-wasm/out.wasm');
    req.responseType = 'arraybuffer';
    req.send();

    req.onload = function() {
      Module.wasmBinary = req.response;
      var script = document.createElement('script');
      script.src = '/js/rust-wasm/out.js';
      document.body.appendChild(script);
    };
  } else {
    document.getElementById('main').innerHTML = '<div class="container text-center">' +
        '<h2 class="text-danger mt-3 mb-4">Your browser doesn\\'t support WebAssembly!</h2>' +
        '<h5 class="text-center">' +
          'Check out the ' +
          '<a href="http://webassembly.org/roadmap/" target="_blank">WebAssembly roadmap</a> ' +
          'and the <a href="http://caniuse.com/#feat=wasm" target="_blank">currently supported browsers</a>.'
        '</h5>' +
      '</div>';
  }
`;
document.body.appendChild(script);
