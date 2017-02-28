import 'dart:html';

import 'sql_formatter.dart';

void main() {
  render();
  bindEvents();
}

void render() {
  querySelector('#main').innerHtml = '''
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
  ''';
}

Function updateOutput(TextAreaElement input, TextAreaElement output, InputElement spaces) {
  return (Event _e) => output.value = SQLFormatter.format(input.value, int.parse(spaces.value));
}

Function selectOutput(TextAreaElement output) => (Event _e) => output.select();

void bindEvents() {
  TextAreaElement input = querySelector("#sql-input");
  TextAreaElement output = querySelector("#sql-output");
  InputElement spaces = querySelector("#sql-spaces");

  input.onInput.listen(updateOutput(input, output, spaces));
  spaces.onInput.listen(updateOutput(input, output, spaces));

  output.onClick.listen(selectOutput(output));
  output.onFocus.listen(selectOutput(output));
}
