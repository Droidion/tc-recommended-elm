module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, field, int, list, map2, map3, string)



-- TYPE ALIASES


type alias Leaderboard =
    { description : String
    , slug : String
    , name : String
    }


type alias LeaderboardItem =
    { composer : String
    , composerId : Int
    , work : String
    }


type alias ComposerStat =
    { work : String
    , position : Int
    , slug : String
    }


type alias StructuredComposerStats =
    List
        { leaderboard : String
        , works :
            List ComposerStat
        }


type alias Model =
    { selectedListSlug : String
    , allLeaderboards : List Leaderboard
    , currentLeaderboardItems : List LeaderboardItem
    , composerStats : List ComposerStat
    , currentComposerName : String
    , error : String
    }



-- TYPES


type Msg
    = ClickedLeaderboardSlug String
    | ClickedComposer ( Int, String )
    | GotJsonLeaderboardContent (Result Http.Error (List LeaderboardItem))
    | GotJsonLeaderboards (Result Http.Error (List Leaderboard))
    | GotJsonComposerStats (Result Http.Error (List ComposerStat))



-- MODEL


initialModel : () -> ( Model, Cmd Msg )
initialModel _ =
    ( { selectedListSlug = ""
      , allLeaderboards = []
      , currentLeaderboardItems = []
      , composerStats = []
      , currentComposerName = ""
      , error = ""
      }
    , getLeaderboards
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
            { name = "", description = "", slug = "" }


structuredComposerStats : List ComposerStat -> List Leaderboard -> StructuredComposerStats
structuredComposerStats stats leaderboards =
    leaderboards
        |> List.map
            (\leaderboard ->
                { leaderboard = leaderboard.name
                , works = List.filter (\stat -> stat.slug == leaderboard.slug) stats
                }
            )
        |> List.filter
            (\stat -> not (List.isEmpty stat.works))



-- JSON decoders


singleWorkDecoder : Decoder LeaderboardItem
singleWorkDecoder =
    map3 LeaderboardItem
        (field "composer" string)
        (field "composerId" int)
        (field "work" string)


leaderboardDecoder : Decoder Leaderboard
leaderboardDecoder =
    map3 Leaderboard
        (field "description" string)
        (field "slug" string)
        (field "name" string)


composerStatDecoder : Decoder ComposerStat
composerStatDecoder =
    map3 ComposerStat
        (field "work" string)
        (field "position" int)
        (field "slug" string)


leaderboardContentDecoder : Decoder (List LeaderboardItem)
leaderboardContentDecoder =
    list singleWorkDecoder


leaderboardsListDecoder : Decoder (List Leaderboard)
leaderboardsListDecoder =
    list leaderboardDecoder


composerStatsDecoder : Decoder (List ComposerStat)
composerStatsDecoder =
    list composerStatDecoder



-- COMMANDS


getLeaderboardItems : String -> Cmd Msg
getLeaderboardItems slug =
    Http.get
        { url = "/api/leaderboard/" ++ slug
        , expect = Http.expectJson GotJsonLeaderboardContent leaderboardContentDecoder
        }


getLeaderboards : Cmd Msg
getLeaderboards =
    Http.get
        { url = "/api/leaderboards"
        , expect = Http.expectJson GotJsonLeaderboards leaderboardsListDecoder
        }


getComposerStats : Int -> Cmd Msg
getComposerStats composerId =
    Http.get
        { url = "/api/composer/" ++ String.fromInt composerId
        , expect = Http.expectJson GotJsonComposerStats composerStatsDecoder
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
        [ div [] [ text model.error ]
        , ul [ class "menu" ] (List.map (menuItemPartial model.selectedListSlug) leaderboards)
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
        [ text leaderboard.name ]


leaderboardPartial : Model -> Html Msg
leaderboardPartial model =
    section []
        [ leaderboardTitlePartial (getListBySlug model.allLeaderboards model.selectedListSlug)
        , div [] (List.indexedMap leaderboardItemPartial model.currentLeaderboardItems)
        ]


composerStatsPartial : Model -> Html Msg
composerStatsPartial model =
    section []
        [ h1 [] [ text model.currentComposerName ]
        , composerStatsItemPartial
            (structuredComposerStats model.composerStats model.allLeaderboards)
        ]


composerStatsItemPartial : StructuredComposerStats -> Html Msg
composerStatsItemPartial stats =
    div []
        (List.map
            (\stat ->
                div []
                    [ h2 [] [ text stat.leaderboard ]
                    , div []
                        (List.map
                            (\work ->
                                div [ class "top-list-item" ]
                                    [ div [ class "order" ] [ text (String.fromInt work.position) ]
                                    , div [ class "composer-work composer" ] [ text work.work ]
                                    ]
                            )
                            stat.works
                        )
                    ]
            )
            stats
        )


leaderboardTitlePartial : Leaderboard -> Html Msg
leaderboardTitlePartial leaderboard =
    div []
        [ h1 [] [ text leaderboard.name ]
        , div [ class "list-description" ] [ text leaderboard.description ]
        ]


leaderboardItemPartial : Int -> LeaderboardItem -> Html Msg
leaderboardItemPartial index item =
    div [ class "top-list-item" ]
        [ div [ class "order" ] [ text (String.fromInt (index + 1)) ]
        , div [ class "composer-work" ]
            [ div [ class "composer clickable", onClick (ClickedComposer ( item.composerId, item.composer )) ] [ text item.composer ]
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
            , if String.isEmpty model.selectedListSlug then
                composerStatsPartial model

              else
                leaderboardPartial model
            ]
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedComposer ( composerId, composerName ) ->
            ( { model | selectedListSlug = "", currentLeaderboardItems = [], currentComposerName = composerName }, getComposerStats composerId )

        ClickedLeaderboardSlug slugName ->
            ( { model | selectedListSlug = slugName }, getLeaderboardItems slugName )

        GotJsonLeaderboardContent result ->
            case result of
                Ok items ->
                    ( { model | currentLeaderboardItems = items, error = "" }, Cmd.none )

                Err _ ->
                    ( { model | currentLeaderboardItems = [], error = "Could not load JSON data" }, Cmd.none )

        GotJsonComposerStats result ->
            case result of
                Ok items ->
                    ( { model | composerStats = items, error = "" }, Cmd.none )

                Err _ ->
                    ( { model | composerStats = [], error = "Could not load JSON data" }, Cmd.none )

        GotJsonLeaderboards result ->
            case result of
                Ok items ->
                    let
                        firstSlug =
                            case List.head items of
                                Just item ->
                                    item.slug

                                Nothing ->
                                    ""
                    in
                    ( { model
                        | allLeaderboards = items
                        , error = ""
                        , selectedListSlug = firstSlug
                      }
                    , getLeaderboardItems firstSlug
                    )

                Err _ ->
                    ( { model | allLeaderboards = [], error = "Could not load JSON data" }, Cmd.none )



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
