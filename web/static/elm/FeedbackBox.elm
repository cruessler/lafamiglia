module FeedbackBox exposing (view)

import Html exposing (Html, div, ul, li, text)
import Html.Attributes exposing (class)


view : List (Html msg) -> Html msg
view entries =
    if List.isEmpty entries then
        text ""
    else
        div [ class "feedback-box" ]
            [ ul [] entries ]
