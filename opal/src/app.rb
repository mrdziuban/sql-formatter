require 'opal/mini'
require 'native'

require 'sql_formatter'

class App
  class << self
    attr_accessor :input, :output, :spaces

    def main
      render
      memoize_els
      bind_events
    end

    def render
      $$.document.getElementById('main').innerHTML = <<-EOT
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
      EOT
    end

    def memoize_els
      self.input = $$.document.getElementById('sql-input')
      self.output = $$.document.getElementById('sql-output')
      self.spaces = $$.document.getElementById('sql-spaces')
    end

    def update_output
      output.value = SQLFormatter.format(input.value, spaces.value.to_i < 0 ? 0 : spaces.value.to_i)
    end

    def select_output
      output.select
    end

    def bind_events
      input.addEventListener('input') { update_output }
      spaces.addEventListener('input') { update_output }

      output.addEventListener('click') { select_output }
      output.addEventListener('focus') { select_output }
    end
  end
end

App.main
