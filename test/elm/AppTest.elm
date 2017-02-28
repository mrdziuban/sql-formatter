module AppTest exposing (all)

import Test exposing (..)
import Expect

import App

initModel: App.Model
initModel = Tuple.first App.init

modelWithQuery: App.Model
modelWithQuery =
  let
    model = Tuple.first App.init
  in
    { model | input = "SELECT * FROM a JOIN b ON c = d" }

testInitialModelAttribute: String -> (App.Model -> a) -> a -> Test
testInitialModelAttribute attr getAttr expected =
  test ("initial value of model " ++ attr) <|
    \() -> Expect.equal expected (getAttr initModel)

testUpdatedModelAttributeCustom: String -> App.Model -> (App.Model -> a) -> App.Msg -> a -> Test
testUpdatedModelAttributeCustom attr model getAttr msg expected =
  test ("updates the " ++ attr ++ " attribute") <|
    \() -> Expect.equal expected (getAttr (Tuple.first (App.update msg model)))

testUpdatedModelAttribute: String -> (App.Model -> a) -> App.Msg -> a -> Test
testUpdatedModelAttribute attr getAttr msg expected =
  testUpdatedModelAttributeCustom attr initModel getAttr msg expected

all: Test
all =
  describe "App tests"
    [ describe "initial model attributes"
      [ testInitialModelAttribute "input" (\m -> m.input) ""
      , testInitialModelAttribute "output" (\m -> m.output) ""
      , testInitialModelAttribute "spaces" (\m -> m.spaces) 2
      ]
    , describe "updating model input"
      [ testUpdatedModelAttribute "input" (\m -> m.input) (App.Input "updated") "updated"
      , testUpdatedModelAttribute "output" (\m -> m.output) (App.Input "select foo") "SELECT foo"
      ]
    , describe "updating model spaces"
      [ testUpdatedModelAttribute "spaces" (\m -> m.spaces) (App.Spaces "4") 4
      , testUpdatedModelAttributeCustom
          "output"
          modelWithQuery
          (\m -> m.output)
          (App.Spaces "4")
          "SELECT *\nFROM a\nJOIN b\n    ON c = d"
      ]
    ]
