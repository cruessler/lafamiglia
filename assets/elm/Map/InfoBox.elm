module Map.InfoBox exposing (view)

import Html exposing (Html, a, div, h4, text)
import Html.Attributes exposing (class, href, type_)
import Html.Events as Events
import Villa exposing (Villa)


reportsHref : Villa -> Html.Attribute msg
reportsHref villa =
    href <| "/villas/" ++ String.fromInt villa.id ++ "/reports"


view : (Villa -> msg) -> Maybe Villa -> Html msg
view onClick villa_ =
    case villa_ of
        Just villa ->
            div [ class "info-box" ]
                [ h4 []
                    [ text (Villa.format villa) ]
                , div [ class "actions" ]
                    [ a [ class "btn btn-primary", reportsHref villa ]
                        [ text "Reports" ]
                    , a [ class "btn btn-primary", Events.onClick (onClick villa) ]
                        [ text "Attack" ]
                    ]
                ]

        Nothing ->
            div [ class "info-box" ] []
