module Villa exposing (Id, Villa, decodeVillas, format)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, field)
import Map.Coordinates exposing (Coordinates)


type alias Id =
    Int


type alias Villa =
    { id : Id
    , name : String
    , x : Int
    , y : Int
    }


decodeVillas : Decoder (Dict Coordinates Villa)
decodeVillas =
    let
        toDict list =
            list
                |> List.map (\v -> ( ( v.x, v.y ), v ))
                |> Dict.fromList
    in
    Decode.list decodeVilla
        |> Decode.map toDict


decodeVilla : Decoder Villa
decodeVilla =
    Decode.map4 Villa
        (field "id" Decode.int)
        (field "name" Decode.string)
        (field "x" Decode.int)
        (field "y" Decode.int)


format : Villa -> String
format villa =
    villa.name ++ " (" ++ String.fromInt villa.x ++ "|" ++ String.fromInt villa.y ++ ")"
