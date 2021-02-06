import std/macros, fusion/matching

type
  EventEmitter*[T] = object
    s: seq[T]

macro emit*[T](emitter: EventEmitter[T]; input: varargs[untyped]) =
  let itemsym = genSym(nskForVar, "item")
  let call = newCall(itemsym)
  if Arglist(len: > 0, [all @args], last: @collect is StmtList()) ?= input:
    for arg in args[0..^2]:
      call.add arg
    let it = ident "it"
    let flet = quote do:
      let `it` = `call`
      `collect`
    echo repr flet
    return nnkForStmt.newTree(
      itemsym,
      nnkDotExpr.newTree(
        emitter,
        ident("s")
      ),
      flet
    )
  else:
    for arg in input:
      call.add arg
    return nnkForStmt.newTree(
      itemsym,
      nnkDotExpr.newTree(
        emitter,
        ident("s")
      ),
      call
    )

template `()`*[T](emitter: EventEmitter[T]; listener: T) =
  emitter.s.add listener
