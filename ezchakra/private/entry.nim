{.experimental: "caseStmtMacros".}
import std/[streams, json, sugar], fusion/matching
import ezcommon/version_code
import ../hookmc, ../ipc, ../hookctx, ../log

type ModDesc = object
  name: string
  min, max: VersionCode

proc parseModDesc(node: JsonNode): ModDesc =
  if node.kind != JObject:
    raise newException(ValueError, "expected Object got " & $node.kind)
  result.name = node["name"].to string
  result.min = parseVersionCode node["min"].to string
  result.max = parseVersionCode node["max"].to string

proc loadMods() =
  const cfgfile = "mods.json"
  let str = openFileStream(cfgfile, fmRead)
  let doc = str.parseJson(cfgfile)
  if doc.kind != JArray:
    raise newException(ValueError, "expected Array")
  let list = collect(newSeq):
    for item in doc:
      parseModDesc item
  for item in list:
    Log.info("Resolving mod", "LOADMOD", spec: $item)
    case ipcSync RequestPacket(
      kind: req_load,
      modName: item.name,
      minVersion: item.min,
      maxVersion: item.max)
    of load(modPath: @path):
      Log.info("Loading mod", "LOADMOD", path: path)
    of failed(errMsg: @msg):
      raise newException(OSError, msg)
    else: doAssert(false, "impossible")

proc main(argc: int; argv, envp: cstringArray): int {.hookmc: "main".} =
  if ipcValid():
    case ipcSync RequestPacket(kind: req_ping)
    of failed(errMsg: @msg): raise newException(OSError, msg)
    of pong(): Log.debug("Checkpoint reached", "STARTUP")
    else: doAssert(false, "impossible")
    try:
      loadMods()
    except:
      let exp = getCurrentException()
      Log.error("Failed to load mods",
        "LOADMOD",
        message: exp.msg,
        name: $exp.name)
      ipcSubmit RequestPacket(kind: req_bye)
      quit 1
    applyHooks()
  result = main_origin(argc, argv, envp)
  ipcSubmit RequestPacket(kind: req_bye)

{.used.}
