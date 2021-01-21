# Package

version       = "0.1.0"
author        = "CodeHz"
description   = "Chakra for ElementZero"
license       = "LGPL-3.0"
srcDir        = "."


# Dependencies

requires "nim >= 1.4.2"
requires "winim, ezutils, cppinterop, ezsqlite3, ezfunchook, ezpdbparser"

task build_dll, "Build chakra.dll":
  exec "nimble cpp --cc:clang_cl --app:lib --passC:/MD -d:chakra -o:chakra.dll src/ezchakra.nim"