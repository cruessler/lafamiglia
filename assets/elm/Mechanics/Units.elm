module Mechanics.Units exposing (all, byId, byKey, decodeUnitNumbers)

import Dict exposing (Dict)
import Unit exposing (Unit)
import Json.Decode as Decode


all =
    [ Unit 1 "unit_1" "Unit 1" 2
    , Unit 2 "unit_2" "Unit 2" 1
    ]


byId : Unit.Id -> Maybe Unit
byId id =
    List.filter (\u -> u.id == id) all
        |> List.head


byKey : Unit.Key -> Maybe Unit
byKey key =
    List.filter (\u -> u.key == key) all
        |> List.head


decodeUnitNumbers : Decode.Decoder (Dict Unit.Id Int)
decodeUnitNumbers =
    let
        parseKey ( k, v ) =
            ( byKey k
                |> Maybe.map .id
                |> Maybe.withDefault 0
            , v
            )

        transformDict =
            Dict.toList >> List.map parseKey >> Dict.fromList
    in
        Decode.dict Decode.int
            |> Decode.map transformDict
