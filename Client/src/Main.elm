module Main exposing (..)

import Browser
import Http
import Messages
import Protobuf.Decode as PbDecode
import Update
import View


main =
    Browser.element
        { init = init
        , update = Update.update
        , view = View.view
        , subscriptions = subscriptions
        }


init : () -> ( Update.Model, Cmd Update.Msg )
init _ =
    ( Update.emptyModel
    , Http.get
        { url = "/cars"
        , expect = PbDecode.expectBytes Update.GotResponse Messages.carsDecoder
        }
    )


subscriptions : Update.Model -> Sub Update.Msg
subscriptions model =
    Sub.none
