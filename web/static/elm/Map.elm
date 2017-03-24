module Map exposing (main)

import Dict exposing (Dict)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (class, rel, href, style, attribute)
import Html.Events as Events
import Http
import Json.Decode as Json exposing (..)
import Map.Coordinates exposing (Coordinates)
import Map.Position exposing (Position)
import Map.StatusBar as StatusBar
import Map.Tile as Tile exposing (Tile)
import Mouse
import Task
import Villa exposing (Villa)


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


villasEndpointUrl : String
villasEndpointUrl =
    "/api/v1/map"


type alias Model =
    { tiles : Dict Coordinates Tile
    , center : Position
    , origin : Position
    , dragging : Bool
    , startPosition : Maybe Mouse.Position
    , offset : Offset
    , startOffset : Offset
    , mapDimensions : Dimensions
    , tileDimensions : Dimensions
    , cellDimensions : Dimensions
    , hoveredVilla : Maybe Villa
    }


type alias Offset =
    { x : Int
    , y : Int
    }


type alias Dimensions =
    { width : Float
    , height : Float
    }


type alias Flags =
    { center : Position
    , mapDimensions : Dimensions
    , tileDimensions : Dimensions
    }


{-|
  Calculate the dimensions of a single map cell.

  Must correspond to `div.cell`’s percentage value in `_map.scss`.
-}
cellDimensions : Dimensions -> Dimensions
cellDimensions tileDimensions =
    { width = tileDimensions.width / 10.0
    , height = tileDimensions.height / 10.0
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            { tiles = Dict.empty
            , center = flags.center
            , origin = { x = 0, y = 0 }
            , dragging = False
            , startPosition = Nothing
            , offset = { x = 0, y = 0 }
            , startOffset = { x = 0, y = 0 }
            , mapDimensions = flags.mapDimensions
            , tileDimensions = flags.tileDimensions
            , cellDimensions = cellDimensions flags.tileDimensions
            , hoveredVilla = Nothing
            }

        tiles =
            visibleTiles model

        modelWithTiles =
            { model | tiles = tiles }
    in
        modelWithTiles ! fetchVillas modelWithTiles


type Msg
    = MouseDown Mouse.Position
    | MouseUp Mouse.Position
    | Move Mouse.Position
    | Hover (Maybe Villa)
    | MouseLeave
    | FetchFail Http.Error
    | FetchSucceed Coordinates (Dict Coordinates Villa)


getOrCreateTile : Dict Coordinates Tile -> Coordinates -> Tile
getOrCreateTile tiles coords =
    tiles
        |> Dict.get coords
        |> Maybe.withDefault (Tile { x = fst coords, y = snd coords } Dict.empty)


{-| Convert viewport coordinates to map coordinates.

Viewport coordinates are relative to the origin of the screen.
-}
mapCoordinates : Model -> Coordinates -> Coordinates
mapCoordinates model ( viewportX, viewportY ) =
    let
        x =
            floor (toFloat (viewportX - model.offset.x) / model.cellDimensions.width)

        y =
            floor (toFloat (viewportY - model.offset.y) / model.cellDimensions.height)
    in
        ( x, y )


{-| Convert map coordinates to viewport coordinates.

Viewport coordinates are relative to the origin of the screen.
-}
viewportCoordinates : Model -> Coordinates -> Coordinates
viewportCoordinates model ( mapX, mapY ) =
    let
        x =
            (toFloat mapX)
                * model.cellDimensions.width
                |> round

        y =
            (toFloat mapY)
                * model.cellDimensions.height
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
    [start..stop]
        |> List.filter (\i -> (i - start) % step == 0)


visibleTileOrigins : Model -> List Coordinates
visibleTileOrigins model =
    let
        upperLeftCorner =
            mapCoordinates model ( 0, 0 )

        lowerRightCorner =
            mapCoordinates
                model
                ( (floor model.mapDimensions.width)
                , (floor model.mapDimensions.height)
                )

        xs =
            range
                (tileOrigin (fst upperLeftCorner))
                (tileOrigin (fst lowerRightCorner))
                10

        ys =
            range
                (tileOrigin (snd upperLeftCorner))
                (tileOrigin (snd lowerRightCorner))
                10
    in
        List.concatMap
            (\x -> List.map (\y -> ( y, x )) ys)
            xs


visibleTiles : Model -> Dict Coordinates Tile
visibleTiles model =
    visibleTileOrigins model
        |> List.map
            (\origin -> ( origin, getOrCreateTile model.tiles origin ))
        |> Dict.fromList


visibleXAxisLabels : Model -> List Int
visibleXAxisLabels model =
    let
        upperLeftX =
            mapCoordinates model ( 0, 0 )
                |> fst

        width =
            ceiling (model.mapDimensions.width / model.cellDimensions.width) + 1
    in
        range upperLeftX (upperLeftX + width) 1


visibleYAxisLabels : Model -> List Int
visibleYAxisLabels model =
    let
        upperLeftY =
            mapCoordinates model ( 0, 0 )
                |> snd

        height =
            ceiling (model.mapDimensions.height / model.cellDimensions.height) + 1
    in
        range upperLeftY (upperLeftY + height) 1


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
            let
                newTiles =
                    visibleTiles model

                newModel =
                    { model
                        | dragging = False
                        , startPosition = Nothing
                        , tiles = newTiles
                    }
            in
                newModel ! fetchVillas newModel

        MouseLeave ->
            { model | dragging = False, startPosition = Nothing } ! []

        Move position ->
            case model.startPosition of
                Just start ->
                    let
                        translateOffset =
                            { x = position.x - start.x
                            , y = position.y - start.y
                            }

                        newOffset =
                            { x = model.startOffset.x + translateOffset.x
                            , y = model.startOffset.y + translateOffset.y
                            }

                        newOrigin =
                            { x =
                                (toFloat newOffset.x)
                                    / model.cellDimensions.width
                                    |> round
                            , y =
                                (toFloat newOffset.y)
                                    / model.cellDimensions.height
                                    |> round
                            }
                    in
                        { model
                            | origin = newOrigin
                            , offset = newOffset
                        }
                            ! []

                Nothing ->
                    model ! []

        Hover villa ->
            { model | hoveredVilla = villa } ! []

        FetchFail _ ->
            model ! []

        FetchSucceed coordinates villas ->
            let
                newTile =
                    Tile { x = fst coordinates, y = snd coordinates } villas

                newTiles =
                    model.tiles |> Dict.insert coordinates newTile
            in
                { model | tiles = newTiles } ! []


fetchVillas : Model -> List (Cmd Msg)
fetchVillas model =
    model.tiles |> Dict.values |> List.map fetchVillas'


fetchVillas' : Tile -> Cmd Msg
fetchVillas' tile =
    let
        queryParams =
            [ ( "min_x", toString tile.origin.x )
            , ( "min_y", toString tile.origin.y )
            , ( "max_x", toString (tile.origin.x + 10) )
            , ( "max_y", toString (tile.origin.y + 10) )
            ]

        url =
            Http.url villasEndpointUrl queryParams

        task =
            Http.get Villa.decodeVillas url
    in
        Task.perform FetchFail (FetchSucceed ( tile.origin.x, tile.origin.y )) task


offset : Dimensions -> Tile -> Tile.Offset
offset cellDimensions tile =
    { x = (toFloat tile.origin.x) * cellDimensions.width
    , y = (toFloat tile.origin.y) * cellDimensions.height
    }


xAxisLabel : Model -> Int -> Html Msg
xAxisLabel model x =
    let
        offset =
            viewportCoordinates model ( x, 0 )
    in
        div
            [ class "x-axis-label"
            , style [ ( "left", toString (fst offset) ++ "px" ) ]
            ]
            [ text (toString x) ]


yAxisLabel : Model -> Int -> Html Msg
yAxisLabel model y =
    let
        offset =
            viewportCoordinates model ( 0, y )
    in
        div
            [ class "y-axis-label"
            , style [ ( "top", toString (snd offset) ++ "px" ) ]
            ]
            [ text (toString y) ]


view : Model -> Html Msg
view model =
    let
        xAxisLabels =
            visibleXAxisLabels model
                |> List.map (\x -> xAxisLabel model x)

        yAxisLabels =
            visibleYAxisLabels model
                |> List.map (\y -> yAxisLabel model y)

        tiles =
            model.tiles
                |> Dict.values
                |> List.map
                    (\t -> Tile.view tileConfig (offset model.cellDimensions t) t)

        xAxisStyle =
            [ ( "transform"
              , "translateX(" ++ (toString model.offset.x) ++ "px)"
              )
            ]

        yAxisStyle =
            [ ( "transform"
              , "translateY(" ++ (toString model.offset.y) ++ "px)"
              )
            ]

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
                [ class "x-axis-labels", style xAxisStyle ]
                xAxisLabels
            , div
                [ class "y-axis-labels", style yAxisStyle ]
                yAxisLabels
            , div
                [ class "map-inner-viewport"
                , Events.onMouseLeave MouseLeave
                ]
                [ div [ class "map", style mapStyle ] tiles
                ]
            , StatusBar.view model.hoveredVilla
            ]


tileConfig : Tile.Config Msg
tileConfig =
    Tile.config
        { onHover = Hover
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.dragging then
        Sub.batch [ Mouse.moves Move, Mouse.ups MouseUp ]
    else
        Mouse.downs MouseDown
