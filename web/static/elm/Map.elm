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
    , dimensions : Dimensions
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
    , dimensions : Dimensions
    }


{-|
  Calculate the dimensions of a single map cell.

  Must correspond to `div.cell`’s percentage value in `_map.scss`.
-}
cellDimensions : Dimensions -> Dimensions
cellDimensions dimensions =
    let
        width =
            dimensions.width / 10.0
    in
        { width = width
        , height = width
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        tiles =
            [ ( ( 0, 0 ), Tile { x = 0, y = 0 } Dict.empty ) ] |> Dict.fromList

        model =
            { tiles = tiles
            , center = flags.center
            , origin = { x = 0, y = 0 }
            , dragging = False
            , startPosition = Nothing
            , offset = { x = 0, y = 0 }
            , startOffset = { x = 0, y = 0 }
            , dimensions = flags.dimensions
            , cellDimensions = cellDimensions flags.dimensions
            }
    in
        model ! fetchVillas model


type Msg
    = MouseDown Mouse.Position
    | MouseUp Mouse.Position
    | Move Mouse.Position
    | MouseLeave
    | FetchFail Http.Error
    | FetchSucceed Coordinates (Dict Coordinates Villa)


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
                ! fetchVillas model

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


view : Model -> Html Msg
view model =
    let
        offset : Tile -> Map.Tile.Offset
        offset tile =
            { x = (toFloat tile.origin.x) * model.cellDimensions.width
            , y = (toFloat tile.origin.y) * model.cellDimensions.height
            }

        tiles =
            model.tiles
                |> Dict.values
                |> List.map (\t -> Map.Tile.view (offset t) t)

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
