module FeedbackBox exposing (view)

import Html exposing (Html, div, li, text, ul)
import Html.Attributes exposing (class)


view : List (List (Html msg)) -> Html msg
view entries =
    if List.isEmpty entries then
        text ""

    else
        div [ class "feedback-box" ]
            [ ul [] (List.map (\e -> li [] e) entries) ]
