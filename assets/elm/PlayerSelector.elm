module PlayerSelector exposing (main)

import Browser
import Dict exposing (Dict)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Json.Decode as D
import Json.Encode as E


type alias Flags =
    ()


type alias Player =
    { id : Int
    , name : String
    }


type State
    = Open
    | Closed


type alias Model =
    { name : String
    , matchingPlayers : List Player
    , selectedPlayers : Dict Int Player
    , state : State
    }


type Msg
    = SetName String
    | AddPlayer Player
    | RemovePlayer Int
    | OpenMenu
    | CloseMenu
    | FetchSuggestions (Result Http.Error (List Player))
    | NoOp


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { name = ""
      , matchingPlayers = []
      , selectedPlayers = Dict.empty
      , state = Closed
      }
    , Cmd.none
    )


viewPlayers : Dict Int Player -> List (Html Msg)
viewPlayers =
    Dict.foldl (\_ player acc -> viewPlayer player :: acc) []


viewHiddenInputs : String -> Dict Int Player -> List (Html Msg)
viewHiddenInputs name =
    -- Lists are encoded by appending `[]` to the param name.
    -- https://github.com/elixir-lang/plug/blob/master/lib/plug/conn/query.ex
    Dict.foldl
        (\_ player acc ->
            H.input
                [ A.type_ "hidden"
                , A.name (name ++ "[]")
                , A.value (String.fromInt player.id)
                ]
                []
                :: acc
        )
        []


onMouseDown : Msg -> H.Attribute Msg
onMouseDown msg =
    E.preventDefaultOn "mousedown" (D.succeed ( msg, True ))


viewSuggestion : Player -> Html Msg
viewSuggestion player =
    H.a
        [ A.href "#"
        , A.class "tt-suggestion tt-selectable"

        -- By default, `onMouseDown` causes the active element to lose focus.
        -- In this case, this would cause a blur in the <input> which would
        -- bubble up and call the topmost <span>’s `onBlur` handler and close
        -- the menu such that the `onClick` would never be called.
        , onMouseDown NoOp
        , E.onClick (AddPlayer player)
        ]
        [ H.text player.name ]


viewMenu : Model -> Html Msg
viewMenu model =
    if model.state == Open then
        H.div [ A.class "tt-menu" ]
            [ H.div [ A.class "tt-dataset tt-dataset-players" ] <|
                H.h4 [] [ H.text "Players" ]
                    :: List.map viewSuggestion model.matchingPlayers
            ]

    else
        H.text ""


viewPlayer : Player -> Html Msg
viewPlayer player =
    H.div [ A.class "btn-group player-selected" ]
        [ H.button
            [ A.class "btn btn-default btn-sm dropdown-toggle"
            , A.type_ "button"
            , A.attribute "data-toggle" "dropdown"
            ]
            [ H.text player.name, H.span [ A.class "caret" ] [] ]
        , H.ul [ A.class "dropdown-menu", A.attribute "role" "menu" ]
            [ H.li []
                [ H.a
                    [ A.href "#"
                    , A.class "remove-player"
                    , E.onClick (RemovePlayer player.id)
                    ]
                    [ H.text "Remove" ]
                ]
            ]
        ]


viewInput : Model -> Html Msg
viewInput model =
    H.span [ A.class "twitter-typeahead" ]
        [ H.input
            [ A.type_ "text"
            , A.class "form-control player-search tt-hint"
            , A.tabindex -1
            ]
            []
        , H.input
            [ A.type_ "text"
            , A.class "form-control player-search tt-input"
            , A.value model.name
            , A.placeholder "Type to search …"
            , E.onInput SetName
            , E.onFocus OpenMenu
            , E.onBlur CloseMenu
            ]
            []
        , viewMenu model
        ]


view : Model -> Html Msg
view ({ name, selectedPlayers } as model) =
    H.div []
        [ H.div [ A.class "has-feedback" ]
            [ viewInput model
            , H.span
                [ A.class "glyphicon glyphicon-search form-control-feedback"
                ]
                []
            , H.div [] (viewPlayers selectedPlayers)
            , H.div [] (viewHiddenInputs name selectedPlayers)
            ]
        ]


decodePlayer : D.Decoder Player
decodePlayer =
    D.map2 Player
        (D.field "id" D.int)
        (D.field "name" D.string)


decodePlayers : D.Decoder (List Player)
decodePlayers =
    D.list decodePlayer


fetchSuggestions : String -> Cmd Msg
fetchSuggestions name =
    let
        url =
            "/api/v1/players/search/" ++ name
    in
    Http.get
        { url = url
        , expect = Http.expectJson FetchSuggestions decodePlayers
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetName newName ->
            ( { model | name = newName }, fetchSuggestions newName )

        AddPlayer player ->
            let
                newSelectedPlayers =
                    Dict.insert player.id player model.selectedPlayers
            in
            ( { model | selectedPlayers = newSelectedPlayers }, Cmd.none )

        RemovePlayer id ->
            let
                newSelectedPlayers =
                    Dict.remove id model.selectedPlayers
            in
            ( { model | selectedPlayers = newSelectedPlayers }, Cmd.none )

        OpenMenu ->
            ( { model | state = Open }, Cmd.none )

        CloseMenu ->
            ( { model | state = Closed }, Cmd.none )

        FetchSuggestions (Ok matchingPlayers) ->
            ( { model | matchingPlayers = matchingPlayers }, Cmd.none )

        FetchSuggestions _ ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )
