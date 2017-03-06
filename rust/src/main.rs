extern crate libc;
#[cfg(test)] extern crate regex;
#[macro_use] extern crate webplatform;

mod regex_fns;
mod sql_formatter;

use std::rc::Rc;
use webplatform::HtmlNode;

macro_rules! enclose {
    ( ($( $x:ident ),*) $y:expr ) => {
        {
            $(let $x = $x.clone();)*
            $y
        }
    };
}

fn main() {
    let document = webplatform::init();

    document.element_query("#main").unwrap().html_set("
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
    ");

    let input = Rc::new(document.element_query("#sql-input").unwrap());
    let output = Rc::new(document.element_query("#sql-output").unwrap());
    let spaces = Rc::new(document.element_query("#sql-spaces").unwrap());

    input.on("input", enclose! { (input, output, spaces) move |_| { update_output(&input, &output, &spaces) } });
    spaces.on("input", enclose! { (input, output, spaces) move |_| { update_output(&input, &output, &spaces) } });

    output.on("click", enclose! { (output) move |_| output.call("select") });
    output.on("focus", enclose! { (output) move |_| output.call("select") });

    webplatform::spin();
}

fn update_output(input: &Rc<HtmlNode>, output: &Rc<HtmlNode>, spaces: &Rc<HtmlNode>) {
    output.prop_set_str("value", &sql_formatter::format(input.prop_get_str("value"), spaces.prop_get_i32("value")));
}
