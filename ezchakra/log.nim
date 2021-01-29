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
    content: string;
    details: openarray[(string, LogDetail)]) =
  rawLog LogData(
    area: modname,
    level: lvl,
    source: pos.filename,
    line: pos.line,
    content: content,
    details: details.toTable(),
  )

macro buildDetails(args: varargs[untyped]): openarray[(string, LogDetail)] =
  result = newNimNode nnkTableConstr
  for arg in args:
    arg.expectKind nnkExprColonExpr
    arg.expectLen 2
    arg[0].expectKind nnkIdent
    let tmp = arg.copy()
    tmp[0] = newLit $arg[0]
    tmp[1] = newCall(bindSym"toLogDetail", arg[1])
    result.add tmp

type Log* = object

template notice*(_: type Log; content: string; details: varargs[untyped]) =
  instantiationInfo().doLog(LogLevel.lvl_notice, content, buildDetails details)
template info*(_: type Log; content: string; details: varargs[untyped]) =
  instantiationInfo().doLog(LogLevel.lvl_info, content, buildDetails details)
template debug*(_: type Log; content: string; details: varargs[untyped]) =
  instantiationInfo().doLog(LogLevel.lvl_debug, content, buildDetails details)
template warn*(_: type Log; content: string; details: varargs[untyped]) =
  instantiationInfo().doLog(LogLevel.lvl_warn, content, buildDetails details)
template error*(_: type Log; content: string; details: varargs[untyped]) =
  instantiationInfo().doLog(LogLevel.lvl_error, content, buildDetails details)