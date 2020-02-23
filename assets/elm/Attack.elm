module Attack
    exposing
        ( Attack
        , Config
        , config
        , Result
        , Errors
        , errors
        , format
        , post
        )

import Api
import Dict exposing (Dict)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Villa exposing (Villa)
import Task exposing (Task)
import Unit
import Mechanics.Units as Units


attackEndpointUrl : Villa -> String
attackEndpointUrl origin =
    "/api/v1/villas/" ++ (toString origin.id) ++ "/attack_movements"


format : Attack -> String
format attack =
    (Villa.format attack.origin) ++ " → " ++ (Villa.format attack.target)


errors : Result -> Maybe Errors
errors result =
    case result of
        Err errors ->
            Just errors

        _ ->
            Nothing


type alias Result =
    Result.Result Errors Success


type alias Attack =
    { origin : Villa
    , target : Villa
    , units : Dict Unit.Id Int
    }


type alias Success =
    { attack : Attack }


type alias Errors =
    { attack : Attack
    , forBase : List String
    , forUnits : Dict Unit.Id String
    }


type Config msg
    = Config
        { csrfToken : String
        , onSuccess : Result -> msg
        , onFail : Result -> msg
        }


config :
    { csrfToken : String
    , onSuccess : Result -> msg
    , onFail : Result -> msg
    }
    -> Config msg
config { csrfToken, onSuccess, onFail } =
    Config
        { csrfToken = csrfToken
        , onSuccess = onSuccess
        , onFail = onFail
        }


post :
    Api.Config
    -> Attack
    -> Task Errors Success
post apiConfig ({ origin, target, units } as attack) =
    let
        movement =
            (encodeUnits units) ++ [ ( "target_id", Encode.int target.id ) ]

        params =
            Encode.object [ ( "attack_movement", Encode.object movement ) ]

        errors =
            Errors attack [ "Your attack could not be sent" ] Dict.empty
    in
        Api.post apiConfig
            { url = attackEndpointUrl origin
            , params = params
            , decoder = Decode.succeed <| Success attack
            }
            |> Http.toTask
            |> Task.mapError (mapErrorResponse attack)


mapErrorResponse : Attack -> Http.Error -> Errors
mapErrorResponse attack error =
    let
        genericError =
            Errors attack [ "Your attack could not be sent" ] Dict.empty
    in
        case error of
            Http.BadStatus response ->
                Decode.decodeString (decodeErrorResponse attack) response.body
                    |> Result.withDefault genericError

            _ ->
                genericError


encodeUnits : Dict Unit.Id Int -> List ( String, Encode.Value )
encodeUnits =
    let
        unitKey =
            Units.byId >> Maybe.map .key >> Maybe.withDefault ""
    in
        Dict.toList
            >> List.map
                (\( k, v ) -> ( unitKey k, Encode.int v ))


decodeErrorResponse : Attack -> Decode.Decoder Errors
decodeErrorResponse attack =
    Decode.map2
        (Errors attack)
        decodeErrorsForBase
        (Decode.succeed Dict.empty)


decodeErrorsForBase : Decode.Decoder (List String)
decodeErrorsForBase =
    Decode.at
        [ "errors", "unit_count" ]
        (Decode.list Decode.string)
