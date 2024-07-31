@echo off
if not exist "bin\release" mkdir "bin\release"
odin build "src/main.odin" -file -out=./bin/release/game.exe