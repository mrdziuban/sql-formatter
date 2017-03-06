module App (main) where

import Prelude ((>>>), (>>=), (<>), bind, pure, unit, Unit)
import Control.Monad.Eff (Eff)
import Data.Int (fromString)
import Data.Maybe (fromMaybe, Maybe, maybe)
import Data.Nullable (toMaybe)
import DOM (DOM)
import DOM.Event.EventTarget (addEventListener, eventListener)
import DOM.Event.Types (Event)
import DOM.HTML.Event.EventTypes (click, focus, input)
import DOM.HTML (window)
import DOM.HTML.Types (htmlDocumentToParentNode)
import DOM.HTML.Window (document)
import DOM.Node.ParentNode (querySelector)
import DOM.Node.Types (Element, elementToEventTarget)

import SQLFormatter (formatSql)

foreign import selectElement :: forall a. Element -> Event -> Eff (dom:: DOM | a) Unit
foreign import setInnerHTML :: forall a. String -> Element -> Eff (dom :: DOM | a) Unit
foreign import getValue :: forall a. Element -> Eff (dom :: DOM | a) String
foreign import setValue :: forall a. Element -> String -> Eff (dom :: DOM | a) Unit

defaultSpaces :: Int
defaultSpaces = 2

view :: String
view =
  """
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
      <textarea id="sql-output" class="form-control code mb-3" rows="20" readonly></textarea>
    </div>
  </div>
  """

getElementById :: forall a. String -> Eff (dom :: DOM | a) (Maybe Element)
getElementById id_ = do
  doc <- window >>= document >>= htmlDocumentToParentNode >>> pure
  querySelector ("#" <> id_) doc >>= toMaybe >>> pure

render :: forall a. Eff (dom :: DOM | a) Unit
render =
  getElementById "main" >>= maybe (pure unit) (setInnerHTML view)

updateOutput :: forall a. Element -> Element -> Element -> Event -> Eff (dom :: DOM | a) Unit
updateOutput inp out spaces _ = do
  val <- getValue inp
  spacesStr <- getValue spaces
  setValue out (formatSql val (fromMaybe defaultSpaces (fromString spacesStr)))

bindInputs :: forall a. Eff (dom :: DOM | a) Unit
bindInputs = do
  inp <- getElementById "sql-input"
  out <- getElementById "sql-output"
  spaces <- getElementById "sql-spaces"
  _ <- maybe
        (pure unit)
        (\i -> maybe
                (pure unit)
                (\o -> maybe
                        (pure unit)
                        (\s -> do
                          addEventListener input (eventListener (updateOutput i o s)) false (elementToEventTarget i)
                          addEventListener input (eventListener (updateOutput i o s)) false (elementToEventTarget s)
                          addEventListener click (eventListener (selectElement o)) false (elementToEventTarget o)
                          addEventListener focus (eventListener (selectElement o)) false (elementToEventTarget o))
                        spaces)
                out)
        inp
  pure unit

main :: forall a. Eff (dom :: DOM | a) Unit
main = do
  render
  bindInputs
