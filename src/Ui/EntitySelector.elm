module Ui.EntitySelector exposing (Msg(..), entityTypeTabs, tabIds, view)

import Bootstrap.Button as Button
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (Html, text)
import Html.Events exposing (onClick)
import Models.SharingEntity exposing (SharingEntity, eqMaybeSharingEntity, isScreen, isWindow)


type alias EntityTypeTabInfo =
    { id : String
    , title : String
    , filter : SharingEntity -> Bool
    }


type alias EntityTypeTab =
    { info : EntityTypeTabInfo
    , values : List SharingEntity
    }


tabIds =
    { windows = "windows"
    , screens = "screens"
    }


entityTypeTabs : List EntityTypeTabInfo
entityTypeTabs =
    [ EntityTypeTabInfo tabIds.windows "Windows" isWindow
    , EntityTypeTabInfo tabIds.screens "Screens" isScreen
    ]


splitEntites : List SharingEntity -> List EntityTypeTab
splitEntites entities =
    entityTypeTabs
        |> List.map (\info -> EntityTypeTab info (List.filter info.filter entities))
        |> List.filter (\tab -> List.length tab.values > 0)



-- UPDATE


type Msg
    = ChangeTab Tab.State
    | CloseModal
    | OpenModal Tab.State
    | SelectEntity SharingEntity



-- VIEW


viewEntity : Maybe SharingEntity -> SharingEntity -> ListGroup.Item Msg
viewEntity selectedEntity entity =
    let
        attrs =
            if eqMaybeSharingEntity selectedEntity (Just entity) then
                [ ListGroup.active
                ]

            else
                [ ListGroup.attrs [ onClick <| SelectEntity entity ]
                ]
    in
    ListGroup.li attrs [ text entity.title ]


viewPane : List SharingEntity -> Maybe SharingEntity -> Tab.Pane Msg
viewPane entities selectedEntity =
    Tab.pane [ Spacing.m3 ]
        [ entities
            |> List.map (viewEntity selectedEntity)
            |> ListGroup.ul
        ]


viewTab : Maybe SharingEntity -> EntityTypeTab -> Tab.Item Msg
viewTab selectedEntity tab =
    Tab.item
        { id = tab.info.id
        , link = Tab.link [ Spacing.mt3 ] [ text tab.info.title ]
        , pane = viewPane tab.values selectedEntity
        }


view : List SharingEntity -> Maybe SharingEntity -> Tab.State -> Modal.Visibility -> Html Msg
view entities selectedEntity tab visibility =
    let
        tabs =
            splitEntites entities
    in
    Modal.config CloseModal
        |> Modal.small
        |> Modal.hideOnBackdropClick True
        |> Modal.h3 [] [ text "Modal header" ]
        |> Modal.body []
            [ Tab.config ChangeTab
                |> Tab.items (List.map (viewTab selectedEntity) tabs)
                |> Tab.view tab
            ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs [ onClick CloseModal ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view visibility
