module Main exposing (main)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Interop.Ports exposing (listen, receive, send)
import Json.Decode as Decode
import List.Zipper as Zipper exposing (Zipper)
import Models.Role exposing (Role(..))
import Models.SST exposing (SST(..), sstToString)
import Models.SharingEntity exposing (SharingEntity)
import Task exposing (perform)
import Ui.SharingScreen exposing (SharingMode(..))
import WsApi.IncomingMessages exposing (ParsedMessage(..), Start(..), messageDecoder)
import WsApi.OutcomingMessages exposing (OutcomingMessage(..), messageToString)


type alias Flags =
    String


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias WaitingForAcknowledgementModel =
    { currentAttempt : Zipper SST
    , previousAttempt : Maybe SST
    }


type PresenterModel
    = WaitingForPreferences
    | ReadyToStart (Zipper SST)
    | WaitingForAcknowledgement WaitingForAcknowledgementModel
    | WaitingForSharingEntites SST
    | Sharing Ui.SharingScreen.Model


type Model
    = Initial
    | Participaint
    | Presenter PresenterModel
    | Error String


type Msg
    = GotWsMessage (Result Decode.Error ParsedMessage)
    | SendWsMessage OutcomingMessage
    | SharingScreenMsg Ui.SharingScreen.Msg
    | DoNothing


init : Flags -> ( Model, Cmd Msg )
init hostUrl =
    ( Initial, listen hostUrl )


wrapSst : Zipper SST -> Msg
wrapSst list =
    SendWsMessage <| StartOM <| Zipper.current list


askSst : Zipper SST -> Cmd Msg
askSst list =
    perform (always (wrapSst list)) (Task.succeed ())


updateOnWsMessage : ParsedMessage -> Model -> ( Model, Cmd Msg )
updateOnWsMessage message model =
    case message of
        RoleMsg role ->
            case role of
                ParticipantRole ->
                    ( Participaint, Cmd.none )

                PresenterRole ->
                    ( Presenter WaitingForPreferences, Cmd.none )

        PreferencesMsg technologies ->
            let
                tech =
                    Zipper.fromList technologies
            in
            case tech of
                Nothing ->
                    ( Error "Got empty list of available screen sharing technologies", Cmd.none )

                Just t ->
                    ( Presenter <| ReadyToStart t, Cmd.none )

        StartAnswer answer ->
            case model of
                Presenter presenterModel ->
                    case presenterModel of
                        WaitingForAcknowledgement waitingForAckModel ->
                            case answer of
                                StartAckVNC isMobile ->
                                    if isMobile then
                                        ( Presenter <| Sharing <| Ui.SharingScreen.initialModel VNCMobileSharing, Cmd.none )

                                    else
                                        ( Presenter <| WaitingForSharingEntites VNC, Cmd.none )

                                StartAckWebRTC ->
                                    ( Presenter <| WaitingForSharingEntites WebRTC, Cmd.none )

                                StartError ->
                                    let
                                        nextSst =
                                            Zipper.next waitingForAckModel.currentAttempt
                                    in
                                    case nextSst of
                                        Nothing ->
                                            ( Error "No sharing technologies are available at the moment", Cmd.none )

                                        Just zipperSst ->
                                            ( Presenter <| WaitingForAcknowledgement <| WaitingForAcknowledgementModel zipperSst (Just (Zipper.current waitingForAckModel.currentAttempt)), askSst zipperSst )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ConfigMsg entities ->
            case model of
                Presenter presenterModel ->
                    case presenterModel of
                        WaitingForSharingEntites selectedSst ->
                            case selectedSst of
                                VNC ->
                                    ( Presenter <| Sharing <| Ui.SharingScreen.initialModel <| (VNCDesktopSharing <| Ui.SharingScreen.initialSharingModeModel entities), Cmd.none )

                                WebRTC ->
                                    ( Presenter <| Sharing <| Ui.SharingScreen.initialModel <| (WebRTCSharing <| Ui.SharingScreen.initialSharingModeModel entities), Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


updateSharingScreen : Ui.SharingScreen.Msg -> Model -> ( Model, Cmd Msg )
updateSharingScreen msg model =
    case model of
        Presenter presModel ->
            case presModel of
                Sharing screenModel ->
                    Ui.SharingScreen.update msg screenModel
                        |> (\( sharingModel, sharingCmd ) -> ( Presenter <| Sharing sharingModel, sharingCmd |> Cmd.map SharingScreenMsg ))

                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            ( model, Cmd.none )

        SharingScreenMsg sharingModeMsg ->
            updateSharingScreen sharingModeMsg model

        SendWsMessage message ->
            case ( message, model ) of
                ( StartOM _, Presenter presenterModel ) ->
                    case presenterModel of
                        ReadyToStart sstlist ->
                            ( Presenter <| WaitingForAcknowledgement <| WaitingForAcknowledgementModel sstlist Nothing, send <| messageToString message )

                        _ ->
                            ( model, send <| messageToString message )

                _ ->
                    ( model, send <| messageToString message )

        GotWsMessage result ->
            case result of
                Err err ->
                    ( Error <| Decode.errorToString err, Cmd.none )

                Ok message ->
                    updateOnWsMessage message model



-- VIEW


viewError : String -> Html Msg
viewError error =
    Modal.config DoNothing
        |> Modal.small
        |> Modal.hideOnBackdropClick False
        |> Modal.h3 [] [ text "Error happened" ]
        |> Modal.body []
            [ Html.text error
            ]
        |> Modal.view Modal.shown


viewParticipant : Html Msg
viewParticipant =
    Html.text "Waiting for sharing to start"


viewPresenter : PresenterModel -> Html Msg
viewPresenter model =
    case model of
        WaitingForPreferences ->
            Html.text "Waiting for list of supported technologies"

        ReadyToStart technologies ->
            div []
                [ Button.button
                    [ Button.outlineSuccess
                    , Button.attrs [ onClick <| wrapSst technologies ]
                    ]
                    [ text "Start" ]
                ]

        WaitingForAcknowledgement waitingForAckModel ->
            let
                prevAttemptFailedText =
                    waitingForAckModel.previousAttempt
                        |> Maybe.map sstToString
                        |> Maybe.map (\sst -> "Server refused to use " ++ sst ++ ". ")
                        |> Maybe.withDefault ""

                currentTechnology =
                    sstToString <| Zipper.current waitingForAckModel.currentAttempt
            in
            Html.text <| prevAttemptFailedText ++ "Attempting to connect via " ++ currentTechnology

        WaitingForSharingEntites _ ->
            Html.text "Waiting for list of what to share"

        Sharing sharingModel ->
            Ui.SharingScreen.view sharingModel
                |> Html.map SharingScreenMsg


view : Model -> Html Msg
view model =
    case model of
        Initial ->
            Html.text "Waiting for role"

        Participaint ->
            viewParticipant

        Presenter presenterModel ->
            viewPresenter presenterModel

        Error message ->
            viewError message



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    receive (Decode.decodeString messageDecoder >> GotWsMessage)
