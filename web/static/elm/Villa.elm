module Villa exposing (Villa, Id, format, decodeVillas)

import Map.Coordinates exposing (Coordinates)
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, (:=))


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
    Decode.object4 Villa
        ("id" := Decode.int)
        ("name" := Decode.string)
        ("x" := Decode.int)
        ("y" := Decode.int)


format : Villa -> String
format villa =
    villa.name ++ " (" ++ (toString villa.x) ++ "|" ++ (toString villa.y) ++ ")"
