import std/[tables, macros]
import ezcommon/log

when defined(chakra):
  import ./ipc
  proc rawLog*(data: LogData) {.exportc, dynlib.} =
    if ipcValid():
      ipcSubmit data
  const modname = "CHAKRA"
  {.used.}
else:
  proc rawLog*(data: LogData) {.importc, dynlib: "chakra.dll".}

proc doLog*(
    pos: tuple[filename: string, line: int, column: int];
    lvl: LogLevel;
    tags: seq[string];
    content: string;
    details: Table[string, LogDetail]) =
  rawLog LogData(
    area: modname,
    tags: tags,
    level: lvl,
    source: pos.filename,
    line: pos.line,
    content: content,
    details: details,
  )

macro buildDetails(args: varargs[untyped]): (seq[string], Table[string, LogDetail]) =
  let tags = newNimNode nnkBracket
  let details = newNimNode nnkTableConstr
  for arg in args:
    case arg.kind:
    of nnkExprColonExpr:
      arg.expectLen 2
      arg[0].expectKind nnkIdent
      let tmp = arg.copy()
      tmp[0] = newLit $arg[0]
      tmp[1] = newCall(bindSym"toLogDetail", arg[1])
      details.add tmp
    of nnkStrLit:
      tags.add arg
    else:
      error "invalid tag: " & $arg.kind
  let tab = if details.len == 0:
    quote do:
      initTable[string, LogDetail]()
  else:
    newCall(bindSym"toTable", details)
  nnkPar.newTree(
    nnkPrefix.newTree(ident("@"), tags),
    tab
  )

type Log* = object

template notice*(_: type Log; content: string; args: varargs[untyped]) =
  let (tags, details) = buildDetails args
  instantiationInfo().doLog(LogLevel.lvl_notice, tags, content, details)
template info*(_: type Log; content: string; args: varargs[untyped]) =
  let (tags, details) = buildDetails args
  instantiationInfo().doLog(LogLevel.lvl_info, tags, content, details)
template debug*(_: type Log; content: string; args: varargs[untyped]) =
  let (tags, details) = buildDetails args
  instantiationInfo().doLog(LogLevel.lvl_debug, tags, content, details)
template warn*(_: type Log; content: string; args: varargs[untyped]) =
  let (tags, details) = buildDetails args
  instantiationInfo().doLog(LogLevel.lvl_warn, tags, content, details)
template error*(_: type Log; content: string; args: varargs[untyped]) =
  let (tags, details) = buildDetails args
  instantiationInfo().doLog(LogLevel.lvl_error, tags, content, details)
