FROM microsoft/dotnet:2.2-sdk as builder
LABEL stage=intermediate
COPY . /usr/local/build/
WORKDIR /usr/local/build
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && apt-get install -y nodejs
RUN npm install -g elm@elm0.19.0 --unsafe-perm=true
RUN npm install -g protoc-gen-elm
RUN npm install -g uglify-js
RUN apt-get install unzip
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v3.7.1/protoc-3.7.1-linux-x86_64.zip
RUN unzip protoc-3.7.1-linux-x86_64.zip -d ./protoc
RUN ./protoc/bin/protoc --proto_path="./protobuf" --csharp_out="./Server/Messages" --elm_out="./Client/src" ./protobuf/Messages.proto
WORKDIR /usr/local/build/Client
RUN elm make src/Main.elm --optimize --output=build/app.js
RUN uglifyjs build/app.js -o build/app.min.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe'
RUN uglifyjs --mangle --output=../Server/Server/wwwroot/app.min.js build/app.min.js
WORKDIR /usr/local/build/Server/Server
RUN dotnet publish -f netcoreapp2.2 -c Release

FROM microsoft/dotnet:2.2-aspnetcore-runtime 
COPY --from=builder /usr/local/build/Server/Server/bin/Release/netcoreapp2.2/publish /usr/local/app
WORKDIR /usr/local/app
CMD dotnet Server.dll
