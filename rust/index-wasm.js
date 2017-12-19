require('rust-emscripten-loader?target=wasm&outName=js/rust-wasm/out!./src/main');

const script = document.createElement('script');
script.text = `
  if (typeof WebAssembly === 'object') {
    fetch('js/rust-wasm/out.wasm')
      .then(response => response.arrayBuffer())
      .then(buffer => WebAssembly.compile(buffer))
      .then(module => {
        // Create the imports for the module, including the
        // standard dynamic library imports
        const imports = {};
        imports.env = imports.env || { emscripten_asm_const_int: function() {}, free: function() {} };
        imports.env.memoryBase = imports.env.memoryBase || 0;
        imports.env.tableBase = imports.env.tableBase || 0;
        imports.env.memory = new WebAssembly.Memory({ initial: 4096, maximum: 65536 });
        imports.env.table = new WebAssembly.Table({ initial: 0, element: 'anyfunc', maximum: 1000000 });
        // Create the instance.
        return WebAssembly.instantiate(module, imports);
      });

    //var Module = {};
    //var req = new XMLHttpRequest();
    //req.open('GET', 'js/rust-wasm/out.wasm');
    //req.responseType = 'arraybuffer';
    //req.send();
//
//    //req.onload = function() {
//    //  WebAssembly.compile(req.response)
//    //    .then(mod => WebAssembly.instantiate(mod, { env: { error: function() {}, emscripten_asm_const_int: function() {}, free: function() {} } }))
//    //    .then(inst => { debugger; });
    //};
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
