module Villa exposing (Villa, format)


type alias Villa =
    { id : Int
    , name : String
    , x : Int
    , y : Int
    }


format : Villa -> String
format villa =
    villa.name ++ " (" ++ (toString villa.x) ++ "|" ++ (toString villa.y) ++ ")"
