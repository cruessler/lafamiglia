module Map.Feedback exposing (forResults)

import Attack
import Dict exposing (Dict)
import Html exposing (Html, a, li, span, text)
import Html.Attributes exposing (class)
import Html.Events as Events
import Villa exposing (Villa)


forResults :
    (Attack.Result -> msg)
    -> Dict Int Attack.Result
    -> List (List (Html msg))
forResults onReview results =
    if Dict.isEmpty results then
        []

    else
        Dict.map (singleFeedback onReview) results |> Dict.values


singleFeedback :
    (Attack.Result -> msg)
    -> Int
    -> Attack.Result
    -> List (Html msg)
singleFeedback onReview _ result =
    case result of
        Ok { attack } ->
            [ Html.h4 [] [ text <| Attack.format attack ]
            , text "Your attack is on the way"
            ]

        Err { attack } ->
            [ Html.h4 [] [ text <| Attack.format attack ]
            , span [] [ text "Your attack could not be sent" ]
            , a
                [ class "btn btn-primary btn-sm pull-right"
                , Events.onClick (onReview result)
                ]
                [ text "Review" ]
            ]
