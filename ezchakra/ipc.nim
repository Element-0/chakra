{.experimental: "caseStmtMacros".}
import fusion/matching
import ezcommon/ipc
export ipc

type
  IpcRequestKind* = enum
    irk_drop
    irk_sync
    irk_async
  IpcRequest* = object
    packet*: RequestPacket
    case kind*: IpcRequestKind
    of irk_drop:
      discard
    of irk_sync:
      chanref: ptr Channel[ResponsePacket]
    of irk_async:
      handler*: proc (pkt: ResponsePacket) {.gcsafe, locks: 0.}

when defined(chakra):
  import std/[os, oids], ezpipe, binpak

  var chan: Channel[IpcRequest]
  var thrd: Thread[ref IpcPipe]
  var valid = false

  proc ipcThread(pipe: ref IpcPipe) {.thread.} =
    while true:
      let req = chan.recv()
      pipe.send: ~>$ req.packet
      if req.packet.kind.noReply:
        assert req.kind == irk_drop
        continue
      let data = ResponsePacket <<- pipe.recv()
      case req:
      of drop():
        if data.kind == res_failed:
          quit data.errMsg
      of sync(chanref: @chan): chan[].send data
      of async(handler: @handler): handler data

  let path = getEnv("EZPIPE", "debug")
  if path != "debug":
    valid = true
    chan.open()
    thrd.createThread(ipcThread, newIpcPipeClient(parseOid path))

  proc ipcRequest*(req: IpcRequest) {.exportc, dynlib.} =
    if not valid:
      if req.kind == irk_drop:
        return
      else:
        raise newException(OSError, "invalid endpoint")
    chan.send req

  proc ipcValid*(): bool {.exportc, dynlib.} = valid
else:
  proc ipcRequest*(req: IpcRequest) {.importc, dynlib: "chakra.dll".}
  proc ipcValid*(): bool {.importc, dynlib: "chakra.dll".}

proc ipcSubmit*(pkt: RequestPacket) {.inline.} =
  assert not pkt.kind.noReply
  ipcRequest IpcRequest(packet: pkt, kind: irk_drop)
proc ipcAsync*(pkt: RequestPacket, fn: proc (pkt: ResponsePacket) {.gcsafe, locks: 0.}) {.inline.} =
  assert not pkt.kind.noReply
  ipcRequest IpcRequest(packet: pkt, kind: irk_async, handler: fn)
proc ipcSync*(pkt: RequestPacket): ResponsePacket =
  var chan: Channel[ResponsePacket]
  defer: chan.close()
  chan.open(1)
  ipcRequest IpcRequest(packet: pkt, kind: irk_sync, chanref: addr chan)
  chan.recv()
