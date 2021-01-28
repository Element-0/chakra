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
      let data = ResponsePacket <<- pipe.recv()
      case req.kind:
      of irk_drop:
        if data.kind == res_failed:
          quit data.errMsg
      of irk_sync:
        req.chanref[].send data
      of irk_async:
        req.handler data

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

proc ipcSubmit*(pkt: RequestPacket) {.inline.} = ipcRequest IpcRequest(packet: pkt, kind: irk_drop)
proc ipcAsync*(pkt: RequestPacket, fn: proc (pkt: ResponsePacket) {.gcsafe, locks: 0.}) {.inline.} =
  ipcRequest IpcRequest(packet: pkt, kind: irk_async, handler: fn)
template ipcSync*(pkt: RequestPacket, name, blk: untyped): untyped =
  var chan: Channel[ResponsePacket]
  try:
    chan.open(1)
    ipcRequest IpcRequest(packet: pkt, kind: irk_sync, chanref: addr chan)
    let name = chan.recv()
    blk
  finally:
    chan.close()
