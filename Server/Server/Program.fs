module Server.App

open FSharp.Control.Tasks.V2
open Giraffe
open Google.Protobuf
open Messages
open Microsoft.AspNetCore.Builder
open Microsoft.AspNetCore.Hosting
open Microsoft.AspNetCore.Http
open Microsoft.Extensions.DependencyInjection
open Microsoft.Extensions.Logging
open System
open System.IO
open System.Text.RegularExpressions
open Microsoft.AspNetCore.ResponseCompression

// ---------------------------------
// Car storage
// ---------------------------------

type ClientRequest = 
    | CreateCar of Car
    | GetCars of AsyncReplyChannel<seq<Car>>

let carRegistry = MailboxProcessor.Start (fun inbox ->

    let mutable cars = List.empty<Car>

    let rec messageLoop() = async {

        match! inbox.Receive() with
        | CreateCar car ->
            cars <- car :: (if cars.Length > 9 then List.take 9 cars else cars)
        | GetCars ch ->
            ch.Reply cars

        return! messageLoop()  
    }

    messageLoop()
)

// ---------------------------------
// Views
// ---------------------------------

let elmScript =
    if File.Exists "wwwroot/app.min.js"
    then "/app.min.js"
    else "/app.js"

module Views =
    open GiraffeViewEngine

    let index () =
        html [] [
            head [] [
                meta [ _charset "UTF-8" ] 
                meta [ _name "viewport"; _content "width=device-width, initial-scale=1" ] 
                title []  [ encodedText "server" ]
                link [
                    _rel  "stylesheet"
                    _type "text/css"
                    _href "//cdnjs.cloudflare.com/ajax/libs/bulma/0.7.4/css/bulma.min.css" ]
                script [
                    _defer
                    _src "//use.fontawesome.com/releases/v5.8.1/js/all.js"
                    _integrity "sha384-g5uSoOSBd7KkhAMlnQILrecXvzst9TdC09/VM+pjDTCM+1il8RHz5fKANTFFb+gQ"
                    _crossorigin "anonymous" ] []
                script [ _src elmScript ] []
            ]
            body [] [
                div [ _id "elm" ] []
                script [ _src "/load-app.js" ] []
            ]
        ]

// ---------------------------------
// Request handlers
// ---------------------------------

let protobufContentType = "application/protobuf"
let registryReplyTimeoutMs = 100
let emailRegex = @"\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*"

let indexHandler () =
    Views.index () |> htmlView

let validateCar (car: Messages.Car) =
    if not (Regex.IsMatch(car.OwnerEmail, emailRegex)) then
        Some "invalid e-mail"
    else if car.Make = "" then
        Some "Make must not be empty"
    else if car.Model = "" then
        Some "Model must not be empty"
    else if car.Price = 0.0f then
        Some "Price must not be zero"
    else if car.RegistrationYear < 1800 || car.RegistrationYear > 2100 then
        Some "Invalid registration year"
    else
        None

let addCarHandler =
  fun (next : HttpFunc) (ctx : HttpContext) ->
        task {
            ctx.SetHttpHeader "Content-Type" protobufContentType

            let car = Car.Parser.ParseFrom(ctx.Request.Body)

            match validateCar car with
            | Some error ->
                let! cars = carRegistry.PostAndAsyncReply (GetCars, registryReplyTimeoutMs)
                let response = new Messages.Cars(Error = error)

                response.Cars_.AddRange(cars)

                return! ctx.WriteBytesAsync (response.ToByteArray())

            | None ->
                carRegistry.Post (CreateCar car)

                let! cars = carRegistry.PostAndAsyncReply (GetCars, registryReplyTimeoutMs)
                let response = new Messages.Cars(Error = "")

                response.Cars_.AddRange(cars)

                return! ctx.WriteBytesAsync (response.ToByteArray())
        }

let getCarsHandler =
  fun (next : HttpFunc) (ctx : HttpContext) ->
        task {
            ctx.SetHttpHeader "Content-Type" protobufContentType

            let! cars = carRegistry.PostAndAsyncReply (GetCars, registryReplyTimeoutMs)
            let response = new Messages.Cars(Error = "")

            response.Cars_.AddRange(cars)

            return! ctx.WriteBytesAsync (response.ToByteArray())
        }

// ---------------------------------
// Request routing
// ---------------------------------

let webApp =
    choose [
        GET >=>
            choose [
                route "/" >=> indexHandler ()
                route "/cars" >=> getCarsHandler
            ]
        POST >=>
            choose [
                route "/car" >=> addCarHandler
            ]
        setStatusCode 404 >=> text "Not Found" ]

// ---------------------------------
// Error handler
// ---------------------------------

let errorHandler (ex : Exception) (logger : ILogger) =
    logger.LogError(ex, "An unhandled exception has occurred while executing the request.")
    clearResponse >=> setStatusCode 500 >=> text ex.Message

// ---------------------------------
// Configuration
// ---------------------------------

let configureApp (app : IApplicationBuilder) =
    let env = app.ApplicationServices.GetService<IHostingEnvironment>()
    (match env.IsDevelopment() with
    | true  -> app.UseDeveloperExceptionPage()
    | false -> app.UseGiraffeErrorHandler errorHandler)
        .UseResponseCompression()
        .UseStaticFiles()
        .UseGiraffe(webApp)

let configureServices (services : IServiceCollection) =
    services
        .AddResponseCompression(fun options ->
            options.Providers.Add<GzipCompressionProvider>()
            options.MimeTypes <- Seq.append [protobufContentType] ResponseCompressionDefaults.MimeTypes)
        .AddGiraffe() |> ignore

let configureLogging (builder : ILoggingBuilder) =
    builder.AddFilter(fun l -> l.Equals LogLevel.Error)
           .AddConsole()
           .AddDebug() |> ignore

[<EntryPoint>]
let main _ =

    let contentRoot = Directory.GetCurrentDirectory()
    let wwwroot = Path.Combine(contentRoot, "wwwroot")

    WebHostBuilder()
        .UseKestrel()
        .UseContentRoot(contentRoot)
        .UseWebRoot(wwwroot)
        .Configure(Action<IApplicationBuilder> configureApp)
        .ConfigureServices(configureServices)
        .ConfigureLogging(configureLogging)
        .Build()
        .Run()
    0