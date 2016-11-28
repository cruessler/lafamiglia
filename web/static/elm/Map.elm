module Map exposing (main)

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (class, rel, href, style, attribute)
import Html.Events exposing (onMouseLeave)
import Mouse


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { center : Position
    , dragging : Bool
    , startPosition : Maybe Mouse.Position
    , offset : Offset
    , startOffset : Offset
    }


type alias Position =
    { x : Int
    , y : Int
    }


type alias Offset =
    { x : Int
    , y : Int
    }


type alias Flags =
    { center : Position }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { center = flags.center
      , dragging = False
      , startPosition = Nothing
      , offset = { x = 0, y = 0 }
      , startOffset = { x = 0, y = 0 }
      }
    , Cmd.none
    )


type Msg
    = MouseDown Mouse.Position
    | MouseUp Mouse.Position
    | Move Mouse.Position
    | MouseLeave


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MouseDown position ->
            { model
                | dragging = True
                , startPosition = Just position
                , startOffset = model.offset
            }
                ! []

        MouseUp position ->
            { model
                | dragging = False
                , startPosition = Nothing
            }
                ! []

        MouseLeave ->
            { model | dragging = False, startPosition = Nothing } ! []

        Move position ->
            case model.startPosition of
                Just start ->
                    let
                        newOffset =
                            { x = model.startOffset.x + position.x - start.x
                            , y = model.startOffset.y + position.y - start.y
                            }
                    in
                        { model | offset = newOffset } ! []

                Nothing ->
                    model ! []


view : Model -> Html Msg
view model =
    let
        cells =
            List.map (\i -> div [ class "cell" ] [ text (toString i) ]) [1..100]

        mapStyle =
            [ ( "transform"
              , "translate("
                    ++ (toString model.offset.x)
                    ++ "px, "
                    ++ (toString model.offset.y)
                    ++ "px)"
              )
            ]
    in
        div [ class "container-fluid map-viewport" ]
            [ div
                [ class "map-inner-viewport"
                , onMouseLeave MouseLeave
                ]
                [ div [ class "map", style mapStyle ] cells
                ]
            ]


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.dragging then
        Sub.batch [ Mouse.moves Move, Mouse.ups MouseUp ]
    else
        Mouse.downs MouseDown
