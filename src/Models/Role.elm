module Models.Role exposing (..)

import Json.Decode as Decode exposing (Decoder)


type Role
    = PresenterRole
    | ParticipantRole


roleDecoder : Decoder Role
roleDecoder =
    Decode.string |> Decode.andThen parseRole


parseRole : String -> Decoder Role
parseRole str =
    case str of
        "presenter" ->
            Decode.succeed PresenterRole

        "participant" ->
            Decode.succeed ParticipantRole

        _ ->
            Decode.fail "Failed to parse role"
