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
    { center : Position }


type alias Position =
    { x : Int
    , y : Int
    }


type alias Flags =
    { center : Position }


init : Flags -> ( Model, Cmd () )
init flags =
    ( { center = flags.center }
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
