package mrdziuban.sqlFormatter

import org.scalajs.dom.document
import org.scalajs.dom.html.{Input, TextArea}
import org.scalajs.dom.raw.{Event, FocusEvent}
import scala.scalajs.js.JSApp

object App extends JSApp {
  val defaultSpaces = 2

  def main(): Unit = {
    render
    withEls(bindEvents)
    ()
  }

  private def render(): Unit =
    document.getElementById("main").innerHTML = s"""
      <div class="container">
        <div class="form-inline mb-3">
          <label for="sql-spaces" class="h4 mr-3">Spaces</label>
          <input id="sql-spaces" class="form-control" type="number" value="$defaultSpaces" min="0">
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

  private def withEls[A](fn: (TextArea, TextArea, Input) => A): A =
    fn(document.getElementById("sql-input").asInstanceOf[TextArea],
       document.getElementById("sql-output").asInstanceOf[TextArea],
       document.getElementById("sql-spaces").asInstanceOf[Input])

  private def getSpaces(spaces: Input): Int =
    try { spaces.value.toInt } catch { case _: Exception => defaultSpaces }

  private def updateOutput(input: TextArea, output: TextArea, spaces: Input)(e: Event): Unit =
    output.value = SQLFormatter.format(input.value, getSpaces(spaces))

  private def selectOutput(output: TextArea)(e: Event): Unit = {
    output.dispatchEvent(new FocusEvent)
    document.getSelection.selectAllChildren(output)
  }

  private def bindEvents(input: TextArea, output: TextArea, spaces: Input): Unit = {
    input.addEventListener("input", updateOutput(input, output, spaces))
    spaces.addEventListener("input", updateOutput(input, output, spaces))

    output.addEventListener("click", selectOutput(output))
  }
}
