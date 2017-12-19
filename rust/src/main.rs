extern crate regex;
#[macro_use] extern crate stdweb;

mod regex_fns;
mod sql_formatter;

use stdweb::web::{document, Element, IEventTarget};
use stdweb::web::event::{ClickEvent, FocusEvent, InputEvent};

macro_rules! enclose {
    ( ($( $x:ident ),*) $y:expr ) => {
        {
            $(let $x = $x.clone();)*
            $y
        }
    };
}

fn main() {
    stdweb::initialize();

    let main = document().query_selector("#main").unwrap();
    let html = "
        <div class=\"container\">
            <div class=\"form-inline mb-3\">
                <label for=\"sql-spaces\" class=\"h4 mr-3\">Spaces</label>
                <input id=\"sql-spaces\" class=\"form-control\" type=\"number\" value=\"2\" min=\"0\">
            </div>
            <div class=\"form-group\">
                <label for=\"sql-input\" class=\"d-flex h4 mb-3\">Input</label>
                <textarea id=\"sql-input\" class=\"form-control code\" placeholder=\"Enter SQL\" rows=\"9\"></textarea>
            </div>
            <div class=\"form-group\">
                <label for=\"sql-output\" class=\"d-flex h4 mb-3\">Output</label>
                <textarea id=\"sql-output\" class=\"form-control code\" rows=\"20\" readonly></textarea>
            </div>
        </div>
    ";
    js! { @(no_return) @{main}.innerHTML = @{html}; };

    let input = document().query_selector("#sql-input").unwrap();
    let output = document().query_selector("#sql-output").unwrap();
    let spaces = document().query_selector("#sql-spaces").unwrap();

    input.add_event_listener(enclose! { (input, output, spaces) move |_: InputEvent| { update_output(&input, &output, &spaces) } });
    spaces.add_event_listener(enclose! { (input, output, spaces) move |_: InputEvent| { update_output(&input, &output, &spaces) } });

    output.add_event_listener(enclose! { (output) move |_: ClickEvent| { js! { @(no_return) @{&output}.select(); } } });
    output.add_event_listener(enclose! { (output) move |_: FocusEvent| { js! { @(no_return) @{&output}.select(); } } });

    stdweb::event_loop();
}

fn update_output(input: &Element, output: &Element, spaces: &Element) {
    let input_val: String = js! { return @{input}.value; }.into_string().unwrap();
    let spaces_val: String = js! { return @{spaces}.value; }.into_string().unwrap();
    let formatted = &sql_formatter::format(input_val, spaces_val.parse::<i32>().unwrap());
    js! { @(no_return) @{output}.value = @{formatted}; }
}
