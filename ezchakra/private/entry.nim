import ../hookmc, ../ipc, ../hookctx, ../log

proc main(argc: int; argv, envp: cstringArray): int {.hookmc: "main".} =
  if ipcValid():
    ipcSync RequestPacket(kind: req_ping), res:
      Log.debug("Checkpoint reached", "STARTUP", pong: $res)
      applyHooks()
  result = main_origin(argc, argv, envp)
  ipcSubmit RequestPacket(kind: req_bye)

{.used.}
