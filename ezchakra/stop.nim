import importmc, serverhook, sync

proc stopServer(server: DedicatedServer) {.importmc: "?stop@DedicatedServer@@UEAA_NXZ".}

proc enqueueStopServer*() =
  syncCall do():
    addServerHook do(server: DedicatedServer):
      stopServer(cast[DedicatedServer](cast[ByteAddress](server) + 8))

when defined(chakra):
  import winim/[lean, inc/wincon]
  proc handler(xtype: DWORD): WINBOOL {.stdcall.} =
    once: enqueueStopServer()
    return TRUE
  SetConsoleCtrlHandler handler, TRUE
