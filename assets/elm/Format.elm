module Format exposing (arrival, duration)

import Date
import Date.Format exposing (format)
import Time exposing (Time)


arrival : Time -> Time -> String
arrival start duration =
    let
        startDate =
            Date.fromTime start

        arrivalDate =
            Date.fromTime (start + duration)

        formatString =
            if
                Date.year startDate
                    == Date.year arrivalDate
                    && Date.month startDate
                    == Date.month arrivalDate
                    && Date.day startDate
                    == Date.day arrivalDate
            then
                "%I:%M:%S %P"
            else
                "%B %e, %I:%M:%S %P"
    in
        format formatString arrivalDate


duration : Time -> String
duration duration =
    let
        minutes =
            Time.inMinutes duration |> floor |> toString

        seconds =
            rem (Time.inSeconds duration |> floor) 60 |> toString
    in
        minutes ++ " minutes, " ++ seconds ++ " seconds"
