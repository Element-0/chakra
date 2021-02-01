import std/dynlib, ./log

type PWineGetVersion = proc (): cstring {.cdecl.}

proc detect_wine(): bool =
  let lib = loadLib("ntdll.dll")
  defer: lib.unloadLib()
  let fn = cast[PWineGetVersion](lib.symAddr("wine_get_version"));
  if fn != nil:
    let version = $fn()
    Log.debug("Wine detected", version: version)
    true
  else:
    false

let detected* = detect_wine()

{.used.}
