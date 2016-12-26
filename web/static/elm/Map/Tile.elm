module Map.Tile exposing (Tile, Offset, view)

import Map.Coordinates exposing (Coordinates)
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
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


cell : Coordinates -> Tile -> Html msg
cell coordinates tile =
    let
        title =
            Dict.get coordinates tile.villas
                |> Maybe.map (\villa -> (toString villa.y) ++ "|" ++ (toString villa.x) ++ " " ++ villa.name)
                |> Maybe.withDefault ""
    in
        div [ class "cell" ] [ text title ]


view : Offset -> Tile -> Html msg
view offset tile =
    let
        xs =
            [tile.origin.x..(tile.origin.x + width - 1)]

        ys =
            [tile.origin.y..(tile.origin.y + height - 1)]

        cells =
            List.concatMap
                (\x -> List.map (\y -> cell ( x, y ) tile) xs)
                ys

        tileStyle =
            [ ( "top", (toString offset.x) ++ "px" )
            , ( "left", (toString offset.y) ++ "px" )
            ]
    in
        div [ class "tile", style tileStyle ] cells
