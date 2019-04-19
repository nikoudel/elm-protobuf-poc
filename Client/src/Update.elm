module Update exposing (..)

import Http
import Messages
import Protobuf.Decode as PbDecode
import Protobuf.Encode as PbEncode


type alias Model =
    { error : String
    , make : String
    , model : String
    , year : String
    , price : String
    , email : String
    , cars : List Messages.Car
    }


type Msg
    = GotResponse (Result Http.Error Messages.Cars)
    | MakeChanged String
    | ModelChanged String
    | YearChanged String
    | PriceChanged String
    | EmailChanged String
    | Submitted
    | Clear
    | ErrorClosed


emptyModel : Model
emptyModel =
    Model "" "" "" "" "" "" []


createBody : PbEncode.Encoder -> Http.Body
createBody encoder =
    Http.bytesBody "application/protobuf" (PbEncode.encode encoder)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse result ->
            case result of
                Ok r ->
                    if r.error == "" then
                        ( { emptyModel | cars = r.cars }, Cmd.none )
                    else
                        ( { model | error = r.error }, Cmd.none )

                Err e ->
                    ( { model | error = httpErrorString e }, Cmd.none )

        MakeChanged v ->
            ( { model | make = v }, Cmd.none )

        ModelChanged v ->
            ( { model | model = v }, Cmd.none )

        YearChanged v ->
            ( { model | year = v }, Cmd.none )

        PriceChanged v ->
            ( { model | price = v }, Cmd.none )

        EmailChanged v ->
            ( { model | email = v }, Cmd.none )

        ErrorClosed ->
            ( { model | error = "" }, Cmd.none )

        Submitted ->
            case validate model of
                Ok car ->
                    ( model
                    , Http.post
                        { url = "/car"
                        , body = car |> Messages.toCarEncoder |> createBody
                        , expect = PbDecode.expectBytes GotResponse Messages.carsDecoder
                        }
                    )

                Err e ->
                    ( { model | error = e }, Cmd.none )

        Clear ->
            ( { emptyModel | cars = model.cars }, Cmd.none )


validate : Model -> Result String Messages.Car
validate model =
    let
        year =
            case String.toInt model.year of
                Just val ->
                    Ok val

                Nothing ->
                    Err ("Failed parsing Registration year as integer: '" ++ model.year ++ "'")

        price =
            case String.toFloat model.price of
                Just val ->
                    Ok val

                Nothing ->
                    Err ("Failed parsing Price as float: '" ++ model.price ++ "'")
    in
    case ( year, price ) of
        ( Ok y, Ok p ) ->
            Ok (Messages.Car model.make model.model y p model.email)

        ( Err y, _ ) ->
            Err y

        ( _, Err p ) ->
            Err p


httpErrorString : Http.Error -> String
httpErrorString e =
    case e of
        Http.BadUrl url ->
            "Bad URL: " ++ url

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus code ->
            "Request failed with status code " ++ String.fromInt code

        Http.BadBody text ->
            "Bad body: " ++ text
