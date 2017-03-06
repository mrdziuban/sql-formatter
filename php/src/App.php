<?php

echo '<div class="container">'
  . '<div class="form-inline mb-3">'
    . '<label for="sql-spaces" class="h4 mr-3">Spaces</label>'
    . '<input id="sql-spaces" class="form-control" type="number" value="2" min="0">'
  . '</div>'
  . '<div class="form-group">'
    . '<label for="sql-input" class="d-flex h4 mb-3">Input</label>'
    . '<textarea id="sql-input" class="form-control code" placeholder="Enter SQL" rows="9"></textarea>'
  . '</div>'
  . '<div class="form-group">'
    . '<label for="sql-output" class="d-flex h4 mb-3">Output</label>'
    . '<textarea id="sql-output" class="form-control code" rows="20" readonly></textarea>'
  . '</div>'
. '</div>';
