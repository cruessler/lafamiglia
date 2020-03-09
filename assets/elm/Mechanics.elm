module Mechanics exposing (distance)

import Villa exposing (Villa)


distance : Villa -> Villa -> Float
distance origin target =
    let
        x1 =
            toFloat origin.x

        x2 =
            toFloat target.x

        y1 =
            toFloat origin.y

        y2 =
            toFloat target.y
    in
    sqrt ((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
