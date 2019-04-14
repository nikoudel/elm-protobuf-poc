Param(
    [string]$protocVersion = "3.7.1-win64"
)

$ErrorActionPreference = "Stop"

$protoc = "$PSScriptRoot\protobuf\protoc\protoc-$protocVersion\bin\protoc.exe"

if (!(Test-Path $protoc))
{
    # Get protoc.exe from https://github.com/protocolbuffers/protobuf/releases
    New-Item -Path "$PSScriptRoot\protobuf\protoc" -ItemType Directory -Force | Out-Null
    Invoke-WebRequest "https://github.com/protocolbuffers/protobuf/releases/download/v3.7.1/protoc-$protocVersion.zip" -OutFile "$PSScriptRoot\protobuf\protoc\protoc-$protocVersion.zip"
    Expand-Archive -Path "$PSScriptRoot\protobuf\protoc\protoc-$protocVersion.zip" -DestinationPath "$PSScriptRoot\protobuf\protoc\protoc-$protocVersion"
}

& $protoc `
    --proto_path="$PSScriptRoot\protobuf" `
    --csharp_out=$PSScriptRoot\Server\Messages `
    $PSScriptRoot\protobuf\Car.proto