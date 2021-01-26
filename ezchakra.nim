import ezchakra/[importmc, hookmc]

export importmc, hookmc

when defined(chakra):
  {.compile: "ezchakra/forward.cpp".}
  import os

  import ezchakra/hookctx
  import winim/lean
  import cppinterop/cppstr
  import ezchakra/fsredirect

  proc getServerVersionString(): CppString {.hookmc: "?getServerVersionString@Common@@YA?AV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@XZ".} =
    return $getServerVersionString_origin() & " with EZR"

  for folder in walkDirRec("mods", {pcDir, pcLinkToDir}, {pcDir, pcLinkToDir}):
    for module in walkFiles(folder / "*.dll"):
      LoadLibrary(module)

  applyHooks()