module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Messages
import Update


view : Update.Model -> Html Update.Msg
view model =
    div []
        (choose
            [ Just (getTopSection model)
            , getBottomSection model
            ]
        )


getTopSection : Update.Model -> Html Update.Msg
getTopSection { error, make, model, year, price, email, cars } =
    section [ class "section" ]
        [ div [ class "container" ]
            [ article (hideUnlessError error [ class "message is-danger" ])
                [ div [ class "message-header" ]
                    [ p []
                        [ text "Error!" ]
                    , button [ attribute "aria-label" "delete", class "delete", onClick Update.ErrorClosed ]
                        []
                    ]
                , div [ class "message-body" ]
                    [ text error ]
                ]
            , Html.form [ novalidate True, onSubmit Update.Submitted ]
                [ div [ class "field" ]
                    [ label [ class "label" ]
                        [ text "Make" ]
                    , div [ class "control" ]
                        [ viewInput "input"
                            "text"
                            make
                            Update.MakeChanged
                        ]
                    ]
                , div [ class "field" ]
                    [ label [ class "label" ]
                        [ text "Model" ]
                    , div [ class "control" ]
                        [ viewInput "input"
                            "text"
                            model
                            Update.ModelChanged
                        ]
                    ]
                , div [ class "field" ]
                    [ label [ class "label" ]
                        [ text "Registration year" ]
                    , div [ class "control" ]
                        [ viewInput "input"
                            "text"
                            year
                            Update.YearChanged
                        ]
                    ]
                , div [ class "field" ]
                    [ label [ class "label" ]
                        [ text "Price" ]
                    , div [ class "control" ]
                        [ viewInput "input"
                            "text"
                            price
                            Update.PriceChanged
                        ]
                    ]
                , div [ class "field" ]
                    [ label [ class "label" ]
                        [ text "Owner e-mail" ]
                    , div [ class "control" ]
                        [ viewInput "input"
                            "text"
                            email
                            Update.EmailChanged
                        ]
                    ]
                , div [ class "field is-grouped" ]
                    [ div [ class "control" ]
                        [ button [ class "button is-link", type_ "submit" ]
                            [ text "Submit" ]
                        ]
                    , div [ class "control" ]
                        [ button [ class "button is-text", type_ "button", onClick Update.Clear ]
                            [ text "Clear" ]
                        ]
                    ]
                ]
            ]
        ]


getBottomSection : Update.Model -> Maybe (Html Update.Msg)
getBottomSection { error, make, model, year, price, email, cars } =
    case cars of
        [] ->
            Nothing

        _ ->
            Just
                (section [ class "section" ]
                    [ div [ class "container" ]
                        [ table [ class "table is-bordered is-striped is-narrow is-hoverable is-fullwidth" ]
                            [ tbody [] (tableHeader :: List.map toCarView cars) ]
                        ]
                    ]
                )


tableHeader : Html Update.Msg
tableHeader =
    tr []
        [ th [] [ text "Make" ]
        , th [] [ text "Model" ]
        , th [] [ text "Registration year" ]
        , th [] [ text "Price" ]
        , th [] [ text "Owner e-mail" ]
        ]


toCarView : Messages.Car -> Html Update.Msg
toCarView car =
    tr []
        [ td [] [ text car.make ]
        , td [] [ text car.model ]
        , td [] [ text (car.registrationYear |> String.fromInt) ]
        , td [] [ text (car.price |> String.fromFloat) ]
        , td [] [ text car.ownerEmail ]
        ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput c t v toMsg =
    input [ class c, type_ t, value v, onInput toMsg ] []


hideUnlessError : String -> List (Attribute msg) -> List (Attribute msg)
hideUnlessError error attributes =
    if error == "" then
        style "display" "none" :: attributes
    else
        attributes


choose : List (Maybe a) -> List a
choose list =
    let
        chooser item =
            case item of
                Just value ->
                    [ value ]

                Nothing ->
                    []
    in
    list |> List.map chooser |> List.concat
