module Main exposing (main)

import Browser
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick)
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
    , allTopLists :
        List TopList
    , currentTopListItems : List TopListItem
    }


type Msg
    = ClickedTopListSlug String
    | GotJson (Result Http.Error (List TopListItem))


initialModel : () -> ( Model, Cmd Msg )
initialModel _ =
    ( { selectedListSlug = "keyboard-concerti-100"
      , allTopLists = TopList.lists
      , currentTopListItems = []
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
        , css
            [ hover
                [ cursor pointer
                ]
            , if topList.slug == currentSlug then
                textDecoration underline

              else
                textDecoration none
            ]
        ]
        [ text topList.title ]


listElemFull : TopList -> Html Msg
listElemFull topList =
    div []
        [ div [] [ text topList.title ]
        , div [] [ text topList.description ]
        ]


topListItem : TopListItem -> Html Msg
topListItem item =
    div [] [ text (item.composer ++ ": " ++ item.work) ]


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
        { url = "/assets/json/" ++ slug ++ ".json"
        , expect = Http.expectJson GotJson topListItemsDecoder
        }


view : Model -> Html Msg
view model =
    let
        topLists =
            model.allTopLists
    in
    div []
        [ h1 [] [ text "All Lists" ]
        , ul [] (List.map (listElemShort model.selectedListSlug) topLists)
        , h1 [] [ text "Currently Selected List" ]
        , listElemFull (getListBySlug model.allTopLists model.selectedListSlug)
        , h1 [] [ text "Content" ]
        , div [] (List.map topListItem model.currentTopListItems)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedTopListSlug slugName ->
            ( { model | selectedListSlug = slugName }, getTopListItems slugName )

        GotJson result ->
            case result of
                Ok items ->
                    ( { model | currentTopListItems = items }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


main =
    Browser.element
        { init = initialModel
        , subscriptions = subscriptions
        , update = update
        , view = view >> toUnstyled
        }
