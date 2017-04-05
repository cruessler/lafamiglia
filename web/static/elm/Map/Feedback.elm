module Map.Feedback exposing (forResults)

import Attack
import Dict exposing (Dict)
import Html exposing (Html, li, span, a, text)
import Html.Attributes exposing (class)
import Html.Events as Events
import Villa exposing (Villa)


forResults :
    (Attack.Result -> msg)
    -> Dict Attack.Id Attack.Result
    -> List (List (Html msg))
forResults onReview results =
    if Dict.isEmpty results then
        []
    else
        Dict.map (singleFeedback onReview) results |> Dict.values


singleFeedback :
    (Attack.Result -> msg)
    -> Attack.Id
    -> Attack.Result
    -> List (Html msg)
singleFeedback onReview _ result =
    case result of
        Attack.InProgress attack ->
            [ text "Your attack is on the way" ]

        Attack.Success attack ->
            [ text "Your attack is on the way (confirmed)" ]

        Attack.Failure attack errors ->
            [ span [] [ text "Your attack could not be sent" ]
            , a
                [ class "btn btn-primary btn-sm"
                , Events.onClick (onReview result)
                ]
                [ text "Review" ]
            ]
