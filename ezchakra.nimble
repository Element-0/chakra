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

const chakracorelink = "https://github.com/Element-0/Dependencies/releases/download/chakracore-51d75d0efa9d334ee3c15fc87342205971a6f69d/ChakraCore.dll"

task prepare, "Prepare":
  cpFile(gorge("nimble path ezsqlite3").strip / "sqlite3.dll", "sqlite3.dll")
  cpFile(gorge("nimble path ezfunchook").strip / "funchook.dll", "funchook.dll")
  if not fileExists "./ChakraCore.dll":
    exec "curl -Lo ChakraCore.dll " & chakracorelink

task build_dll, "Build chakra.dll":
  exec "nimble cpp --cc:clang_cl --app:lib --passC:/MD -d:chakra -o:chakra.dll --gc:arc ezchakra.nim"

before install:
  prepareTask()
  build_dllTask()