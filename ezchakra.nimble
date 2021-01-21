# Package

version       = "0.1.0"
author        = "CodeHz"
description   = "Chakra for ElementZero"
license       = "LGPL-3.0"
srcDir        = "."
installExt    = @["nim", "dll", "pdb"]


# Dependencies

requires "nim >= 1.4.2"
requires "winim, ezutils, cppinterop, ezsqlite3, ezfunchook, ezpdbparser"

from os import `/`
from strutils import strip

task prepare, "Prepare":
  mkDir "dist"
  cpFile(gorge("nimble path ezsqlite3").strip / "sqlite3.dll", "sqlite3.dll")
  cpFile(gorge("nimble path ezfunchook").strip / "funchook.dll", "funchook.dll")

task build_dll, "Build chakra.dll":
  exec "nimble cpp --cc:clang_cl --app:lib --passC:/MD -d:chakra -o:chakra.dll --gc:arc ezchakra.nim"

before build_dll:
  prepareTask()

before install:
  build_dllTask()