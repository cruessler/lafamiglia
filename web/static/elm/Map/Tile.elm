module Map.Tile exposing (Tile, Offset, view)

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


cell : (Maybe Villa -> msg) -> Coordinates -> Tile -> Html msg
cell toMsg coordinates tile =
    case Dict.get coordinates tile.villas of
        (Just v) as villa ->
            div
                [ class "cell"
                , Events.onMouseEnter (toMsg villa)
                , Events.onMouseOut (toMsg Nothing)
                ]
                [ text (Villa.format v) ]

        Nothing ->
            div [ class "cell" ] []


view : (Maybe Villa -> msg) -> Offset -> Tile -> Html msg
view toMsg offset tile =
    let
        xs =
            [tile.origin.x..(tile.origin.x + width - 1)]

        ys =
            [tile.origin.y..(tile.origin.y + height - 1)]

        cells =
            List.concatMap
                (\x -> List.map (\y -> cell toMsg ( x, y ) tile) xs)
                ys

        tileStyle =
            [ ( "top", (toString offset.x) ++ "px" )
            , ( "left", (toString offset.y) ++ "px" )
            ]
    in
        div [ class "tile", style tileStyle ] cells
