type MayClosureTask = object
  case isClosure: bool
  of true:
    closure: proc () {.closure, locks: "unknown".}
  of false:
    normal: proc () {.cdecl, noconv, locks: "unknown".}

when defined(chakra):
  import hookmc, winim/lean

  var closure_chan: Channel[MayClosureTask]
  closure_chan.open(16)
  let mainthread = GetCurrentThreadId()

  proc invoke(task: MayClosureTask) {.inline.} =
    if task.isClosure: task.closure()
    else: task.normal()

  proc isMainThread: bool {.inline.} = mainthread == GetCurrentThreadId()

  proc update() {.hookmc: "?update@BedrockLog@@YAXXZ".} =
    while true:
      let tmp = closure_chan.tryRecv()
      if not tmp.dataAvailable:
        break
      tmp.msg.invoke()
    update_origin()

  proc syncCall(task: MayClosureTask) {.exportc, dynlib.} =
    if isMainThread():
      task.invoke()
    else:
      closure_chan.send task
else:
  proc syncCall(task: MayClosureTask) {.importc, dynlib: "chakra.dll".}

proc syncCall*(input: proc () {.closure, locks: "unknown".}) {.inline.} =
  syncCall MayClosureTask(isClosure: true, closure: input)

proc syncCall*(input: proc () {.cdecl, noconv, locks: "unknown".}) {.inline.} =
  syncCall MayClosureTask(isClosure: false, normal: input)
