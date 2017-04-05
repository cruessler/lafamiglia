module AttackDialog
    exposing
        ( State
        , initialState
        , open
        , close
        , review
        , isOpen
        , Config
        , config
        , view
        , subscriptions
        )

{-| This module provides an attack dialog.

It is implemented using a Bootstrap modal dialog.
-}

import Attack exposing (Attack)
import Html exposing (..)
import Html.App as Html
import Html.Attributes as Attributes exposing (class, classList, rel, href, style, attribute)
import Html.Events as Events
import Http
import Task exposing (Task)
import Json.Decode as Decode exposing ((:=))
import Json.Encode as Encode
import Dict exposing (Dict)
import String
import Time exposing (Time)
import Api
import Format
import Mechanics
import Mechanics.Units as Units
import Unit exposing (Unit)
import Villa exposing (Villa)


subscriptions : Config data msg -> State -> Sub msg
subscriptions (Config config) state =
    let
        unitsPresent =
            Dict.values >> List.any (\v -> v > 0)
    in
        if unitsPresent state.selectedUnits then
            Time.every Time.second (\t -> { state | now = t })
                |> Sub.map config.onUpdate
        else
            Sub.none


type alias State =
    { dialogState : DialogState
    , now : Time
    , selectedUnits : Dict Unit.Id Int
    }


type alias Data =
    { units : Dict Unit.Id Int
    , errors : Attack.Errors
    }


type DialogState
    = Open Villa
    | Closed


initialState : Dict Unit.Id Int -> State
initialState units =
    State Closed 0 (initialUnits units)


initialUnits : Dict Unit.Id Int -> Dict Unit.Id Int
initialUnits units =
    Dict.map (\_ _ -> 0) units


close : State -> State
close state =
    { state | dialogState = Closed }


open : Villa -> State -> State
open villa state =
    { state
        | dialogState = Open villa
        , selectedUnits = initialUnits state.selectedUnits
    }


review : Attack.Result -> State -> State
review result state =
    case result of
        Attack.Failure attack errors ->
            { state
                | dialogState = Open attack.target
                , selectedUnits = attack.units
            }

        _ ->
            state


isOpen : State -> Bool
isOpen state =
    state.dialogState /= Closed


type Config data msg
    = Config
        { onAttack : Attack -> msg
        , onUpdate : State -> msg
        , origin : Villa
        }


config :
    { onAttack : Attack -> msg
    , onUpdate : State -> msg
    , origin : Villa
    }
    -> Config data msg
config { onAttack, onUpdate, origin } =
    Config
        { onAttack = onAttack
        , onUpdate = onUpdate
        , origin = origin
        }


modalHeader : Villa -> Html msg
modalHeader target =
    div [ class "modal-header" ]
        [ h2 [] [ text ("Attack on " ++ Villa.format target) ] ]


range : Decode.Decoder msg -> Int -> Int -> Html msg
range decoder current max =
    input
        [ Attributes.type' "range"
        , Attributes.min "0"
        , Attributes.max (toString max)
        , Attributes.value (toString current)
        , Attributes.step "1"
        , Events.on "input" decoder
        , Events.on "change" decoder
        ]
        []


updateValue : State -> Unit.Id -> Int -> State
updateValue state id value =
    { state | selectedUnits = Dict.insert id value state.selectedUnits }


sliderLink :
    (Int -> msg)
    -> Int
    -> String
    -> Html msg
sliderLink onUpdate value text' =
    a
        [ class "adjacent-link btn btn-default btn-xs"
        , Events.onClick (onUpdate value)
        ]
        [ text text' ]


sliderLinks :
    (Int -> msg)
    -> Int
    -> Int
    -> List (Html msg)
sliderLinks onUpdate current max' =
    let
        steps =
            [0..4]

        numSteps =
            List.length steps - 1

        step =
            toFloat max' / toFloat numSteps

        {- This helper expects `acc` to be sorted. -}
        uniq : Int -> List Int -> List Int
        uniq current acc =
            case acc of
                x :: xs ->
                    if x == current then
                        acc
                    else
                        current :: acc

                [] ->
                    [ current ]

        values =
            List.map (\i -> round <| toFloat i * step) steps
                |> List.foldr uniq []

        {- Adding the type signature `Int -> Html msg` leads to a compile
           error.
        -}
        decreaseLink by =
            let
                value =
                    max (current - by) 0
            in
                sliderLink onUpdate value ("-" ++ (toString by))

        increaseLink by =
            let
                value =
                    min (current + by) max'
            in
                sliderLink onUpdate value ("+" ++ (toString by))

        links =
            List.map
                (\v -> sliderLink onUpdate v (toString v))
                values
    in
        [ div [ class "absolute-links" ] links
        , div [ class "relative-links" ]
            [ decreaseLink 1
            , decreaseLink 10
            , increaseLink 1
            , increaseLink 10
            ]
        ]


sliderWithLinks :
    Config data msg
    -> State
    -> Unit.Id
    -> Int
    -> Html msg
sliderWithLinks (Config config) state id max =
    let
        current =
            Dict.get id state.selectedUnits |> Maybe.withDefault 0

        onUpdate =
            updateValue state id >> config.onUpdate

        links =
            sliderLinks onUpdate current max

        rangeDecoder =
            Decode.at [ "target", "valueAsNumber" ] Decode.int
                |> Decode.map (updateValue state id)
                |> Decode.map config.onUpdate
    in
        div [ class "slider" ]
            ([ range rangeDecoder current max ] ++ links)


sliderWithUnitName :
    Config data msg
    -> State
    -> Unit.Id
    -> Int
    -> Html msg
sliderWithUnitName config state id value =
    let
        unitName =
            Units.byId >> Maybe.map .name >> Maybe.withDefault ""

        children =
            [ h4 [] [ text (unitName id) ]
            , sliderWithLinks config state id value
            ]
    in
        div [ class "unit-slider" ] children


overviewHeader : Data -> Html msg
overviewHeader data =
    let
        unitName =
            Units.byId >> Maybe.map .name >> Maybe.withDefault ""

        columns =
            data.units
                |> Dict.keys
                |> List.map (\k -> th [] [ text (unitName k) ])
    in
        tr [] ([ td [] [] ] ++ columns)


unitsChosen : State -> Data -> Html msg
unitsChosen state data =
    let
        columns =
            state.selectedUnits
                |> Dict.values
                |> List.map (\v -> td [] [ text (toString v) ])
    in
        tr [ class "units-chosen" ] ([ td [] [ text "Chosen" ] ] ++ columns)


unitsAvailable : State -> Data -> Html msg
unitsAvailable state data =
    let
        columns =
            data.units
                |> Dict.values
                |> List.map (\v -> td [] [ text (toString v) ])
    in
        tr [] ([ td [] [ text "Available" ] ] ++ columns)


overview : State -> Data -> Html msg
overview state data =
    table [ class "table overview" ]
        [ overviewHeader data
        , unitsChosen state data
        , unitsAvailable state data
        ]


arrivalInfo : Config data msg -> State -> Villa -> Html msg
arrivalInfo (Config config) state target =
    let
        units =
            state.selectedUnits
                |> Dict.filter (\id s -> s > 0)
                |> Dict.keys
                |> List.filterMap Units.byId

        duration =
            Unit.duration
                units
                (Mechanics.distance config.origin target)

        arrival =
            duration
                |> Maybe.map (Format.arrival state.now)
                |> Maybe.withDefault ""

        timeToArrival =
            duration
                |> Maybe.map Format.duration
                |> Maybe.withDefault ""

        classes =
            classList
                [ ( "table", True )
                , ( "arrival-info", True )
                , ( "units-selected", List.length units > 0 )
                ]
    in
        table [ classes ]
            [ tr [ class "arrives-at" ]
                [ td [] [ text "Arrives at" ]
                , td [] [ text arrival ]
                ]
            , tr []
                [ td [] [ text "Arrives in" ]
                , td [] [ text timeToArrival ]
                ]
            ]


modalBody : Config data msg -> State -> Villa -> Data -> Html msg
modalBody config state target data =
    let
        messages =
            ul [ class "alert alert-info" ]
                (List.map (\m -> li [] [ text m ]) data.errors.forBase)

        children =
            [ h3 [] [ text "Overview" ]
            , messages
            , overview state data
            , arrivalInfo config state target
            , h3 [] [ text "Choose the units to send" ]
            ]

        sliders =
            Dict.map
                (sliderWithUnitName config state)
                data.units
                |> Dict.values
    in
        div [ class "modal-body" ] (children ++ sliders)


modalFooter : Config data msg -> State -> Villa -> Html msg
modalFooter (Config config) state target =
    let
        attack =
            Attack config.origin target state.selectedUnits
    in
        div [ class "modal-footer" ]
            [ button
                [ attribute "type" "button"
                , class "btn btn-default"
                , Events.onClick (config.onUpdate <| close state)
                ]
                [ text "Cancel" ]
            , button
                [ attribute "type" "button"
                , class "btn btn-primary"
                , Events.onClick (config.onAttack attack)
                ]
                [ text "Attack" ]
            ]


modal : Config data msg -> State -> Villa -> Data -> Html msg
modal config state target data =
    let
        visible =
            state.dialogState /= Closed
    in
        div
            [ Attributes.id "attack-modal"
            , classList
                [ ( "modal", True )
                , ( "fade", True )
                , ( "in", visible )
                , ( "show", visible )
                ]
            ]
            [ div [ class "modal-dialog" ]
                [ div [ class "modal-content" ]
                    [ modalHeader target
                    , modalBody config state target data
                    , modalFooter config state target
                    ]
                ]
            ]


view : Config data msg -> State -> Data -> Html msg
view config state data =
    case state.dialogState of
        Open target ->
            div [] [ modal config state target data ]

        Closed ->
            text ""
