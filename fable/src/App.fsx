#r "../../node_modules/fable-core/Fable.Core.dll"

#load "SQLFormatter.fsx"

open Fable.Import.Browser

let render =
  document.getElementById("main").innerHTML <- """
    <div class="container">
      <div class="form-inline mb-3">
        <label for="sql-spaces" class="h4 mr-3">Spaces</label>
        <input id="sql-spaces" class="form-control" type="number" value="2" min="0">
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
  """

let bindEvents =
  let input = document.getElementById("sql-input") :?> HTMLTextAreaElement
  let output = document.getElementById("sql-output") :?> HTMLTextAreaElement
  let spaces = document.getElementById("sql-spaces") :?> HTMLInputElement

  let updateOutput(e: Event):obj =
    output.value <- SQLFormatter.format input.value (int spaces.value)
    null

  let selectOutput(e: Event):obj =
    output.select()
    null

  input.addEventListener_input(System.Func<_,_> updateOutput)
  spaces.addEventListener_input(System.Func<_,_> updateOutput)

  output.onclick <- System.Func<_,_> selectOutput
  output.onfocus <- System.Func<_,_> selectOutput

render
bindEvents
