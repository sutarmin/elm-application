module Ui.SharingScreen exposing (Model, Msg, SharingMode(..), initialModel, initialSharingModeModel, update, view)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
import Models.SharingEntity exposing (SharingEntity)
import Ui.EntitySelector exposing (Msg(..))
import Utils.Html exposing (viewNothing)


type Msg
    = StartTransmission
    | StopTransmission
    | PauseTransmission
    | EntitySelectorMsg Ui.EntitySelector.Msg


type SharingStatus
    = Started
    | Stopped
    | Paused


type alias SharingModeModel =
    { selectedEntity : Maybe SharingEntity
    , selectorTab : Tab.State
    , selectorVisibility : Modal.Visibility
    , entities : List SharingEntity
    }


initialSharingModeModel : List SharingEntity -> SharingModeModel
initialSharingModeModel entities =
    { selectorTab = Tab.initialState
    , selectedEntity = Nothing
    , selectorVisibility = Modal.hidden
    , entities = entities
    }


type SharingMode
    = WebRTCSharing SharingModeModel
    | VNCDesktopSharing SharingModeModel
    | VNCMobileSharing


type alias Model =
    { status : SharingStatus
    , mode : SharingMode
    }


initialModel : SharingMode -> Model
initialModel mode =
    { status = Stopped
    , mode = mode
    }


changeMode : Model -> SharingMode -> Model
changeMode model mode =
    { model | mode = mode }



-- UPDATE
-- NOTE: in TS I can handle WebRTCSharing and VNCDesktopSharing after VNCMobileSharing elimination because model is the same


updateEntitySelector : Ui.EntitySelector.Msg -> Model -> ( Model, Cmd Msg )
updateEntitySelector msg model =
    case ( msg, model.mode ) of
        ( SelectEntity entity, WebRTCSharing sharingModel ) ->
            ( changeMode model <| WebRTCSharing { sharingModel | selectedEntity = Just entity }, Cmd.none )

        ( SelectEntity entity, VNCDesktopSharing sharingModel ) ->
            ( changeMode model <| VNCDesktopSharing { sharingModel | selectedEntity = Just entity }, Cmd.none )

        ( ChangeTab tab, WebRTCSharing sharingModel ) ->
            ( changeMode model <| WebRTCSharing { sharingModel | selectorTab = tab }, Cmd.none )

        ( ChangeTab tab, VNCDesktopSharing sharingModel ) ->
            ( changeMode model <| VNCDesktopSharing { sharingModel | selectorTab = tab }, Cmd.none )

        ( OpenModal tab, WebRTCSharing sharingModel ) ->
            ( changeMode model <| WebRTCSharing { sharingModel | selectorTab = tab, selectorVisibility = Modal.shown }, Cmd.none )

        ( OpenModal tab, VNCDesktopSharing sharingModel ) ->
            ( changeMode model <| VNCDesktopSharing { sharingModel | selectorTab = tab, selectorVisibility = Modal.shown }, Cmd.none )

        ( CloseModal, WebRTCSharing sharingModel ) ->
            ( changeMode model <| WebRTCSharing { sharingModel | selectorVisibility = Modal.hidden }, Cmd.none )

        ( CloseModal, VNCDesktopSharing sharingModel ) ->
            ( changeMode model <| VNCDesktopSharing { sharingModel | selectorVisibility = Modal.hidden }, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EntitySelectorMsg selectorMsg ->
            updateEntitySelector selectorMsg model

        StartTransmission ->
            ( { model | status = Started }, Cmd.none )

        StopTransmission ->
            ( { model | status = Stopped }, Cmd.none )

        PauseTransmission ->
            ( { model | status = Paused }, Cmd.none )


viewCanvas : String -> SharingStatus -> Html Msg
viewCanvas title status =
    div []
        [ text title
        , div []
            [ case status of
                Stopped ->
                    text "Press Start to start sharing"

                Started ->
                    text "Here be canvas"

                Paused ->
                    text "Sharing is paused. Press Resume to resume"
            ]
        ]


viewMessage : Maybe SharingEntity -> SharingStatus -> Html Msg
viewMessage sharingEntity status =
    case sharingEntity of
        Nothing ->
            div [] [ text "Please, select sharing entity" ]

        Just entity ->
            viewCanvas entity.title status


viewCanvasOrSelectMessage : Model -> Html Msg
viewCanvasOrSelectMessage model =
    case model.mode of
        VNCMobileSharing ->
            viewCanvas "Mobile display" model.status

        VNCDesktopSharing vncModel ->
            viewMessage vncModel.selectedEntity model.status

        WebRTCSharing webRtcModel ->
            viewMessage webRtcModel.selectedEntity model.status


openTab : String -> Msg
openTab tabId =
    tabId
        |> Tab.customInitialState
        |> Ui.EntitySelector.OpenModal
        |> EntitySelectorMsg


viewEntitySelectorButtons : Model -> Html Msg
viewEntitySelectorButtons model =
    case model.mode of
        VNCDesktopSharing vncModel ->
            let
                selectedEntity =
                    vncModel.selectedEntity
            in
            div []
                [ Button.button
                    [ Button.outlineSuccess
                    , Button.attrs [ onClick <| openTab Ui.EntitySelector.tabIds.screens ]
                    ]
                    [ text "Select Screen" ]
                , Button.button
                    [ Button.outlineSuccess
                    , Button.attrs [ onClick <| openTab Ui.EntitySelector.tabIds.windows ]
                    ]
                    [ text "Select Window" ]
                , Ui.EntitySelector.view
                    vncModel.entities
                    selectedEntity
                    vncModel.selectorTab
                    vncModel.selectorVisibility
                    |> Html.map EntitySelectorMsg
                ]

        WebRTCSharing webRTCModel ->
            let
                selectedEntity =
                    webRTCModel.selectedEntity
            in
            div []
                [ Button.button
                    [ Button.outlineSuccess
                    , Button.attrs [ onClick <| openTab Ui.EntitySelector.tabIds.screens ]
                    ]
                    [ text "Select Screen" ]
                , Ui.EntitySelector.view
                    webRTCModel.entities
                    selectedEntity
                    webRTCModel.selectorTab
                    webRTCModel.selectorVisibility
                    |> Html.map EntitySelectorMsg
                ]

        VNCMobileSharing ->
            viewNothing


viewButtons : Model -> Html Msg
viewButtons model =
    let
        shouldDisableStart =
            case model.mode of
                VNCMobileSharing ->
                    False

                VNCDesktopSharing sharingModel ->
                    sharingModel.selectedEntity |> Maybe.map (always False) |> Maybe.withDefault True

                WebRTCSharing sharingModel ->
                    sharingModel.selectedEntity |> Maybe.map (always False) |> Maybe.withDefault True

        isStarted =
            model.status == Started

        isStopped =
            model.status == Stopped

        isPaused =
            model.status == Paused

        stopBtn =
            Button.button
                [ Button.outlineSuccess
                , Button.attrs [ onClick <| StopTransmission ]
                ]
                [ text "Stop" ]

        startBtn =
            Button.button
                [ Button.outlineSuccess
                , Button.disabled <| shouldDisableStart
                , Button.attrs [ onClick <| StartTransmission ]
                ]
                [ text "Start" ]

        pauseBtn =
            Button.button
                [ Button.outlineSuccess
                , Button.attrs [ onClick <| PauseTransmission ]
                ]
                [ text "Pause" ]

        resumeBtn =
            Button.button
                [ Button.outlineSuccess
                , Button.attrs [ onClick <| StartTransmission ]
                ]
                [ text "Resume" ]
    in
    div []
        [ if isStopped then
            startBtn

          else
            stopBtn
        , viewEntitySelectorButtons model
        , case ( isStarted, isPaused ) of
            ( _, True ) ->
                resumeBtn

            ( True, _ ) ->
                pauseBtn

            _ ->
                viewNothing
        ]


view : Model -> Html Msg
view model =
    div []
        [ viewButtons model
        , viewCanvasOrSelectMessage model
        ]
