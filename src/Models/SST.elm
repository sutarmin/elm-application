module Models.SST exposing (SST, parseSst, sstDecoder, sstToString)

-- SST stands for Screen Sharing Technology

import Json.Decode as Decode exposing (Decoder)


type SST
    = VNC
    | WebRTC


sstDecoder : Decoder SST
sstDecoder =
    Decode.string |> Decode.andThen parseSst


sstToString : SST -> String
sstToString sst =
    case sst of
        VNC ->
            "VNC"

        WebRTC ->
            "WebRTC"


parseSst : String -> Decoder SST
parseSst str =
    case str of
        "VNC" ->
            Decode.succeed VNC

        "WebRTC" ->
            Decode.succeed WebRTC

        _ ->
            Decode.fail "Failed to parse SST"
