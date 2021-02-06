import ezchakra/[importmc, hookmc, hookos, hookctx, stop, event]

export importmc, hookmc, hookos, stop, event

when defined(chakra):
  {.compile: "ezchakra/forward.cpp".}
  import winim/lean
  import cppinterop/cppstr
  import ezchakra/[log, detect_wine], ezchakra/private/[fsredirect, logcollector, entry, dbengine, crashlog]

  Log.notice("ElementZero is loading...", "STARTUP")

  proc getServerVersionString(): CppString {.hookmc: "?getServerVersionString@Common@@YA?AV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@XZ".} =
    return $getServerVersionString_origin() & " with EZR"

  applyPreHooks()
