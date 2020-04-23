module Attack exposing
    ( Attack
    , Config
    , Errors
    , Result
    , config
    , errors
    , format
    , post
    )

import Api
import Dict exposing (Dict)
import Http
import Json.Decode as D
import Json.Encode as E
import Mechanics.Units as Units
import Unit
import Villa exposing (Villa)


attackEndpointUrl : Villa -> String
attackEndpointUrl origin =
    "/api/v1/villas/" ++ String.fromInt origin.id ++ "/attack_movements"


format : Attack -> String
format attack =
    Villa.format attack.origin ++ " → " ++ Villa.format attack.target


errors : Result -> Maybe Errors
errors result =
    case result of
        Err errors_ ->
            Just errors_

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
        }


config :
    { csrfToken : String
    , onSuccess : Result -> msg
    }
    -> Config msg
config { csrfToken, onSuccess } =
    Config
        { csrfToken = csrfToken
        , onSuccess = onSuccess
        }


post : Config msg -> Attack -> Cmd msg
post (Config config_) ({ origin, target, units } as attack) =
    let
        movement =
            encodeUnits units ++ [ ( "target_id", E.int target.id ) ]

        params =
            E.object [ ( "attack_movement", E.object movement ) ]
    in
    Api.post
        { csrfToken = config_.csrfToken }
        { url = attackEndpointUrl origin
        , params = params
        , expect = expectJson config_.onSuccess attack
        }


expectJson : (Result.Result Errors Success -> msg) -> Attack -> Http.Expect msg
expectJson toMsg attack =
    Http.expectStringResponse toMsg (mapErrorResponse attack)


mapErrorResponse : Attack -> Http.Response String -> Result.Result Errors Success
mapErrorResponse attack response =
    let
        genericError =
            Errors attack [ "Your attack could not be sent" ] Dict.empty
    in
    case response of
        Http.GoodStatus_ _ _ ->
            Ok <| Success attack

        Http.BadStatus_ _ body ->
            D.decodeString (decodeErrorResponse attack) body
                |> Result.withDefault genericError
                |> Err

        _ ->
            Err genericError


encodeUnits : Dict Unit.Id Int -> List ( String, E.Value )
encodeUnits =
    let
        unitKey =
            Units.byId >> Maybe.map .key >> Maybe.withDefault ""
    in
    Dict.toList
        >> List.map
            (\( k, v ) -> ( unitKey k, E.int v ))


decodeErrorResponse : Attack -> D.Decoder Errors
decodeErrorResponse attack =
    D.map2
        (Errors attack)
        decodeErrorsForBase
        (D.succeed Dict.empty)


decodeErrorsForBase : D.Decoder (List String)
decodeErrorsForBase =
    D.at
        [ "errors", "unit_count" ]
        (D.list D.string)
