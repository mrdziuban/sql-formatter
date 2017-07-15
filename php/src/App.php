<?php

$sqlFormatter = $require('./SQLFormatter.php');
$defaultSpaces = 2;

class App {
  function __construct() {
    $this->render();
    $this->bindEvents();
  }

  private function render() {
    $document->getElementById("main")->innerHTML = <<<HTML
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
HTML;
  }

  private function updateOutput($output, $input, $spaces) {
    return function() use ($output, $input, $spaces) {
      $output->value = $sqlFormatter->format($input->value, intval($spaces->value));
    };
  }

  private function selectOutput($output) {
    return function() use ($output) {
      $output->select();
    };
  }

  private function bindEvents() {
    $input = $document->getElementById("sql-input");
    $output = $document->getElementById("sql-output");
    $spaces = $document->getElementById("sql-spaces");

    $updater = $this->updateOutput($output, $input, $spaces);
    $selector = $this->selectOutput($output);

    $input->addEventListener("input", $updater);
    $spaces->addEventListener("input", $updater);

    $output->onclick = $selector;
    $output->onfocus = $selector;
  }
}

$module->exports = App;
