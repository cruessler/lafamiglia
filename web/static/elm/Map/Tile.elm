module Map.Tile exposing (Tile, Offset, Config, config, view)

import Map.Coordinates exposing (Coordinates)
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events as Events
import Map.Position exposing (Position)
import Villa exposing (Villa)


width : Int
width =
    10


height : Int
height =
    width


type alias Tile =
    { origin : Position
    , villas : Dict ( Int, Int ) Villa
    }


type alias Offset =
    { x : Float
    , y : Float
    }


type Config msg
    = Config
        { onHover : Maybe Villa -> msg
        }


config :
    { onHover : Maybe Villa -> msg
    }
    -> Config msg
config { onHover } =
    Config
        { onHover = onHover
        }


cell : Config msg -> Coordinates -> Tile -> Html msg
cell (Config { onHover }) coordinates tile =
    case Dict.get coordinates tile.villas of
        (Just v) as villa ->
            div
                [ class "cell"
                , Events.onMouseEnter (onHover villa)
                , Events.onMouseOut (onHover Nothing)
                ]
                [ text (Villa.format v) ]

        Nothing ->
            div [ class "cell" ] []


view : Config msg -> Offset -> Tile -> Html msg
view config offset tile =
    let
        xs =
            [tile.origin.x..(tile.origin.x + width - 1)]

        ys =
            [tile.origin.y..(tile.origin.y + height - 1)]

        cells =
            List.concatMap
                (\x -> List.map (\y -> cell config ( x, y ) tile) xs)
                ys

        tileStyle =
            [ ( "top", (toString offset.x) ++ "px" )
            , ( "left", (toString offset.y) ++ "px" )
            ]
    in
        div [ class "tile", style tileStyle ] cells
