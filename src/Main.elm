module Main exposing (main)

import Browser
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick)
import TopList


type alias TopList =
    { description : String
    , slug : String
    , title : String
    }


type alias Model =
    { selectedListSlug : String
    , allTopLists :
        List TopList
    }


type Msg
    = ClickedTopListSlug String


initialModel : Model
initialModel =
    { selectedListSlug = "keyboard-concerti"
    , allTopLists = TopList.lists
    }


getListBySlug : String -> TopList
getListBySlug slug =
    let
        list =
            initialModel.allTopLists
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
        , listElemFull (getListBySlug model.selectedListSlug)
        ]


update : Msg -> Model -> Model
update msg model =
    case ( msg, model ) of
        ( ClickedTopListSlug slugName, _ ) ->
            { model | selectedListSlug = slugName }


main =
    Browser.sandbox
        { init = initialModel
        , view = view >> toUnstyled
        , update = update
        }
