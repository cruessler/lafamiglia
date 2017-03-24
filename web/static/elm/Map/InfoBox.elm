module Map.InfoBox exposing (view)

import Html exposing (Html, h4, div, a, text)
import Html.Attributes exposing (class, href, type')
import Villa exposing (Villa)


reportsHref : Villa -> Html.Attribute msg
reportsHref villa =
    href <| "/villas/" ++ (toString villa.id) ++ "/reports"


view : Maybe Villa -> Html msg
view villa =
    case villa of
        Just v ->
            div [ class "info-box" ]
                [ h4 []
                    [ text (Villa.format v) ]
                , div [ class "actions" ]
                    [ a [ class "btn btn-primary", reportsHref v ]
                        [ text "Reports" ]
                    ]
                ]

        Nothing ->
            div [ class "info-box" ] []
