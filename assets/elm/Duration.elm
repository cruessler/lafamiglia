module Duration exposing (Duration, fromMillis, toMillis, toMinutes, toSeconds)


type Duration
    = Millis Int


toMillis : Duration -> Int
toMillis (Millis millis) =
    millis


fromMillis : Int -> Duration
fromMillis =
    Millis


toSeconds : Duration -> Int
toSeconds (Millis millis) =
    millis // 1000


toMinutes : Duration -> Int
toMinutes (Millis millis) =
    millis // 1000 // 60
