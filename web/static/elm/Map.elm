module Map exposing (main)

import Html exposing (..)
import Html.App as Html


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    ()


type alias Flags =
    {}


init : Flags -> ( Model, Cmd () )
init flags =
    ( ()
    , Cmd.none
    )


type alias Msg =
    ()


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    model ! []


view : Model -> Html Msg
view model =
    div [] []
