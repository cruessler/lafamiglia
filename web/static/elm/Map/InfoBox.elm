module Map.InfoBox exposing (view)

import Html exposing (Html, h4, div, a, text)
import Html.Attributes exposing (class, href, type')
import Html.Events as Events
import Villa exposing (Villa)


reportsHref : Villa -> Html.Attribute msg
reportsHref villa =
    href <| "/villas/" ++ (toString villa.id) ++ "/reports"


view : (Villa -> msg) -> Maybe Villa -> Html msg
view onClick villa' =
    case villa' of
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
