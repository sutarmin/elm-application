module Mocks.SharingEntity exposing (entities, onlyScreens, onlyWindows)

import Models.SharingEntity exposing (SharingEntity, SharingEntityType(..), isScreen, isWindow)


entities : List SharingEntity
entities =
    [ SharingEntity "Window1" "First Window" Window
    , SharingEntity "Window2" "Second Window" Window
    , SharingEntity "Window3" "Third Window" Window
    , SharingEntity "Screen1" "First Screen" Screen
    , SharingEntity "Screen2" "Second Screen" Screen
    , SharingEntity "Screen3" "Third Screen" Screen
    ]


onlyWindows : List SharingEntity
onlyWindows =
    List.filter isWindow entities


onlyScreens : List SharingEntity
onlyScreens =
    List.filter isScreen entities
