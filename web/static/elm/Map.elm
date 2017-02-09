module Map exposing (main)

import Dict exposing (Dict)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (class, rel, href, style, attribute)
import Html.Events exposing (onMouseLeave)
import Http
import Json.Decode as Json exposing (..)
import Map.Coordinates exposing (Coordinates)
import Map.Position exposing (Position)
import Map.Tile exposing (Tile)
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
    | MouseLeave
    | FetchFail Http.Error
    | FetchSucceed Coordinates (Dict Coordinates Villa)


getOrCreateTile : Dict Coordinates Tile -> Coordinates -> Tile
getOrCreateTile tiles coords =
    tiles
        |> Dict.get coords
        |> Maybe.withDefault (Tile { x = fst coords, y = snd coords } Dict.empty)


mapCoordinates : Model -> Coordinates -> Coordinates
mapCoordinates model ( viewportX, viewportY ) =
    let
        x =
            floor (toFloat (viewportX - model.offset.x) / model.cellDimensions.width)

        y =
            floor (toFloat (viewportY - model.offset.y) / model.cellDimensions.height)
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
            Http.get decodeVillas url
    in
        Task.perform FetchFail (FetchSucceed ( tile.origin.x, tile.origin.y )) task


decodeVillas : Json.Decoder (Dict Coordinates Villa)
decodeVillas =
    let
        listToDict list =
            List.map (\v -> ( ( v.x, v.y ), v )) list
                |> Dict.fromList
    in
        Json.map listToDict (list decodeVilla)


decodeVilla : Json.Decoder Villa
decodeVilla =
    object4 Villa
        ("id" := int)
        ("name" := string)
        ("x" := int)
        ("y" := int)


offset : Dimensions -> Tile -> Map.Tile.Offset
offset cellDimensions tile =
    { x = (toFloat tile.origin.x) * cellDimensions.width
    , y = (toFloat tile.origin.y) * cellDimensions.height
    }


view : Model -> Html Msg
view model =
    let
        tiles =
            model.tiles
                |> Dict.values
                |> List.map
                    (\t -> Map.Tile.view (offset model.cellDimensions t) t)

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
                [ div [ class "map", style mapStyle ] tiles
                ]
            ]


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.dragging then
        Sub.batch [ Mouse.moves Move, Mouse.ups MouseUp ]
    else
        Mouse.downs MouseDown
