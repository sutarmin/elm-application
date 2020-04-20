module Main exposing (main)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Interop.Ports exposing (listen, receive, send)
import Json.Decode as Decode
import List.Zipper as Zipper exposing (Zipper)
import Models.Role exposing (Role(..))
import Models.SST exposing (SST(..))
import Models.SharingEntity exposing (SharingEntity)
import Task exposing (perform)
import Ui.EntitySelector
import Utils.Html exposing (viewNothing)
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


type alias Model =
    { role : Maybe Role
    , technologies : Maybe (Zipper SST)
    , isMobile : Maybe Bool
    , entitySelector : Maybe Ui.EntitySelector.Model
    , displayError : Maybe String
    }


type Msg
    = EntitySelectorMsg Ui.EntitySelector.Msg
    | GotWsMessage (Result Decode.Error ParsedMessage)
    | SendWsMessage OutcomingMessage
    | DoNothing


init : Flags -> ( Model, Cmd Msg )
init hostUrl =
    ( { role = Nothing
      , technologies = Nothing
      , isMobile = Nothing
      , entitySelector = Nothing
      , displayError = Nothing
      }
    , listen hostUrl
    )


wrapSst : Zipper SST -> Msg
wrapSst list =
    SendWsMessage <| StartOM <| Zipper.current list


askSst : Zipper SST -> Cmd Msg
askSst list =
    perform (always (wrapSst list)) (Task.succeed ())


requestNextSstOrShowError : Model -> ( Model, Cmd Msg )
requestNextSstOrShowError model =
    case model.technologies of
        Nothing ->
            ( model, Cmd.none )

        Just tech ->
            case Zipper.next tech of
                Nothing ->
                    ( { model | technologies = Nothing, displayError = Just "Server is unavailable at the moment" }, Cmd.none )

                Just list ->
                    ( model, askSst list )


updateEntitySelector : Ui.EntitySelector.Msg -> Model -> ( Model, Cmd Msg )
updateEntitySelector msg model =
    case model.entitySelector of
        Nothing ->
            ( model, Cmd.none )

        Just entitySelectorModel ->
            Ui.EntitySelector.update msg entitySelectorModel
                |> (\( esModel, esMsg ) -> ( { model | entitySelector = Just esModel }, Cmd.map EntitySelectorMsg esMsg ))


updateOnStartAnswer : Start -> Model -> ( Model, Cmd Msg )
updateOnStartAnswer start model =
    case start of
        StartAck isMobile ->
            ( { model | isMobile = Just isMobile }, Cmd.none )

        StartError ->
            requestNextSstOrShowError model


updateOnWsMessage : ParsedMessage -> Model -> ( Model, Cmd Msg )
updateOnWsMessage message model =
    case message of
        RoleMsg role ->
            ( { model | role = Just role }, Cmd.none )

        PreferencesMsg technologies ->
            ( { model | technologies = Zipper.fromList technologies }, Cmd.none )

        StartAnswer answer ->
            updateOnStartAnswer answer model

        ConfigMsg entities ->
            ( { model | entitySelector = Just <| Ui.EntitySelector.Model entities Modal.hidden Tab.initialState Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            ( model, Cmd.none )

        EntitySelectorMsg entitySelectorMsg ->
            updateEntitySelector entitySelectorMsg model

        SendWsMessage message ->
            ( model, send <| messageToString message )

        GotWsMessage result ->
            case result of
                Err err ->
                    ( { model | displayError = Just (Decode.errorToString err) }, Cmd.none )

                Ok message ->
                    updateOnWsMessage message model



-- VIEW


viewEntitySelector : Maybe Ui.EntitySelector.Model -> Html Msg
viewEntitySelector model =
    case model of
        Just esModel ->
            Html.map EntitySelectorMsg (Ui.EntitySelector.view esModel)

        Nothing ->
            viewNothing


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


viewLoading : Html Msg
viewLoading =
    Html.text "Loading..."


viewParticipant : Html Msg
viewParticipant =
    Html.text "Waiting for sharing to start"


viewPresenter : Model -> Html Msg
viewPresenter model =
    case model.technologies of
        Nothing ->
            Html.text "Waiting for list of supported technologies"

        Just technologies ->
            case model.isMobile of
                Nothing ->
                    div []
                        [ Button.button
                            [ Button.outlineSuccess
                            , Button.attrs [ onClick <| wrapSst technologies ]
                            ]
                            [ text "Start" ]
                        ]

                Just isMobile ->
                    case model.entitySelector of
                        Nothing ->
                            div [] [ text "Waiting for list of available entities to share" ]

                        Just selector ->
                            div []
                                [ Button.button
                                    [ Button.outlineSuccess
                                    , Button.attrs [ onClick <| EntitySelectorMsg Ui.EntitySelector.OpenModal ]
                                    ]
                                    [ text "Show screens/windows" ]
                                , viewEntitySelector model.entitySelector
                                ]


view : Model -> Html Msg
view model =
    case model.displayError of
        Just error ->
            viewError error

        Nothing ->
            case model.role of
                Nothing ->
                    viewLoading

                Just role ->
                    case role of
                        Participant ->
                            viewParticipant

                        Presenter ->
                            viewPresenter model



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    receive (Decode.decodeString messageDecoder >> GotWsMessage)
