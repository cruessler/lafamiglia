module Unit exposing (Unit, duration)

import Time exposing (Time)


type alias Unit =
    { id : Int
    , key : String
    , name : String
    , speed : Float
    }


duration : List Unit -> Float -> Maybe Time
duration units distance =
    let
        slowestSpeed =
            List.minimum <| List.map .speed units
    in
        case slowestSpeed of
            Just speed ->
                Just ((distance / speed) * Time.second)

            Nothing ->
                Nothing
