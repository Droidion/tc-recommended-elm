module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, field, list, map2, string)
import TopList


type alias TopList =
    { description : String
    , slug : String
    , title : String
    }


type alias TopListItem =
    { composer : String
    , work : String
    }


type alias Model =
    { selectedListSlug : String
    , allTopLists : List TopList
    , currentTopListItems : List TopListItem
    , error : String
    }


type Msg
    = ClickedTopListSlug String
    | GotJson (Result Http.Error (List TopListItem))


initialModel : () -> ( Model, Cmd Msg )
initialModel _ =
    ( { selectedListSlug = "keyboard-concerti-100"
      , allTopLists = TopList.lists
      , currentTopListItems = []
      , error = ""
      }
    , getTopListItems "keyboard-concerti-100"
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


getListBySlug : List TopList -> String -> TopList
getListBySlug allTopLists slug =
    let
        list =
            allTopLists
                |> List.filter (\l -> l.slug == slug)
                |> List.head
    in
    case list of
        Just val ->
            val

        Nothing ->
            { title = "", description = "", slug = "" }


listElemShort : String -> TopList -> Html Msg
listElemShort currentSlug topList =
    li
        [ onClick (ClickedTopListSlug topList.slug)
        , class
            (if topList.slug == currentSlug then
                "selected"

             else
                ""
            )
        ]
        [ text topList.title ]


listElemFull : TopList -> Html Msg
listElemFull topList =
    div []
        [ h1 [] [ text topList.title ]
        , div [ class "list-description" ] [ text topList.description ]
        ]


topListItem : Int -> TopListItem -> Html Msg
topListItem index item =
    div [ class "top-list-item" ]
        [ div [ class "order" ] [ text (String.fromInt (index + 1)) ]
        , div [ class "composer-work" ]
            [ div [ class "composer" ] [ text item.composer ]
            , div [ class "work" ] [ text item.work ]
            ]
        ]


topListItemDecoder : Decoder TopListItem
topListItemDecoder =
    map2 TopListItem
        (field "composer" string)
        (field "work" string)


topListItemsDecoder : Decoder (List TopListItem)
topListItemsDecoder =
    list topListItemDecoder


getTopListItems : String -> Cmd Msg
getTopListItems slug =
    Http.get
        { url = "/json/" ++ slug ++ ".json"
        , expect = Http.expectJson GotJson topListItemsDecoder
        }


headerBlock : Html Msg
headerBlock =
    header []
        [ div [ class "title" ] [ text "Talkclassical Top Lists" ]
        , div [ class "subtitle" ] [ text "Best works of classical music as voted by talkclassical.com members" ]
        ]


menuBlock : Model -> List TopList -> Html Msg
menuBlock model topLists =
    aside []
        [ ul [ class "menu" ] (List.map (listElemShort model.selectedListSlug) topLists)
        ]


contentBlock : Model -> Html Msg
contentBlock model =
    section []
        [ listElemFull (getListBySlug model.allTopLists model.selectedListSlug)
        , div [] (List.indexedMap topListItem model.currentTopListItems)
        ]


view : Model -> Html Msg
view model =
    let
        topLists =
            model.allTopLists
    in
    div []
        [ headerBlock
        , div
            [ class "content" ]
            [ menuBlock model topLists
            , contentBlock model
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedTopListSlug slugName ->
            ( { model | selectedListSlug = slugName }, getTopListItems slugName )

        GotJson result ->
            case result of
                Ok items ->
                    ( { model | currentTopListItems = items, error = "" }, Cmd.none )

                Err _ ->
                    ( { model | currentTopListItems = [], error = "Could not load JSON data" }, Cmd.none )


main =
    Browser.document
        { init = initialModel
        , subscriptions = subscriptions
        , update = update
        , view =
            \m ->
                { title = "TC Recommended"
                , body = [ view m ]
                }
        }
