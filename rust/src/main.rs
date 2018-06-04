extern crate regex;
extern crate stdweb;
#[macro_use] extern crate yew;

mod regex_fns;
mod sql_formatter;

use stdweb::web::{document, IParentNode};
use yew::prelude::*;

type Context = ();

struct Model {
    input: String,
    spaces: i64
}

enum Msg {
    Input(String),
    Spaces(i64)
}

impl Component<Context> for Model {
    type Message = Msg;
    type Properties = ();

    fn create(_: Self::Properties, _: &mut Env<Context, Self>) -> Self {
        Model {
            input: String::from(""),
            spaces: 2
        }
    }

    fn update(&mut self, msg: Self::Message, _: &mut Env<Context, Self>) -> ShouldRender {
        match msg {
            Msg::Input(v) => { self.input = v; }
            Msg::Spaces(v) => { self.spaces = v; }
        }
        true
    }
}

impl Renderable<Context, Model> for Model {
    fn view(&self) -> Html<Context, Self> {
        html! {
            <div class="container",>
                <div class=("form-inline", "mb-3"),>
                    <label for="sql-spaces", class=("h4", "mr-3"),>{ "Spaces" }</label>
                    <input
                        id="sql-spaces",
                        class="form-control",
                        type="number",
                        value={ self.spaces },
                        min="0",
                        oninput=|e| Msg::Spaces(e.value.parse::<i64>().unwrap()),
                    />
                </div>
                <div class="form-group",>
                    <label for="sql-input", class=("d-flex", "h4", "mb-3"),>{ "Input" }</label>
                    <textarea
                        id="sql-input",
                        class=("form-control", "code"),
                        placeholder="Enter SQL",
                        rows="9",
                        oninput=|e| Msg::Input(e.value),
                    >
                        { &self.input }
                    </textarea>
                </div>
                <div class="form-group",>
                    <label for="sql-output", class=("d-flex", "h4", "mb-3"),>{ "Output" }</label>
                    <textarea
                        id="sql-output",
                        class=("form-control", "code"),
                        rows="20",
                        readonly="readonly",
                    >
                        { sql_formatter::format(&self.input, &self.spaces) }
                    </textarea>
                </div>
            </div>
        }
    }
}

fn main() {
    yew::initialize();
    let app: App<_, Model> = App::new(());
    let element = document().query_selector("#main").unwrap().unwrap();
    app.mount(element);
    yew::run_loop();
}
