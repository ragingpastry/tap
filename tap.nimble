# Package

version       = "0.1.0"
author        = "Nick Wilburn"
description   = "Start GitlabCI pipelines from the CLI"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["tap"]


# Dependencies

requires "nim >= 1.6.0"
requires "argparse >= 2.0.1"

# Tasks
task test, "Runs the test suite":
    exec "testament cat /"

task muslbuild, "Builds the project":
    exec "nimble --accept install argparse@2.0.1"
    exec "nim musl --gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc -d:libressl --passL:\"-static\" -d:release --opt:size src/tap.nim"
