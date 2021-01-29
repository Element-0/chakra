import std/[macros, os], ezpdbparser
import ./private/abifix

when defined(chakra):
  import winim/inc/winbase
  import ezsqlite3

  proc selectSymbol(hash: int64): tuple[address: int] {.importdb: "SELECT address FROM symbols_hash WHERE symbol=$hash".}

  var symdb = initDatabase getAppDir() / "bedrock_server.db"
  var baseaddr = cast[ByteAddress](GetModuleHandle(nil))

  proc findSymbolByHash*(hash: int64): ByteAddress {.exportc, dynlib.} =
    cast[ByteAddress](symdb.selectSymbol(hash).address) + baseaddr
else:
  proc findSymbolByHash*(hash: int64): ByteAddress {.importc, dynlib: "chakra.dll".}

proc findSymbol*(symbol: static string, T: typedesc): T =
  const hash = symhash(symbol)
  var cached {.global.}: T
  if cached == nil:
    try:
      result = cast[T](findSymbolByHash(hash))
      cached = result
    except:
      quit "Symbol '" & symbol & "' not found!"
  else:
    result = cached

proc directImport(sym: string; body: NimNode): NimNode =
  let xtype = nnkProcTy.newTree(
    body[3].copy(),
    nnkPragma.newTree(ident "cdecl")
  )
  let fname = body[0].copy()
  result = quote do:
    let `fname` = findSymbol(`sym`, `xtype`)

proc abifixImport(sym: string; body: NimNode): NimNode =
  let buffer_id = nskParam.genSym "buffer"
  let raw_id = nskLet.genSym sym
  let params = transformParams(buffer_id, body[3])
  let xtype = nnkProcTy.newTree(
    params,
    nnkPragma.newTree(ident "cdecl")
  )
  let invoke = nnkCall.newNimNode()
  for idx, param in params:
    case idx:
    of 0: invoke.add(raw_id)
    of 2: invoke.add(newCall(ident "addr", ident "result"))
    else: invoke.add(param[0])
  let wrapper = nnkDiscardStmt.newTree(invoke)
  let generated = nnkProcDef.newTree(
    ident sym,
    newEmptyNode(),
    newEmptyNode(),
    body[3].copy(),
    nnkPragma.newTree(ident "inline"),
    newEmptyNode(),
    wrapper)
  result = quote do:
    let `raw_id` = findSymbol(`sym`, `xtype`)
    `generated`

macro importmc*(sym: static string, body: untyped) =
  if body[4].kind == nnkPragma and body[4].len == 1 and $body[4][0] == "thisabi":
    abifixImport(sym, body)
  else:
    directImport(sym, body)
