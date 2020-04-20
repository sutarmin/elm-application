module WsApi.OutcomingMessages exposing (OutcomingMessage(..), messageToString)

import Json.Encode as Encode
import Models.SST exposing (SST, sstToString)


type OutcomingMessage
    = StartOM SST
    | StopOM
    | PauseOM
    | ResumeOM


messageToString : OutcomingMessage -> String
messageToString message =
    message
        |> encodeMessage
        |> Encode.encode 0


encodeMessage : OutcomingMessage -> Encode.Value
encodeMessage message =
    case message of
        StartOM technology ->
            Encode.object
                [ ( "type", Encode.string "start" )
                , ( "technology", Encode.string <| sstToString technology )
                ]

        StopOM ->
            Encode.object
                [ ( "type", Encode.string "stop" )
                ]

        PauseOM ->
            Encode.object
                [ ( "type", Encode.string "pause" )
                ]

        ResumeOM ->
            Encode.object
                [ ( "type", Encode.string "resume" )
                ]
