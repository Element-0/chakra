{.experimental: "caseStmtMacros".}
{.deadCodeElim: on.}
import fusion/matching

type
  DedicatedServer* = distinct pointer
  DedicatedServerHook* = proc(server: DedicatedServer) {.closure.}

when defined(chakra):
  import std/options, hookmc, importmc, cppinterop/cppstr

  var hooks: seq[DedicatedServerHook]
  var started: Option[DedicatedServer]

  proc startServer(server: DedicatedServer, str: ptr CppString): int {.hookmc: "?start@DedicatedServer@@QEAA?AW4StartResult@1@AEBV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@Z".} =
    started = some server
    for item in hooks:
      item(server)
    hooks.setLen 0
    result = server.startServer_origin(str)

  proc addServerHook*(hook: DedicatedServerHook) {.exportc, dynlib.} =
    if Some(@server) ?= started:
      hook server
    else:
      hooks.add hook
else:
  proc addServerHook*(hook: DedicatedServerHook) {.importc, dynlib: "chakra.dll".}

proc addServerHook*(raw: proc(server: DedicatedServer) {.cdecl.}) =
  addServerHook do(server: DedicatedServer): raw(server)
