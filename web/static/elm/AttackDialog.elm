module AttackDialog exposing (..)

{-| This module provides an attack dialog.

It is implemented using a Bootstrap modal dialog.
-}

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (class, rel, href, style, attribute)
import Html.Events exposing (onClick, on)
import Json.Decode as Json
import String
import Time exposing (Time)
import Format
import Mechanics
import Mechanics.Units
import Unit exposing (Unit)
import Villa exposing (Villa)


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = (\m -> Time.every Time.second Tick)
        }


type alias Slider =
    { unit : Unit
    , min : Int
    , max : Int
    , current : Int
    }


type alias Flags =
    { origin : Villa
    , target : Villa
    }


type alias Model =
    { origin : Villa
    , target : Villa
    , now : Maybe Time
    , sliders : List Slider
    }


init : Flags -> ( Model, Cmd a )
init flags =
    ( { origin = flags.origin
      , target = flags.target
      , now = Nothing
      , sliders = List.map (\u -> Slider u 0 0 0) Mechanics.Units.all
      }
    , Cmd.none
    )


type Msg
    = SetValue Int Int
    | Tick Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetValue targetId value ->
            let
                updateSlider =
                    (\id slider ->
                        if targetId == id then
                            { slider | current = value }
                        else
                            slider
                    )

                newSliders =
                    List.indexedMap updateSlider model.sliders
            in
                ( { model | sliders = newSliders }, Cmd.none )

        Tick time ->
            ( { model | now = Just time }, Cmd.none )


modalHeader : Model -> Html Msg
modalHeader model =
    div [ class "modal-header" ]
        [ h2 [] [ text ("Attack on " ++ Villa.format model.target) ] ]


range : Int -> Slider -> Html Msg
range id { min, max, current } =
    let
        percent =
            toFloat (current) / toFloat (max) * 100

        decoder =
            Json.object2 SetValue (Json.succeed id) (Json.at [ "target", "valueAsNumber" ] Json.int)
    in
        input
            [ Html.Attributes.type' "range"
            , Html.Attributes.min (toString min)
            , Html.Attributes.max (toString max)
            , Html.Attributes.value (toString current)
            , Html.Attributes.step "1"
            , on "input" decoder
            , on "change" decoder
            ]
            []


sliderLink' : Int -> Int -> String -> Html Msg
sliderLink' id value text' =
    a
        [ class "adjacent-link btn btn-default btn-xs"
        , onClick (SetValue id value)
        ]
        [ text text' ]


sliderLink : Int -> Int -> Html Msg
sliderLink id value =
    sliderLink' id value (toString value)


decreaseLink : Int -> Slider -> Int -> Html Msg
decreaseLink id slider by =
    let
        value =
            max (slider.current - by) slider.min
    in
        sliderLink' id value ("-" ++ (toString by))


increaseLink : Int -> Slider -> Int -> Html Msg
increaseLink id slider by =
    let
        value =
            min (slider.current + by) slider.max
    in
        sliderLink' id value ("+" ++ (toString by))


sliderLinks : Int -> Slider -> List (Html Msg)
sliderLinks id slider =
    let
        steps =
            [0..4]

        numSteps =
            List.length steps - 1

        step =
            toFloat (slider.max - slider.min) / toFloat (numSteps)

        values =
            List.map (\i -> round <| toFloat (slider.min + i) * step) steps
    in
        [ div [ class "absolute-links" ] (List.map (sliderLink id) values)
        , div [ class "relative-links" ]
            [ decreaseLink id slider 1
            , decreaseLink id slider 10
            , increaseLink id slider 1
            , increaseLink id slider 10
            ]
        ]


sliderWithLinks : Int -> Slider -> Html Msg
sliderWithLinks id slider =
    div [ class "slider" ] ([ range id slider ] ++ sliderLinks id slider)


sliderWithUnitName : Int -> Slider -> Html Msg
sliderWithUnitName id slider =
    let
        children =
            [ h4 [] [ text slider.unit.name ]
            , sliderWithLinks id slider
            ]
    in
        div [ class "unit-slider" ] children


overviewHeader : List Slider -> Html Msg
overviewHeader sliders =
    let
        children =
            [ td [] [] ]
                ++ List.map (\s -> th [] [ text s.unit.name ]) sliders
    in
        tr [] children


unitsChosen : List Slider -> Html Msg
unitsChosen sliders =
    let
        children =
            [ td [] [ text "Chosen" ] ]
                ++ List.map (\s -> td [] [ text (s.current |> toString) ]) sliders
    in
        tr [ class "units-chosen" ] children


unitsAvailable : List Slider -> Html Msg
unitsAvailable sliders =
    let
        children =
            [ td [] [ text "Available" ] ]
                ++ List.map (\s -> td [] [ text (s.max |> toString) ]) sliders
    in
        tr [] children


overview : List Slider -> Html Msg
overview sliders =
    table [ class "table overview" ]
        [ overviewHeader sliders
        , unitsChosen sliders
        , unitsAvailable sliders
        ]


arrivalInfo : Model -> Html Msg
arrivalInfo model =
    let
        units =
            List.filter (\s -> s.current > 0) model.sliders |> List.map .unit

        maybeDuration =
            Unit.duration units (Mechanics.distance model.origin model.target)

        duration =
            case maybeDuration of
                Just duration ->
                    Format.duration duration

                _ ->
                    ""

        arrival =
            case ( model.now, maybeDuration ) of
                ( Just now, Just time ) ->
                    Format.arrival now (now + time)

                _ ->
                    ""

        classes =
            [ "table arrival-info" ]
                ++ case maybeDuration of
                    Just _ ->
                        [ "units-selected" ]

                    _ ->
                        []
    in
        table [ class (String.join " " classes) ]
            [ tr [ class "arrives-at" ]
                [ td [] [ text "Arrives at" ]
                , td [] [ text arrival ]
                ]
            , tr []
                [ td [] [ text "Arrives in" ]
                , td [] [ text duration ]
                ]
            ]


modalBody : Model -> Html Msg
modalBody model =
    let
        children =
            [ h3 [] [ text "Overview" ]
            , overview model.sliders
            , arrivalInfo model
            , h3 [] [ text "Choose the units to send" ]
            ]

        sliders =
            List.indexedMap sliderWithUnitName model.sliders
    in
        div [ class "modal-body" ] (children ++ sliders)


modalFooter : Html Msg
modalFooter =
    div [ class "modal-footer" ]
        [ button
            [ attribute "type" "button"
            , class "btn btn-default"
            , attribute "data-dismiss" "modal"
            ]
            [ text "Cancel" ]
        , button
            [ attribute "type" "button"
            , class "btn btn-primary"
            ]
            [ text "Attack" ]
        ]


modal : Model -> Html Msg
modal model =
    div [ Html.Attributes.id "attack-modal", class "modal fade" ]
        [ div [ class "modal-dialog" ]
            [ div [ class "modal-content" ]
                [ modalHeader model
                , modalBody model
                , modalFooter
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    div [] [ modal model ]