package main

import (
	"strconv"

	"github.com/gopherjs/gopherjs/js"
)

func main() {
	render()
	bindEvents()
}

func render() {
	js.Global.Get("document").Call("getElementById", "main").Set("innerHTML", `
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
	`)
}

func updateOutput(input *js.Object, output *js.Object, spaces *js.Object) func() {
	return func() {
		spacesStr := spaces.Get("value").String()
		spacesInt, err := strconv.Atoi(spacesStr)
		if err != nil { spacesInt = 2 }
		output.Set("value", formatSql(input.Get("value").String(), spacesInt))
	}
}

func seletOutput(output *js.Object) func() {
	return func() { output.Call("select") }
}

func bindEvents() {
	input := js.Global.Get("document").Call("getElementById", "sql-input")
	output := js.Global.Get("document").Call("getElementById", "sql-output")
	spaces := js.Global.Get("document").Call("getElementById", "sql-spaces")

	input.Call("addEventListener", "input", updateOutput(input, output, spaces))
	spaces.Call("addEventListener", "input", updateOutput(input, output, spaces))

	output.Set("onclick", seletOutput(output))
	output.Set("onfocus", seletOutput(output))
}
