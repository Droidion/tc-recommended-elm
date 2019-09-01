module Main exposing (main)

import Browser
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, field, int, list, map2, map3, map4, string)
import Task
import Url
import Url.Parser exposing ((</>), Parser, int, map, oneOf, s, string)



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
    { name : String
    , work : String
    , position : Int
    , slug : String
    }


type alias BestComposer =
    { composerId : Int
    , composerName : String
    , rating : Int
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
    , bestComposers : List BestComposer
    , error : String
    , key : Nav.Key
    , url : Url.Url
    }



-- TYPES


type Msg
    = GotJsonLeaderboardContent (Result Http.Error (List LeaderboardItem))
    | GotJsonLeaderboards (Result Http.Error (List Leaderboard))
    | GotJsonComposerStats (Result Http.Error (List ComposerStat))
    | GotJsonBestComposers (Result Http.Error (List BestComposer))
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoAction


type Route
    = HomeRoute
    | BestComposers
    | ComposerRoute Int
    | LeaderboardRoute String



-- MODEL


initialModel : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
initialModel flags url key =
    let
        parsed =
            Url.Parser.parse routeParser url

        model =
            { selectedListSlug = ""
            , allLeaderboards = []
            , currentLeaderboardItems = []
            , composerStats = []
            , currentComposerName = ""
            , bestComposers = []
            , error = ""
            , key = key
            , url = url
            }
    in
    processUrl model url



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


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map HomeRoute (s "")
        , map BestComposers (s "best-composers")
        , map ComposerRoute (s "composer" </> Url.Parser.int)
        , map LeaderboardRoute (s "leaderboard" </> Url.Parser.string)
        ]


processUrl : Model -> Url.Url -> ( Model, Cmd Msg )
processUrl model url =
    let
        parsed =
            Url.Parser.parse routeParser url
    in
    case parsed of
        Just (ComposerRoute composerId) ->
            ( { model | url = url, selectedListSlug = "", currentLeaderboardItems = [], currentComposerName = "", bestComposers = [] }, Cmd.batch [ getLeaderboards model, getComposerStats composerId ] )

        Just (LeaderboardRoute slug) ->
            ( { model | url = url, selectedListSlug = slug, bestComposers = [] }, Cmd.batch [ getLeaderboards model, getLeaderboardItems slug, resetViewport ] )

        Just HomeRoute ->
            ( { model | url = url, selectedListSlug = "orchestral", bestComposers = [] }, Cmd.batch [ getLeaderboards model, getLeaderboardItems "orchestral", resetViewport ] )

        Just BestComposers ->
            ( { model | url = url, selectedListSlug = "" }, Cmd.batch [ getLeaderboards model, getBestComposers, resetViewport ] )

        _ ->
            ( { model | url = url, selectedListSlug = "orchestral", bestComposers = [] }, Cmd.batch [ getLeaderboards model, getLeaderboardItems "orchestral", resetViewport ] )



-- JSON decoders


singleWorkDecoder : Decoder LeaderboardItem
singleWorkDecoder =
    map3 LeaderboardItem
        (field "composer" Json.Decode.string)
        (field "composerId" Json.Decode.int)
        (field "work" Json.Decode.string)


leaderboardDecoder : Decoder Leaderboard
leaderboardDecoder =
    map3 Leaderboard
        (field "description" Json.Decode.string)
        (field "slug" Json.Decode.string)
        (field "name" Json.Decode.string)


composerStatDecoder : Decoder ComposerStat
composerStatDecoder =
    map4 ComposerStat
        (field "name" Json.Decode.string)
        (field "work" Json.Decode.string)
        (field "position" Json.Decode.int)
        (field "slug" Json.Decode.string)


bestComposerDecoder : Decoder BestComposer
bestComposerDecoder =
    map3 BestComposer
        (field "composerId" Json.Decode.int)
        (field "composerName" Json.Decode.string)
        (field "rating" Json.Decode.int)


leaderboardContentDecoder : Decoder (List LeaderboardItem)
leaderboardContentDecoder =
    list singleWorkDecoder


leaderboardsListDecoder : Decoder (List Leaderboard)
leaderboardsListDecoder =
    list leaderboardDecoder


composerStatsDecoder : Decoder (List ComposerStat)
composerStatsDecoder =
    list composerStatDecoder


bestComposersDecoder : Decoder (List BestComposer)
bestComposersDecoder =
    list bestComposerDecoder



-- COMMANDS


getLeaderboardItems : String -> Cmd Msg
getLeaderboardItems slug =
    Http.get
        { url = "/api/leaderboard/" ++ slug
        , expect = Http.expectJson GotJsonLeaderboardContent leaderboardContentDecoder
        }


getLeaderboards : Model -> Cmd Msg
getLeaderboards model =
    if List.isEmpty model.allLeaderboards then
        Http.get
            { url = "/api/leaderboards"
            , expect = Http.expectJson GotJsonLeaderboards leaderboardsListDecoder
            }

    else
        Cmd.none


getComposerStats : Int -> Cmd Msg
getComposerStats composerId =
    Http.get
        { url = "/api/composer/" ++ String.fromInt composerId
        , expect = Http.expectJson GotJsonComposerStats composerStatsDecoder
        }


getBestComposers : Cmd Msg
getBestComposers =
    Http.get
        { url = "/api/best-composers"
        , expect = Http.expectJson GotJsonBestComposers bestComposersDecoder
        }


resetViewport : Cmd Msg
resetViewport =
    Task.perform (\_ -> NoAction) (Dom.setViewport 0 0)



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
        , ul [ class "menu" ]
            (li
                [ class
                    (if List.isEmpty model.bestComposers then
                        ""

                     else
                        "selected"
                    )
                ]
                [ a [ href "/best-composers" ] [ text "Best composers" ] ]
                :: List.map (menuItemPartial model.selectedListSlug) leaderboards
            )
        ]


menuItemPartial : String -> Leaderboard -> Html Msg
menuItemPartial currentSlug leaderboard =
    li
        [ class
            (if leaderboard.slug == currentSlug then
                "selected"

             else
                ""
            )
        ]
        [ a [ href ("/leaderboard/" ++ leaderboard.slug) ] [ text leaderboard.name ]
        ]


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
            [ div [ class "composer clickable" ]
                [ a [ href ("/composer/" ++ String.fromInt item.composerId) ] [ text item.composer ]
                ]
            , div [ class "work" ] [ text item.work ]
            ]
        ]


bestComposersPartial : Model -> Html Msg
bestComposersPartial model =
    section []
        [ h1
            []
            [ text "Best Composers" ]
        , div []
            (List.indexedMap
                (\ind el ->
                    div [ class "top-list-item" ]
                        [ div [ class "order" ] [ text (String.fromInt (ind + 1)) ]
                        , div [ class "composer-work" ]
                            [ div [ class "composer clickable" ]
                                [ a [ href ("/composer/" ++ String.fromInt el.composerId) ] [ text el.composerName ]
                                ]
                            , div [ class "work" ] [ text (String.fromInt el.rating) ]
                            ]
                        ]
                )
                model.bestComposers
            )
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
            , if not (String.isEmpty model.selectedListSlug) then
                leaderboardPartial model

              else if not (List.isEmpty model.bestComposers) then
                bestComposersPartial model

              else
                composerStatsPartial model
            ]
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoAction ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            processUrl model url

        GotJsonLeaderboardContent result ->
            case result of
                Ok items ->
                    ( { model | currentLeaderboardItems = items, error = "" }, Cmd.none )

                Err _ ->
                    ( { model | currentLeaderboardItems = [], error = "Could not load JSON data" }, Cmd.none )

        GotJsonComposerStats result ->
            case result of
                Ok items ->
                    ( { model
                        | composerStats = items
                        , currentComposerName =
                            case List.head items of
                                Just item ->
                                    item.name

                                Nothing ->
                                    ""
                        , error = ""
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | composerStats = [], error = "Could not load JSON data" }, Cmd.none )

        GotJsonBestComposers result ->
            case result of
                Ok items ->
                    ( { model
                        | bestComposers = items
                        , error = ""
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | bestComposers = [], error = "Could not load JSON data" }, Cmd.none )

        GotJsonLeaderboards result ->
            case result of
                Ok items ->
                    ( { model
                        | allLeaderboards = items
                        , error = ""
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | allLeaderboards = [], error = "Could not load JSON data" }, Cmd.none )



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = initialModel
        , subscriptions = subscriptions
        , update = update
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        , view =
            \m ->
                { title = "TC Recommended"
                , body = [ view m ]
                }
        }
