import ezchakra/[importmc, hookmc, hookos, hookctx, stop]

export importmc, hookmc, hookos, stop

when defined(chakra):
  {.compile: "ezchakra/forward.cpp".}
  import winim/lean
  import cppinterop/cppstr
  import ezchakra/[fsredirect, ipc]

  proc getServerVersionString(): CppString {.hookmc: "?getServerVersionString@Common@@YA?AV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@XZ".} =
    return $getServerVersionString_origin() & " with EZR"

  proc main(argc: int; argv, envp: cstringArray): int {.hookmc: "main".} =
    if ipcValid():
      ipcSync RequestPacket(kind: req_ping), res:
        echo res
        applyHooks()
    main_origin(argc, argv, envp)

  applyPreHooks()
