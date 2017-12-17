module Attack
    exposing
        ( Attack
        , Config
        , config
        , Result(..)
        , Errors
        , errors
        , format
        , postAttack
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


errors : Result -> Errors
errors result =
    case result of
        Failure _ errors ->
            errors

        _ ->
            Errors [] Dict.empty


type alias Attack =
    { origin : Villa
    , target : Villa
    , units : Dict Unit.Id Int
    }


type alias Errors =
    { forBase : List String
    , forUnits : Dict Unit.Id String
    }


type Result
    = InProgress Attack
    | Success Attack
    | Failure Attack Errors


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


postAttack : Config msg -> Attack -> Cmd msg
postAttack (Config config) ({ origin, target, units } as attack) =
    let
        movement =
            (encodeUnits units) ++ [ ( "target_id", Encode.int target.id ) ]

        params =
            Encode.object [ ( "attack_movement", Encode.object movement ) ]
                |> Encode.encode 0

        task =
            Http.send Http.defaultSettings
                { verb = "POST"
                , headers =
                    [ ( "Content-Type", "application/json" )
                    , ( "X-CSRF-Token", config.csrfToken )
                    ]
                , url = attackEndpointUrl origin
                , body = Http.string params
                }
    in
        task
            |> Api.fromJson decodeErrorResponse (Decode.succeed ())
            |> Task.mapError (mapErrorResponse attack)
            |> Task.map (mapSuccessfulResponse attack)
            |> Task.perform config.onFail config.onSuccess


{-| Always discards the error and returns a generic failure message.
-}
mapErrorResponse : Attack -> a -> Result
mapErrorResponse attack _ =
    Failure attack
        (Errors [ "Your attack could not be sent" ] Dict.empty)


{-| Converts an `Api.Response` into an `Attack.Result`.
-}
mapSuccessfulResponse : Attack -> Api.Response Errors a -> Result
mapSuccessfulResponse attack response =
    case response of
        Api.Error errors ->
            Failure attack errors

        Api.Success _ ->
            Success attack


encodeUnits : Dict Unit.Id Int -> List ( String, Encode.Value )
encodeUnits =
    let
        unitKey =
            Units.byId >> Maybe.map .key >> Maybe.withDefault ""
    in
        Dict.toList
            >> List.map
                (\( k, v ) -> ( unitKey k, Encode.int v ))


decodeErrorResponse : Decode.Decoder Errors
decodeErrorResponse =
    Decode.object2
        Errors
        decodeErrorsForBase
        (Decode.succeed Dict.empty)


decodeErrorsForBase : Decode.Decoder (List String)
decodeErrorsForBase =
    Decode.at
        [ "errors", "unit_count" ]
        (Decode.list Decode.string)
