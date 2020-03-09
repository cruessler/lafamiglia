module Api exposing
    ( get, post, patch
    , Config, config
    )

{-|

@docs get, post, patch, send

-}

import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Task exposing (Task, fail, succeed)


type alias Config =
    { csrfToken : String }


type alias Request a =
    { url : String
    , params : Encode.Value
    , decoder : Decode.Decoder a
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
get : Config -> Request a -> Http.Request a
get =
    send Get


{-| Create a task for sending a POST request to a url.
-}
post : Config -> Request a -> Http.Request a
post =
    send Post


{-| Create a task for sending a PATCH request to a url.
-}
patch : Config -> Request a -> Http.Request a
patch =
    send Patch


{-| Create a task for sending a request to a url.

The API token is sent in an "Authorization" header.

-}
send : Method -> Config -> Request a -> Http.Request a
send method config_ { url, params, decoder } =
    Http.request
        { method = toString method
        , headers =
            [ Http.header "X-CSRF-Token" config_.csrfToken
            ]
        , url = url
        , body = Http.jsonBody params
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }
