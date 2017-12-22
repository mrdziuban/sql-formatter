module App (main) where

import Prelude ((>>>), (>>=), (<>), bind, discard, pure, unit, Unit)
import Control.Monad.Eff (Eff)
import Data.Int (fromString)
import Data.Maybe (fromMaybe, Maybe, maybe)
import DOM (DOM)
import DOM.Event.Types (Event)
import DOM.HTML (window)
import DOM.HTML.Types (htmlDocumentToParentNode)
import DOM.HTML.Window (document)
import DOM.Node.ParentNode (QuerySelector(..), querySelector)
import DOM.Node.Types (Element)

import SQLFormatter (formatSql)

foreign import setInnerHTML :: forall a. String -> Element -> Eff (dom :: DOM | a) Unit
foreign import selectElement :: Element -> Event -> Unit
foreign import getValue :: Element -> String
foreign import setValue :: Element -> String -> Unit
foreign import addEventListener :: String -> (Event -> Unit) -> Element -> Unit

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
  querySelector (QuerySelector ("#" <> id_)) doc

render :: forall a. Eff (dom :: DOM | a) Unit
render =
  getElementById "main" >>= maybe (pure unit) (setInnerHTML view)

updateOutput :: Element -> Element -> Element -> Event -> Unit
updateOutput inp out spaces _ =
  setValue out (formatSql (getValue inp) (fromMaybe defaultSpaces (fromString (getValue spaces))))

bindInputs :: forall a. Eff (dom :: DOM | a) Unit
bindInputs = do
  inp <- getElementById "sql-input"
  out <- getElementById "sql-output"
  spaces <- getElementById "sql-spaces"
  maybe
    (pure unit)
    (\i -> maybe
            (pure unit)
            (\o -> maybe
                    (pure unit)
                    (\s -> do
                      pure (addEventListener "input" (updateOutput i o s) i)
                      pure (addEventListener "input" (updateOutput i o s) s)
                      pure (addEventListener "click" (selectElement o) o)
                      pure (addEventListener "focus" (selectElement o) o))
                    spaces)
            out)
    inp

main :: forall a. Eff (dom :: DOM | a) Unit
main = do
  render
  bindInputs
