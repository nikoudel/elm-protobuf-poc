#!/usr/bin/env sh
set -euxo pipefail

export PATH="/usr/bin:\
/c/Program Files/nodejs:\
/c/Users/$USERNAME/AppData/Roaming/npm:\
/c/Program Files (x86)/Elm/0.19/bin:\
/c/Windows/System32/WindowsPowerShell/v1.0"

cd "$(dirname "$0")/Client"

mkdir -p build

powershell.exe -NoProfile -Command ../build-proto.ps1
elm-format --yes src/

elm make src/Main.elm --optimize --output=build/app.js

uglifyjs build/app.js -o build/app.min.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe'
uglifyjs --mangle --output=../Server/Server/wwwroot/app.min.js build/app.min.js