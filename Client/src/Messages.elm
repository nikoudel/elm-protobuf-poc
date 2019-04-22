{- !!! DO NOT EDIT THIS FILE MANUALLY !!! -}


module Messages
    exposing
        ( Car
        , Cars
        , carDecoder
        , carsDecoder
        , toCarEncoder
        , toCarsEncoder
        )

{-| ProtoBuf module: `Messages`

This module was generated automatically using

  - [`protoc-gen-elm`](https://www.npmjs.com/package/protoc-gen-elm) 1.0.0-beta-1
  - [`elm-protocol-buffers`](https://package.elm-lang.org/packages/eriktim/elm-protocol-buffers/1.0.0) 1.0.0
  - `protoc` 3.7.1
  - the following specification file:
      - `Messages.proto`


# Model

@docs Car, Cars


# Decoder

@docs carDecoder, carsDecoder


# Encoder

@docs toCarEncoder, toCarsEncoder

-}

import Protobuf.Decode as Decode
import Protobuf.Encode as Encode


-- MODEL


{-| Car
-}
type alias Car =
    { make : String
    , model : String
    , registrationYear : Int
    , price : Float
    , ownerEmail : String
    }


{-| Cars
-}
type alias Cars =
    { error : String
    , cars : List Car
    }



-- DECODER


carDecoder : Decode.Decoder Car
carDecoder =
    Decode.message (Car "" "" 0 0 "")
        [ Decode.optional 1 Decode.string setMake
        , Decode.optional 2 Decode.string setModel
        , Decode.optional 3 Decode.int32 setRegistrationYear
        , Decode.optional 4 Decode.double setPrice
        , Decode.optional 5 Decode.string setOwnerEmail
        ]


carsDecoder : Decode.Decoder Cars
carsDecoder =
    Decode.message (Cars "" [])
        [ Decode.optional 1 Decode.string setError
        , Decode.repeated 2 carDecoder .cars setCars
        ]



-- ENCODER


toCarEncoder : Car -> Encode.Encoder
toCarEncoder model =
    Encode.message
        [ ( 1, Encode.string model.make )
        , ( 2, Encode.string model.model )
        , ( 3, Encode.int32 model.registrationYear )
        , ( 4, Encode.double model.price )
        , ( 5, Encode.string model.ownerEmail )
        ]


toCarsEncoder : Cars -> Encode.Encoder
toCarsEncoder model =
    Encode.message
        [ ( 1, Encode.string model.error )
        , ( 2, Encode.list toCarEncoder model.cars )
        ]



-- SETTERS


setMake : a -> { b | make : a } -> { b | make : a }
setMake value model =
    { model | make = value }


setModel : a -> { b | model : a } -> { b | model : a }
setModel value model =
    { model | model = value }


setRegistrationYear : a -> { b | registrationYear : a } -> { b | registrationYear : a }
setRegistrationYear value model =
    { model | registrationYear = value }


setPrice : a -> { b | price : a } -> { b | price : a }
setPrice value model =
    { model | price = value }


setOwnerEmail : a -> { b | ownerEmail : a } -> { b | ownerEmail : a }
setOwnerEmail value model =
    { model | ownerEmail = value }


setError : a -> { b | error : a } -> { b | error : a }
setError value model =
    { model | error = value }


setCars : a -> { b | cars : a } -> { b | cars : a }
setCars value model =
    { model | cars = value }
