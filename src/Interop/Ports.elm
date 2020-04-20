port module Interop.Ports exposing (..)


port listen : String -> Cmd msg


port receive : (String -> msg) -> Sub msg


port send : String -> Cmd msg
