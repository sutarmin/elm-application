module Utils.Eq exposing (Eq, liftMaybe)

-- I didn't find compatible module in registiry, so found it easier to partially implement it by myself


type alias Eq a =
    a -> a -> Bool


liftMaybe : Eq a -> Eq (Maybe a)
liftMaybe eq =
    \first second ->
        first
            |> Maybe.andThen (\fst -> Maybe.map (eq fst) second)
            |> Maybe.withDefault False
