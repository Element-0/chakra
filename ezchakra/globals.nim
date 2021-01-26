import hookmc

template genGlobal(T, symbol: untyped) =
  type T* = distinct pointer
  var storage {.gensym.}: T
  block:
    proc hooked(target: T) {.inject, hookmc: symbol.} =
      storage = target
      hooked_origin(target)
  proc global*(unused: typedesc[T]): T {.inject.} = storage

genGlobal(ServerInstance): "?set@?$ServiceLocator@VServerInstance@@@@SA?AV?$ServiceRegistrationToken@VServerInstance@@@@V?$not_null@PEAVServerInstance@@@gsl@@@Z"
