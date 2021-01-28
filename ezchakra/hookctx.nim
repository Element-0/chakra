import ezfunchook

when defined(chakra):
  var ctx = newFuncHook()
  var prectx* = newFuncHook()
  var state = false

  proc applyPreHooks*() =
    prectx.install()
    state = true

  proc applyHooks*() =
    ctx.install()

  proc getHookContext*(): ref FuncHook {.exportc, dynlib.} =
    if state: ctx else: prectx
else:
  proc getHookContext*(): ref FuncHook {.importc, dynlib: "chakra.dll".}
