import std/macros

iterator iterateParams(params: NimNode): NimNode =
  for item in params[1..^1]:
    for name in item[0..^3]:
      yield nnkIdentDefs.newTree(name, item[^2], newEmptyNode())

proc transformParams*(buf_id, params: NimNode): NimNode =
  result = nnkFormalParams.newNimNode()
  let retType = params[0]
  result.add nnkPtrTy.newTree(retType)
  var first = true
  for p in iterateParams(params):
    result.add p
    if first:
      first = false
      result.add nnkIdentDefs.newTree(
        buf_id,
        nnkPtrTy.newTree(retType),
        newEmptyNode())
