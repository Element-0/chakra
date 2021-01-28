import std/strutils, cppinterop/stdarg, ezcommon/log
import ./hookmc, ./ipc

func mapLogLevel(val: int32): LogLevel =
  case val:
  of 1: lvl_notice
  of 2: lvl_info
  of 4: lvl_warn
  of 8: lvl_error
  else: lvl_debug

func mapLogArea(area: int32): string =
  const fixed = @[
    "ALL",
    "PLATFORM",
    "ENTITY",
    "DATABASE",
    "GUI",
    "SYSTEM",
    "NETWORK",
    "RENDER",
    "MEMORY",
    "ANIMATION",
    "INPUT",
    "LEVEL",
    "SERVER",
    "DLC",
    "PHYSICS",
    "FILE",
    "STORAGE",
    "REALMS",
    "REALMSAPI",
    "XBOXLIVE",
    "USERMANAGER",
    "XSAPI",
    "PERF",
    "TELEMETRY",
    "BLOCKS",
    "RAKNET",
    "GAMEFACE",
    "SOUND",
    "INTERACTIVE",
    "SCRIPTING",
    "PLAYFAB",
    "AUTOMATION",
    "PERSONA",
    "MODDING"
  ];
  fixed[area]

proc log_va(
  self: pointer;
  area, level: int32;
  src: cstring;
  line, column: int32;
  fmt: cstring;
  args: va_list
) {.hookmc: "?_log_va@LogDetails@BedrockLog@@AEAAXW4LogAreaID@@IPEBDHH1PEAD@Z".} =
  if not ipcValid():
    log_va_origin(self, area, level, src, line, column, fmt, args)
  else:
    ipcSubmit LogData(
      area: mapLogArea area,
      level: mapLogLevel level,
      src_name: $src,
      src_line: line,
      src_column: column,
      content: cfmt(fmt, args).strip()
    )

{.used.}
