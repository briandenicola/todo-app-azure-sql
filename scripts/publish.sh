#!/bin/bash

cd ../src
dotnet publish -c Release -r linux-x64 --self-contained --nologo -o publish/linux -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true
