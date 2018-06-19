open Tea.App;
open Tea.Html;

type model = {
  input: string,
  output: string,
  spaces: int
};

let init = {
  input: "",
  output: "",
  spaces: 2
};

[@bs.deriving { accessors: accessors }]
type msg =
  | Input(string)
  | Spaces(string)
  | Select;

let update = model =>
  fun
  | Input(v) => { ...model, input: v, output: SqlFormatter.format(v, model.spaces) }
  | Spaces(v) => { ...model, spaces: int_of_string(v), output: SqlFormatter.format(model.input, int_of_string(v)) }
  | Select => {
      ignore([%raw "document.getElementById(\"sql-output\").select()"]);
      model
    };

let view = model =>
  div(
    [class'("container")],
    [
      div(
        [class'("form-inline mb-3")],
        [
          label([for'("sql-spaces"), class'("h4 mr-3")], [text("Spaces")]),
          input'(
            [
              id("sql-spaces"),
              class'("form-control"),
              type'("number"),
              value(string_of_int(model.spaces)),
              onInput(v => Spaces(v))
            ],
            []
          )
        ]
      ),
      div(
        [class'("form-group")],
        [
          label([for'("sql-input"), class'("d-flex h4 mb-3")], [text("Input")]),
          textarea(
            [
              id("sql-input"),
              class'("form-control code"),
              placeholder("Enter SQL"),
              Vdom.prop("rows", "9"),
              onInput(v => Input(v))
            ],
            [text(model.input)]
          )
        ]
      ),
      div(
        [class'("form-group")],
        [
          label([for'("sql-output"), class'("d-flex h4 mb-3")], [text("Output")]),
          textarea(
            [
              id("sql-output"),
              class'("form-control code"),
              Vdom.prop("rows", "20"),
              Vdom.prop("readOnly", "true"),
              onClick(Select),
              onFocus(Select)
            ],
            [text(model.output)]
          )
        ]
      )
    ]
  );

let main = beginnerProgram({ model: init, update, view });
