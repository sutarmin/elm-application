module WsApi.IncomingMessages exposing (ParsedMessage(..), Start(..), messageDecoder)

import Json.Decode as Decode exposing (Decoder)
import Models.Role exposing (Role, roleDecoder)
import Models.SST exposing (SST, sstDecoder)
import Models.SharingEntity exposing (SharingEntity, sharingEntityDecoder)


type ParsedMessage
    = RoleMsg Role
    | PreferencesMsg (List SST)
    | ConfigMsg (List SharingEntity)
    | StartAnswer Start


roleMsgDecoder : Decoder ParsedMessage
roleMsgDecoder =
    Decode.field "role" roleDecoder
        |> Decode.map RoleMsg


preferencesMsgDecoder : Decoder ParsedMessage
preferencesMsgDecoder =
    Decode.field "technologies" (Decode.list sstDecoder)
        |> Decode.map PreferencesMsg


configMsgDecoder : Decoder ParsedMessage
configMsgDecoder =
    Decode.field "entities" (Decode.list sharingEntityDecoder)
        |> Decode.map ConfigMsg


type Start
    = StartAck Bool
    | StartError


decodeAnswer : String -> Decoder Start
decodeAnswer answer =
    case answer of
        "acknowledge" ->
            Decode.field "isMobile" Decode.bool
                |> Decode.map StartAck

        "error" ->
            Decode.succeed StartError

        _ ->
            Decode.fail "Unknown type of Start message"


startDecoder : Decoder ParsedMessage
startDecoder =
    Decode.field "answer" Decode.string
        |> Decode.andThen decodeAnswer
        |> Decode.map StartAnswer


decodeMessage : String -> Decoder ParsedMessage
decodeMessage msgType =
    case msgType of
        "role" ->
            roleMsgDecoder

        "preferences" ->
            preferencesMsgDecoder

        "config" ->
            configMsgDecoder

        "start" ->
            startDecoder

        _ ->
            Decode.fail "Unknown message type"


messageDecoder : Decoder ParsedMessage
messageDecoder =
    Decode.field "type" Decode.string |> Decode.andThen decodeMessage
