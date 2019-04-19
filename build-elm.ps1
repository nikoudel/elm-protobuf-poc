Push-Location "$PSScriptRoot\Client"

try {
    elm-format --yes src/
    elm make src/Main.elm --output=../server/server/wwwroot/app.js
} finally {
    Pop-Location
}