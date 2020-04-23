module Map exposing (main)

import Api
import Attack exposing (Attack)
import AttackDialog
import Browser
import Browser.Events
import Dict exposing (Dict)
import FeedbackBox
import Html exposing (..)
import Html.Attributes exposing (attribute, class, href, id, rel, style)
import Html.Events as Events
import Http
import Json.Decode as Json exposing (..)
import Json.Encode as Encode
import Map.Coordinates exposing (Coordinates)
import Map.Feedback as Feedback
import Map.Geometry as Geometry exposing (Geometry)
import Map.InfoBox as InfoBox
import Map.Position exposing (Position)
import Map.StatusBar as StatusBar
import Map.Tile as Tile exposing (Tile)
import Mechanics.Units as Units
import Task
import Unit
import Url.Builder as Url
import Villa exposing (Villa)


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


villasEndpointUrl : List String
villasEndpointUrl =
    [ "api", "v1", "map" ]


type alias Model =
    { tiles : Dict Coordinates Tile
    , center : Position
    , origin : Position
    , dragging : Bool
    , startPosition : Maybe Position
    , offset : Geometry.Offset
    , startOffset : Geometry.Offset
    , geometry : Geometry
    , hoveredVilla : Maybe Villa
    , clickedVilla : Maybe Villa
    , currentVilla : Villa
    , unitNumbers : Dict Unit.Id Int
    , attackDialogState : AttackDialog.State
    , resultInReview : Maybe Attack.Result
    , nextId : Int
    , attacks : Dict Int Attack.Result
    , csrfToken : String
    }


type alias Flags =
    { center : Position
    , mapDimensions : Geometry.Dimensions
    , tileDimensions : Geometry.Dimensions
    , unitNumbers : Json.Value
    , currentVilla : Villa
    , csrfToken : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        unitNumbers =
            flags.unitNumbers
                |> Json.decodeValue Units.decodeUnitNumbers
                |> Result.toMaybe
                |> Maybe.withDefault Dict.empty

        geometry =
            Geometry.init flags.mapDimensions flags.tileDimensions

        model =
            { tiles = Dict.empty
            , center = flags.center
            , origin = { x = 0, y = 0 }
            , dragging = False
            , startPosition = Nothing
            , offset = { x = 0, y = 0 }
            , startOffset = { x = 0, y = 0 }
            , geometry = geometry
            , hoveredVilla = Nothing
            , clickedVilla = Nothing
            , currentVilla = flags.currentVilla
            , unitNumbers = unitNumbers
            , attackDialogState = AttackDialog.initialState unitNumbers
            , resultInReview = Nothing
            , nextId = 0
            , attacks = Dict.empty
            , csrfToken = flags.csrfToken
            }

        tiles =
            visibleTiles model

        modelWithTiles =
            { model | tiles = tiles }
    in
    ( modelWithTiles
    , Cmd.batch (fetchVillas modelWithTiles)
    )


type Msg
    = MouseDown Position
    | MouseUp Position
    | Move Position
    | Hover (Maybe Villa)
    | MouseLeave
    | Click (Maybe Villa)
    | OpenAttackDialog Villa
    | ReviewAttackDialog Attack.Result
    | SendTroops Attack
    | NewDialogState AttackDialog.State
    | FetchVillas Coordinates (Result Http.Error (Dict Coordinates Villa))
    | PostAttack Int Attack.Result


getOrCreateTile : Dict Coordinates Tile -> Coordinates -> Tile
getOrCreateTile tiles coords =
    tiles
        |> Dict.get coords
        |> Maybe.withDefault
            (Tile { x = Tuple.first coords, y = Tuple.second coords } Dict.empty)


visibleTiles : Model -> Dict Coordinates Tile
visibleTiles model =
    Geometry.visibleTileOrigins model.geometry model.offset
        |> List.map
            (\origin -> ( origin, getOrCreateTile model.tiles origin ))
        |> Dict.fromList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MouseDown position ->
            ( { model
                | dragging = True
                , startPosition = Just position
                , startOffset = model.offset
              }
            , Cmd.none
            )

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
            ( newModel
            , Cmd.batch (fetchVillas newModel)
            )

        MouseLeave ->
            ( { model | dragging = False, startPosition = Nothing }
            , Cmd.none
            )

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
                                toFloat newOffset.x
                                    / model.geometry.cellDimensions.width
                                    |> round
                            , y =
                                toFloat newOffset.y
                                    / model.geometry.cellDimensions.height
                                    |> round
                            }
                    in
                    ( { model
                        | origin = newOrigin
                        , offset = newOffset
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model
                    , Cmd.none
                    )

        Hover villa ->
            ( { model | hoveredVilla = villa }
            , Cmd.none
            )

        Click villa ->
            ( { model | clickedVilla = villa }
            , Cmd.none
            )

        OpenAttackDialog villa ->
            let
                newState =
                    model.attackDialogState |> AttackDialog.open villa
            in
            ( { model | attackDialogState = newState }
            , Cmd.none
            )

        ReviewAttackDialog result ->
            let
                newState =
                    model.attackDialogState |> AttackDialog.review result
            in
            ( { model
                | attackDialogState = newState
                , resultInReview = Just result
              }
            , Cmd.none
            )

        SendTroops attack ->
            let
                newState =
                    model.attackDialogState |> AttackDialog.close

                nextId =
                    model.nextId + 1

                config =
                    Attack.config
                        { csrfToken = model.csrfToken
                        , onSuccess = PostAttack model.nextId
                        }
            in
            ( { model
                | attackDialogState = newState
                , nextId = nextId
              }
            , Attack.post config attack
            )

        NewDialogState state ->
            ( { model | attackDialogState = state }
            , Cmd.none
            )

        FetchVillas coordinates (Ok villas) ->
            let
                newTile =
                    Tile { x = Tuple.first coordinates, y = Tuple.second coordinates } villas

                newTiles =
                    model.tiles |> Dict.insert coordinates newTile
            in
            ( { model | tiles = newTiles }
            , Cmd.none
            )

        FetchVillas _ _ ->
            ( model
            , Cmd.none
            )

        PostAttack id result ->
            let
                newAttacks =
                    model.attacks
                        |> Dict.insert id result
            in
            ( { model | attacks = newAttacks }
            , Cmd.none
            )


fetchVillas : Model -> List (Cmd Msg)
fetchVillas model =
    model.tiles |> Dict.values |> List.map fetchVillas_


fetchVillas_ : Tile -> Cmd Msg
fetchVillas_ tile =
    let
        params =
            [ Url.int "min_x" tile.origin.x
            , Url.int "min_y" tile.origin.y
            , Url.int "max_x" (tile.origin.x + 10)
            , Url.int "max_y" (tile.origin.y + 10)
            ]

        url =
            Url.absolute villasEndpointUrl params
    in
    Api.get
        { csrfToken = "" }
        { url = url
        , params = Encode.null
        , expect =
            Http.expectJson
                (FetchVillas ( tile.origin.x, tile.origin.y ))
                Villa.decodeVillas
        }


offset : Geometry.Dimensions -> Tile -> Tile.Offset
offset cellDimensions tile =
    { x = toFloat tile.origin.x * cellDimensions.width
    , y = toFloat tile.origin.y * cellDimensions.height
    }


xAxisLabel : Model -> Int -> Html Msg
xAxisLabel model x =
    let
        offset_ =
            Geometry.viewportCoordinates model.geometry ( x, 0 )
    in
    div
        [ class "x-axis-label"
        , style "left" (String.fromInt (Tuple.first offset_) ++ "px")
        ]
        [ text (String.fromInt x) ]


yAxisLabel : Model -> Int -> Html Msg
yAxisLabel model y =
    let
        offset_ =
            Geometry.viewportCoordinates model.geometry ( 0, y )
    in
    div
        [ class "y-axis-label"
        , style "top" (String.fromInt (Tuple.second offset_) ++ "px")
        ]
        [ text (String.fromInt y) ]


view : Model -> Html Msg
view model =
    let
        xAxisLabels =
            Geometry.visibleXAxisLabels model.geometry model.offset
                |> List.map (xAxisLabel model)

        yAxisLabels =
            Geometry.visibleYAxisLabels model.geometry model.offset
                |> List.map (yAxisLabel model)

        offset_ =
            offset model.geometry.cellDimensions

        tiles =
            model.tiles
                |> Dict.values
                |> List.map
                    (\t -> Tile.view tileConfig (offset_ t) t)

        xAxisStyle =
            style "transform" ("translateX(" ++ String.fromInt model.offset.x ++ "px)")

        yAxisStyle =
            style "transform" ("translateY(" ++ String.fromInt model.offset.y ++ "px)")

        mapStyle =
            style "transform"
                ("translate("
                    ++ String.fromInt model.offset.x
                    ++ "px, "
                    ++ String.fromInt model.offset.y
                    ++ "px)"
                )

        errors =
            model.resultInReview
                |> Maybe.andThen Attack.errors
    in
    div [ id "map", class "container-fluid map-viewport" ]
        [ div
            [ class "x-axis-labels", xAxisStyle ]
            xAxisLabels
        , div
            [ class "y-axis-labels", yAxisStyle ]
            yAxisLabels
        , div
            [ class "map-inner-viewport"
            , Events.onMouseLeave MouseLeave
            ]
            [ div [ class "map", mapStyle ] tiles
            ]
        , StatusBar.view model.hoveredVilla
        , InfoBox.view OpenAttackDialog model.clickedVilla
        , AttackDialog.view
            (attackDialogConfig model.currentVilla)
            model.attackDialogState
            { units = model.unitNumbers, errors = errors }
        , FeedbackBox.view
            (Feedback.forResults ReviewAttackDialog model.attacks)
        ]


tileConfig : Tile.Config Msg
tileConfig =
    Tile.config
        { onHover = Hover
        , onClick = Click
        }


attackDialogConfig : Villa -> AttackDialog.Config () Msg
attackDialogConfig origin =
    AttackDialog.config
        { onAttack = SendTroops
        , onUpdate = NewDialogState
        , origin = origin
        }


decodePosition : Json.Decoder Position
decodePosition =
    Json.map2 Position
        (Json.field "pageX" Json.int)
        (Json.field "pageY" Json.int)


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        subscriptions_ =
            if model.dragging then
                Sub.batch
                    [ Browser.Events.onMouseMove <| Json.map Move decodePosition
                    , Browser.Events.onMouseUp <| Json.map MouseUp decodePosition
                    ]

            else
                Browser.Events.onMouseDown <| Json.map MouseDown decodePosition
    in
    Sub.batch
        [ AttackDialog.subscriptions
            (attackDialogConfig model.currentVilla)
            model.attackDialogState
        , subscriptions_
        ]
