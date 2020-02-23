module Map.Geometry
    exposing
        ( Geometry
        , Dimensions
        , Offset
        , init
        , viewportCoordinates
        , visibleTileOrigins
        , visibleXAxisLabels
        , visibleYAxisLabels
        )

import Map.Coordinates exposing (Coordinates)


type alias Offset =
    { x : Int
    , y : Int
    }


type alias Dimensions =
    { width : Float
    , height : Float
    }


type alias Geometry =
    { mapDimensions : Dimensions
    , tileDimensions : Dimensions
    , cellDimensions : Dimensions
    }


init : Dimensions -> Dimensions -> Geometry
init mapDimensions tileDimensions =
    Geometry mapDimensions
        tileDimensions
        (cellDimensions tileDimensions)


{-| Calculate the dimensions of a single map cell.

Must correspond to `div.cell`’s percentage value in `_map.scss`.

-}
cellDimensions : Dimensions -> Dimensions
cellDimensions tileDimensions =
    { width = tileDimensions.width / 10.0
    , height = tileDimensions.height / 10.0
    }


{-| Convert viewport coordinates to map coordinates.

Viewport coordinates are relative to the origin of the screen.

-}
mapCoordinates : Geometry -> Coordinates -> Coordinates
mapCoordinates geometry ( viewportX, viewportY ) =
    let
        x =
            (toFloat viewportX)
                / geometry.cellDimensions.width
                |> floor

        y =
            (toFloat viewportY)
                / geometry.cellDimensions.height
                |> floor
    in
        ( x, y )


{-| Convert map coordinates to viewport coordinates.

Viewport coordinates are relative to the origin of the screen.

-}
viewportCoordinates : Geometry -> Coordinates -> Coordinates
viewportCoordinates geometry ( mapX, mapY ) =
    let
        x =
            (toFloat mapX)
                * geometry.cellDimensions.width
                |> round

        y =
            (toFloat mapY)
                * geometry.cellDimensions.height
                |> round
    in
        ( x, y )


tileOrigin : Int -> Int
tileOrigin coordinate =
    if coordinate < 0 then
        ((coordinate // 10) - 1) * 10
    else
        (coordinate // 10) * 10


range : Int -> Int -> Int -> List Int
range start stop step =
    List.range start stop
        |> List.filter (\i -> (i - start) % step == 0)


visibleTileOrigins : Geometry -> Offset -> List Coordinates
visibleTileOrigins geometry offset =
    let
        upperLeftCorner =
            mapCoordinates geometry ( 0 - offset.x, 0 - offset.y )

        lowerRightCorner =
            mapCoordinates
                geometry
                ( (floor geometry.mapDimensions.width) - offset.x
                , (floor geometry.mapDimensions.height) - offset.y
                )

        xs =
            range
                (tileOrigin (Tuple.first upperLeftCorner))
                (tileOrigin (Tuple.first lowerRightCorner))
                10

        ys =
            range
                (tileOrigin (Tuple.second upperLeftCorner))
                (tileOrigin (Tuple.second lowerRightCorner))
                10
    in
        List.concatMap
            (\x -> List.map (\y -> ( y, x )) ys)
            xs


visibleXAxisLabels : Geometry -> Offset -> List Int
visibleXAxisLabels geometry offset =
    let
        upperLeftX =
            mapCoordinates geometry ( 0 - offset.x, 0 - offset.y )
                |> Tuple.first

        width =
            ceiling (geometry.mapDimensions.width / geometry.cellDimensions.width) + 1
    in
        range upperLeftX (upperLeftX + width) 1


visibleYAxisLabels : Geometry -> Offset -> List Int
visibleYAxisLabels geometry offset =
    let
        upperLeftY =
            mapCoordinates geometry ( 0 - offset.x, 0 - offset.y )
                |> Tuple.second

        height =
            ceiling (geometry.mapDimensions.height / geometry.cellDimensions.height) + 1
    in
        range upperLeftY (upperLeftY + height) 1
