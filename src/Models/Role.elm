module Models.Role exposing (..)

import Json.Decode as Decode exposing (Decoder)


type Role
    = Presenter
    | Participant


roleDecoder : Decoder Role
roleDecoder =
    Decode.string |> Decode.andThen parseRole


parseRole : String -> Decoder Role
parseRole str =
    case str of
        "presenter" ->
            Decode.succeed Presenter

        "participant" ->
            Decode.succeed Participant

        _ ->
            Decode.fail "Failed to parse role"
