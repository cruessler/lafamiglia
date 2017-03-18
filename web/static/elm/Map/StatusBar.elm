module Map.StatusBar exposing (view)

import Html exposing (Html, div, small, text)
import Html.Attributes exposing (class)
import Villa exposing (Villa)


view : Maybe Villa -> Html msg
view villa =
    case villa of
        Just v ->
            div [ class "status-bar" ]
                [ text (Villa.format v)
                , small [] [ text "Click on the villa to see more actions" ]
                ]

        Nothing ->
            div [ class "status-bar" ] []
