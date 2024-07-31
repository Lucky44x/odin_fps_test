@echo off
if not exist "bin\debug" mkdir "bin\debug"
odin build "src/main.odin" -file -out=./bin/debug/game.exe -debug