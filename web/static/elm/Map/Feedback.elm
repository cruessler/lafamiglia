module Map.Feedback exposing (forResults)

import Attack
import Dict exposing (Dict)
import Html exposing (Html, li, span, a, text)
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
        Attack.InProgress attack ->
            [ Html.h4 [] [ text <| Attack.format attack ]
            , text "Your attack is on the way"
            ]

        Attack.Success attack ->
            [ Html.h4 [] [ text <| Attack.format attack ]
            , text "Your attack is on the way (confirmed)"
            ]

        Attack.Failure attack errors ->
            [ Html.h4 [] [ text <| Attack.format attack ]
            , span [] [ text "Your attack could not be sent" ]
            , a
                [ class "btn btn-primary btn-sm pull-right"
                , Events.onClick (onReview result)
                ]
                [ text "Review" ]
            ]
