module Map exposing (main)

import Api
import Attack exposing (Attack)
import AttackDialog
import Dict exposing (Dict)
import FeedbackBox
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (class, rel, href, style, attribute)
import Html.Events as Events
import Http
import Json.Decode as Json exposing (..)
import Map.Coordinates exposing (Coordinates)
import Map.Feedback as Feedback
import Map.Geometry as Geometry exposing (Geometry)
import Map.InfoBox as InfoBox
import Map.Position exposing (Position)
import Map.StatusBar as StatusBar
import Map.Tile as Tile exposing (Tile)
import Mechanics.Units as Units
import Mouse
import Task
import Unit
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
        modelWithTiles ! fetchVillas modelWithTiles


type Msg
    = MouseDown Mouse.Position
    | MouseUp Mouse.Position
    | Move Mouse.Position
    | Hover (Maybe Villa)
    | MouseLeave
    | Click (Maybe Villa)
    | OpenAttackDialog Villa
    | ReviewAttackDialog Attack.Result
    | SendTroops Attack
    | NewDialogState AttackDialog.State
    | FetchFail Http.Error
    | FetchSucceed Coordinates (Dict Coordinates Villa)
    | AttackFail Int Attack.Result
    | AttackSucceed Int Attack.Result


getOrCreateTile : Dict Coordinates Tile -> Coordinates -> Tile
getOrCreateTile tiles coords =
    tiles
        |> Dict.get coords
        |> Maybe.withDefault (Tile { x = fst coords, y = snd coords } Dict.empty)


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
                                    / model.geometry.cellDimensions.width
                                    |> round
                            , y =
                                (toFloat newOffset.y)
                                    / model.geometry.cellDimensions.height
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

        Click villa ->
            { model | clickedVilla = villa } ! []

        OpenAttackDialog villa ->
            let
                newState =
                    model.attackDialogState |> AttackDialog.open villa
            in
                { model | attackDialogState = newState } ! []

        ReviewAttackDialog result ->
            let
                newState =
                    model.attackDialogState |> AttackDialog.review result
            in
                { model
                    | attackDialogState = newState
                    , resultInReview = Just result
                }
                    ! []

        SendTroops attack ->
            let
                newState =
                    model.attackDialogState |> AttackDialog.close

                nextId =
                    model.nextId + 1
            in
                { model
                    | attackDialogState = newState
                    , nextId = nextId
                }
                    ! [ Attack.postAttack (attackConfig model.nextId model.csrfToken) attack ]

        NewDialogState state ->
            { model | attackDialogState = state } ! []

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

        AttackFail id result ->
            updateAttack id result model ! []

        AttackSucceed id result ->
            updateAttack id result model ! []


updateAttack : Int -> Attack.Result -> Model -> Model
updateAttack id result model =
    let
        newAttacks =
            model.attacks
                |> Dict.insert id result
    in
        { model | attacks = newAttacks }


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


offset : Geometry.Dimensions -> Tile -> Tile.Offset
offset cellDimensions tile =
    { x = (toFloat tile.origin.x) * cellDimensions.width
    , y = (toFloat tile.origin.y) * cellDimensions.height
    }


xAxisLabel : Model -> Int -> Html Msg
xAxisLabel model x =
    let
        offset =
            Geometry.viewportCoordinates model.geometry ( x, 0 )
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
            Geometry.viewportCoordinates model.geometry ( 0, y )
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
            Geometry.visibleXAxisLabels model.geometry model.offset
                |> List.map (xAxisLabel model)

        yAxisLabels =
            Geometry.visibleYAxisLabels model.geometry model.offset
                |> List.map (yAxisLabel model)

        offset' =
            offset model.geometry.cellDimensions

        tiles =
            model.tiles
                |> Dict.values
                |> List.map
                    (\t -> Tile.view tileConfig (offset' t) t)

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

        errors =
            model.resultInReview
                |> Maybe.map Attack.errors
                |> Maybe.withDefault (Attack.Errors [] Dict.empty)
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


attackConfig : Int -> String -> Attack.Config Msg
attackConfig id csrfToken =
    Attack.config
        { csrfToken = csrfToken
        , onSuccess = AttackSucceed id
        , onFail = AttackFail id
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        subscriptions' =
            if model.dragging then
                Sub.batch [ Mouse.moves Move, Mouse.ups MouseUp ]
            else
                Mouse.downs MouseDown
    in
        Sub.batch
            [ AttackDialog.subscriptions
                (attackDialogConfig model.currentVilla)
                model.attackDialogState
            , subscriptions'
            ]
