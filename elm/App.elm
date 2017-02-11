port module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onFocus, onInput)
import Result
import SQLFormatter


defaultSpaces : Int
defaultSpaces =
    2


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    { input : String
    , output : String
    , spaces : Int
    }


init : ( Model, Cmd Msg )
init =
    { input = ""
    , output = ""
    , spaces = defaultSpaces
    }
        ! []


port selectOutput : () -> Cmd msg


type Msg
    = Input String
    | Spaces String
    | Select


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input text ->
            { model
                | input = text
                , output = SQLFormatter.format text model.spaces
            }
                ! []

        Spaces text ->
            let
                spacesInt =
                    Result.withDefault defaultSpaces (String.toInt text)
            in
                { model
                    | spaces = spacesInt
                    , output = SQLFormatter.format model.input spacesInt
                }
                    ! []

        Select ->
            ( model, selectOutput () )


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "form-inline mb-3" ]
            [ label [ for "sql-spaces", class "h4 mr-3" ] [ text "Spaces" ]
            , input
                [ id "sql-spaces"
                , class "form-control"
                , type_ "number"
                , value (toString model.spaces)
                , onInput Spaces
                ]
                []
            ]
        , div [ class "form-group" ]
            [ label
                [ for "sql-input", class "d-flex h4 mb-3" ]
                [ text "Input" ]
            , textarea
                [ id "sql-input"
                , class "form-control code"
                , placeholder "Enter SQL"
                , rows 9
                , onInput Input
                ]
                [ text model.input ]
            ]
        , div [ class "form-group" ]
            [ label
                [ for "sql-output", class "d-flex h4 mb-3" ]
                [ text "Output" ]
            , textarea
                [ id "sql-output"
                , class "form-control code mb-3"
                , rows 20
                , readonly True
                , onFocus Select
                , onClick Select
                ]
                [ text model.output ]
            ]
        ]
