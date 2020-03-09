module Unit exposing (Id, Key, Unit, duration)

import Duration exposing (Duration)


type alias Id =
    Int


type alias Key =
    String


type alias Unit =
    { id : Id
    , key : String
    , name : String
    , speed : Float
    }


duration : List Unit -> Float -> Maybe Duration
duration units distance =
    let
        slowestSpeed =
            List.minimum <| List.map .speed units
    in
    case slowestSpeed of
        Just speed ->
            Just <| Duration.fromMillis (floor (distance / speed) * 1000)

        Nothing ->
            Nothing
