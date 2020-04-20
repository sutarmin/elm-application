module Ui.EntitySelector exposing (Model, Msg(..), entityTypeTabs, update, view)

import Bootstrap.Button as Button
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (Html, text)
import Html.Events exposing (onClick)
import Models.SharingEntity exposing (SharingEntity, eqMaybeSharingEntity, isScreen, isWindow)


type alias Model =
    { entities : List SharingEntity
    , visibility : Modal.Visibility
    , activeTab : Tab.State
    , selectedEntity : Maybe SharingEntity
    }


type alias EntityTypeTabInfo =
    { id : String
    , title : String
    , filter : SharingEntity -> Bool
    }


type alias EntityTypeTab =
    { info : EntityTypeTabInfo
    , values : List SharingEntity
    }


entityTypeTabs : List EntityTypeTabInfo
entityTypeTabs =
    [ EntityTypeTabInfo "windows" "Windows" isWindow
    , EntityTypeTabInfo "screens" "Screens" isScreen
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
    | OpenModal
    | SelectEntity SharingEntity


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeTab tab ->
            ( { model | activeTab = tab }, Cmd.none )

        OpenModal ->
            ( { model | visibility = Modal.shown }, Cmd.none )

        CloseModal ->
            ( { model | visibility = Modal.hidden }, Cmd.none )

        SelectEntity entity ->
            ( { model | selectedEntity = Just entity, visibility = Modal.hidden }, Cmd.none )



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


view : Model -> Html Msg
view model =
    let
        tabs =
            splitEntites model.entities
    in
    Modal.config CloseModal
        |> Modal.small
        |> Modal.hideOnBackdropClick True
        |> Modal.h3 [] [ text "Modal header" ]
        |> Modal.body []
            [ Tab.config ChangeTab
                |> Tab.items (List.map (viewTab model.selectedEntity) tabs)
                |> Tab.view model.activeTab
            ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs [ onClick CloseModal ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view model.visibility
