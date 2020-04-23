module Api exposing
    ( get, post, patch
    , Config, config
    )

{-|

@docs get, post, patch, send

-}

import Http
import Json.Encode as Encode


type alias Config =
    { csrfToken : String }


type alias Request msg =
    { url : String
    , params : Encode.Value
    , expect : Http.Expect msg
    }


type Method
    = Get
    | Post
    | Patch


config : String -> Config
config csrfToken =
    Config csrfToken


toString : Method -> String
toString method =
    case method of
        Get ->
            "GET"

        Post ->
            "POST"

        Patch ->
            "PATCH"


{-| Create a task for sending a GET request to a url.
-}
get : Config -> Request msg -> Cmd msg
get =
    send Get


{-| Create a task for sending a POST request to a url.
-}
post : Config -> Request msg -> Cmd msg
post =
    send Post


{-| Create a task for sending a PATCH request to a url.
-}
patch : Config -> Request msg -> Cmd msg
patch =
    send Patch


{-| Create a task for sending a request to a url.

The API token is sent in an "Authorization" header.

-}
send : Method -> Config -> Request msg -> Cmd msg
send method config_ { url, params, expect } =
    Http.request
        { method = toString method
        , headers =
            [ Http.header "X-CSRF-Token" config_.csrfToken
            ]
        , url = url
        , body = Http.jsonBody params
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }
