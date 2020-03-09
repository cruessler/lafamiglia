module Format exposing (arrival, duration)

import DateFormat as F
import Duration exposing (Duration)
import Time



{- This module currently only works with UTC, not with local time. This is due
   to changes in Elm 0.19, and will be changed in a later commit.
-}


formatSameDayArrival : Time.Posix -> String
formatSameDayArrival =
    F.format
        [ F.hourMilitaryFixed
        , F.text ":"
        , F.minuteFixed
        , F.text ":"
        , F.secondFixed
        , F.text " "
        , F.amPmUppercase
        ]
        Time.utc


formatNonSameDayArrival : Time.Posix -> String
formatNonSameDayArrival =
    F.format
        [ F.monthNameFull
        , F.text " "
        , F.dayOfMonthSuffix
        , F.text ", "
        , F.hourMilitaryFixed
        , F.text ":"
        , F.minuteFixed
        , F.text ":"
        , F.secondFixed
        , F.text " "
        , F.amPmUppercase
        ]
        Time.utc


arrival : Time.Posix -> Duration -> String
arrival start duration_ =
    formatNonSameDayArrival <|
        Time.millisToPosix <|
            Time.posixToMillis start
                + Duration.toMillis duration_


duration : Duration -> String
duration duration_ =
    let
        millis =
            Duration.toMillis duration_

        minutes =
            Duration.toMinutes duration_ |> String.fromInt

        seconds =
            remainderBy 60 (Duration.toSeconds duration_) |> String.fromInt
    in
    minutes ++ " minutes, " ++ seconds ++ " seconds"
