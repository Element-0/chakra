# Package

version       = "0.1.0"
author        = "CodeHz"
description   = "Chakra for ElementZero"
license       = "LGPL-3.0"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.2"
requires "winim, ezutils, cppinterop, ezsqlite3, ezfunchook"

task build-dll, "Build chakra.dll":
  exec "nim cpp --cc:clang_cl --app:lib --passC:/MD -d:chakra -o:chakra.dll src/ezchakra.nim"