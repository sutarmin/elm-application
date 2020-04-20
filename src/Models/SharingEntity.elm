module Models.SharingEntity exposing
    ( SharingEntity
    , SharingEntityType(..)
    , eqMaybeSharingEntity
    , isScreen
    , isWindow
    , sharingEntityDecoder
    )

import Json.Decode as Decode exposing (Decoder)
import Utils.Eq exposing (Eq, liftMaybe)


type SharingEntityType
    = Screen
    | Window


type alias SharingEntity =
    { id : String
    , title : String
    , entityType : SharingEntityType
    }


isScreen : SharingEntity -> Bool
isScreen entity =
    entity.entityType == Screen


isWindow : SharingEntity -> Bool
isWindow entity =
    entity.entityType == Window


eqSharingEntity : Eq SharingEntity
eqSharingEntity e1 e2 =
    e1.id == e2.id


eqMaybeSharingEntity : Eq (Maybe SharingEntity)
eqMaybeSharingEntity =
    liftMaybe eqSharingEntity


sharingEntityDecoder : Decoder SharingEntity
sharingEntityDecoder =
    Decode.map3 SharingEntity
        (Decode.field "id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "type" entityTypeDecoder)


entityTypeDecoder : Decoder SharingEntityType
entityTypeDecoder =
    Decode.string |> Decode.andThen parseEntityType


parseEntityType : String -> Decoder SharingEntityType
parseEntityType str =
    case str of
        "window" ->
            Decode.succeed Window

        "screen" ->
            Decode.succeed Screen

        _ ->
            Decode.fail "Failed to parse sharing entity type"
