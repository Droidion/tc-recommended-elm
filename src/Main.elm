module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, field, list, map2, string)
import Leaderboard



-- TYPE ALIASES


type alias Leaderboard =
    { description : String
    , slug : String
    , title : String
    }


type alias LeaderboardItem =
    { composer : String
    , work : String
    }


type alias Model =
    { selectedListSlug : String
    , allLeaderboards : List Leaderboard
    , currentLeaderboardItems : List LeaderboardItem
    , error : String
    }



-- TYPES


type Msg
    = ClickedLeaderboardSlug String
    | GotJson (Result Http.Error (List LeaderboardItem))



-- MODEL


initialModel : () -> ( Model, Cmd Msg )
initialModel _ =
    ( { selectedListSlug = "keyboard-concerti-100"
      , allLeaderboards = Leaderboard.leaderboards
      , currentLeaderboardItems = []
      , error = ""
      }
    , getLeaderboardItems "keyboard-concerti-100"
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HELPER FUNCTIONS


getListBySlug : List Leaderboard -> String -> Leaderboard
getListBySlug allLeaderboards slug =
    let
        list =
            allLeaderboards
                |> List.filter (\l -> l.slug == slug)
                |> List.head
    in
    case list of
        Just val ->
            val

        Nothing ->
            { title = "", description = "", slug = "" }



-- JSON decoders


leaderboardItemDecoder : Decoder LeaderboardItem
leaderboardItemDecoder =
    map2 LeaderboardItem
        (field "composer" string)
        (field "work" string)


leaderboardDecoder : Decoder (List LeaderboardItem)
leaderboardDecoder =
    list leaderboardItemDecoder



-- COMMANDS


getLeaderboardItems : String -> Cmd Msg
getLeaderboardItems slug =
    Http.get
        { url = "/json/" ++ slug ++ ".json"
        , expect = Http.expectJson GotJson leaderboardDecoder
        }



-- VIEWS


headerPartial : Html Msg
headerPartial =
    header []
        [ div [ class "title" ] [ text "Talkclassical Top Lists" ]
        , div [ class "subtitle" ] [ text "Best works of classical music as voted by talkclassical.com members" ]
        ]


menuPartial : Model -> List Leaderboard -> Html Msg
menuPartial model leaderboards =
    aside []
        [ ul [ class "menu" ] (List.map (menuItemPartial model.selectedListSlug) leaderboards)
        ]


menuItemPartial : String -> Leaderboard -> Html Msg
menuItemPartial currentSlug leaderboard =
    li
        [ onClick (ClickedLeaderboardSlug leaderboard.slug)
        , class
            (if leaderboard.slug == currentSlug then
                "selected"

             else
                ""
            )
        ]
        [ text leaderboard.title ]


contentPartial : Model -> Html Msg
contentPartial model =
    section []
        [ leaderboardTitlePartial (getListBySlug model.allLeaderboards model.selectedListSlug)
        , div [] (List.indexedMap leaderboardItemPartial model.currentLeaderboardItems)
        ]


leaderboardTitlePartial : Leaderboard -> Html Msg
leaderboardTitlePartial leaderboard =
    div []
        [ h1 [] [ text leaderboard.title ]
        , div [ class "list-description" ] [ text leaderboard.description ]
        ]


leaderboardItemPartial : Int -> LeaderboardItem -> Html Msg
leaderboardItemPartial index item =
    div [ class "top-list-item" ]
        [ div [ class "order" ] [ text (String.fromInt (index + 1)) ]
        , div [ class "composer-work" ]
            [ div [ class "composer" ] [ text item.composer ]
            , div [ class "work" ] [ text item.work ]
            ]
        ]


view : Model -> Html Msg
view model =
    let
        leaderboards =
            model.allLeaderboards
    in
    div []
        [ headerPartial
        , div
            [ class "content" ]
            [ menuPartial model leaderboards
            , contentPartial model
            ]
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLeaderboardSlug slugName ->
            ( { model | selectedListSlug = slugName }, getLeaderboardItems slugName )

        GotJson result ->
            case result of
                Ok items ->
                    ( { model | currentLeaderboardItems = items, error = "" }, Cmd.none )

                Err _ ->
                    ( { model | currentLeaderboardItems = [], error = "Could not load JSON data" }, Cmd.none )



-- MAIN


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
