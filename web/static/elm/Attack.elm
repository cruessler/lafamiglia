module Attack exposing (Attack, Config, config, Errors, Success, postAttack)

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


type alias Attack =
    { origin : Villa
    , target : Villa
    , units : Dict Unit.Id Int
    }


type alias Errors =
    { forBase : List String
    , forUnits : Dict Unit.Id String
    }


type alias Success =
    {}


type Config msg
    = Config
        { csrfToken : String
        , onSuccess : Api.Response Errors Success -> msg
        , onFail : Http.Error -> msg
        }


config :
    { csrfToken : String
    , onFail : Http.Error -> msg
    , onSuccess : Api.Response Errors Success -> msg
    }
    -> Config msg
config { csrfToken, onSuccess, onFail } =
    Config
        { csrfToken = csrfToken
        , onSuccess = onSuccess
        , onFail = onFail
        }


postAttack : Config msg -> Attack -> Cmd msg
postAttack (Config config) { origin, target, units } =
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
            |> Api.fromJson decodeErrorResponse decodeSuccessfulResponse
            |> Task.perform config.onFail config.onSuccess


encodeUnits : Dict Unit.Id Int -> List ( String, Encode.Value )
encodeUnits =
    let
        unitKey =
            Units.byId >> Maybe.map .key >> Maybe.withDefault ""
    in
        Dict.toList
            >> List.map
                (\( k, v ) -> ( unitKey k, Encode.int v ))


decodeSuccessfulResponse : Decode.Decoder Success
decodeSuccessfulResponse =
    Decode.succeed Success


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
