module Format exposing (arrival, duration)

import Date
import Date.Format exposing (format)
import Time exposing (Time)


arrival : Time -> Time -> String
arrival now arrival =
    let
        dateNow =
            Date.fromTime now

        dateArrival =
            Date.fromTime arrival

        formatString =
            if
                Date.year dateNow
                    == Date.year dateArrival
                    && Date.month dateNow
                    == Date.month dateArrival
                    && Date.day dateNow
                    == Date.day dateArrival
            then
                "%I:%M:%S %P"
            else
                "%B %e, %I:%M:%S %P"
    in
        format formatString dateArrival


duration : Time -> String
duration duration =
    let
        minutes =
            Time.inMinutes duration |> floor |> toString

        seconds =
            (Time.inSeconds duration |> floor) `rem` 60 |> toString
    in
        minutes ++ " minutes, " ++ seconds ++ " seconds"
