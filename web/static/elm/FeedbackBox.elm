module FeedbackBox exposing (view)

import Html exposing (Html, div, ul, li, text)
import Html.Attributes exposing (class)


view : List String -> Html msg
view messages =
    if List.isEmpty messages then
        text ""
    else
        div [ class "feedback-box" ]
            [ ul [] (List.map (\m -> li [] [ text m ]) messages) ]
