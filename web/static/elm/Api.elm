module Api exposing (Response(..), fromJson)

{-|

@docs Response

@docs fromJson
-}

import Http
import Json.Decode as Json
import Task exposing (Task, succeed, fail)


{-| Represents an API response.
-}
type Response a b
    = Error a
    | Success b


{-| Turn a `Http.Response` into a `Reponse a b`.

Responses with status code 2xx get decoded by `successDecoder` while responses
with status code 400 get decoded by `failDecoder`.

This accounts for the fact that a JSON API might return a payload on error to
provide further information.
-}
fromJson :
    Json.Decoder a
    -> Json.Decoder b
    -> Task Http.RawError Http.Response
    -> Task Http.Error (Response a b)
fromJson failDecoder successDecoder response =
    let
        failDecode str =
            case Json.decodeString failDecoder str of
                Ok v ->
                    succeed (Error v)

                Err msg ->
                    fail (Http.UnexpectedPayload msg)

        successDecode str =
            case Json.decodeString successDecoder str of
                Ok v ->
                    succeed (Success v)

                Err msg ->
                    fail (Http.UnexpectedPayload msg)
    in
        Task.mapError promoteError response
            `Task.andThen` handleResponse failDecode successDecode


{-| The same as `Http.promoteError` which can’t be used here since it’s
private.
-}
promoteError : Http.RawError -> Http.Error
promoteError rawError =
    case rawError of
        Http.RawTimeout ->
            Http.Timeout

        Http.RawNetworkError ->
            Http.NetworkError


handleResponse :
    (String -> Task Http.Error a)
    -> (String -> Task Http.Error a)
    -> Http.Response
    -> Task Http.Error a
handleResponse failHandle successHandle response =
    if 200 <= response.status && response.status < 300 then
        case response.value of
            Http.Text str ->
                successHandle str

            _ ->
                fail (Http.UnexpectedPayload "Response body is a blob, expecting a string.")
    else if response.status == 400 then
        case response.value of
            Http.Text str ->
                failHandle str

            _ ->
                fail (Http.UnexpectedPayload "Response body is a blob, expecting a string.")
    else
        fail (Http.BadResponse response.status response.statusText)
