import std/[os, tables, strutils], winim/lean
import ../hookos, ../log

{.used.}

let appdata = getAppDir()
let workdir = absolutePath getCurrentDir()

proc relative(x: string): string = relativePath(x, workdir)
proc basepath(x: string): string = x.split('\\', 2)[0]

proc MySetCurrentDirectoryA(s: cstring): bool
    {.stdcall, hookos(r"kernelbase.dll", r"SetCurrentDirectoryA").} = discard

type MapStrategy = enum
  ms_instance
  ms_asset
  ms_temp
  ms_null

let filemap = {
  "behavior_packs": ms_asset,
  "resource_packs": ms_asset,
  "definitions": ms_asset,
  "data": ms_asset,
  "world_templates": ms_instance,
  "development_behavior_packs": ms_instance,
  "development_resource_packs": ms_instance,
  "development_skin_packs": ms_instance,
  "internalStorage": ms_instance,
  "worlds": ms_instance,
  "server.properties": ms_instance,
  "permissions.json": ms_instance,
  "whitelist.json": ms_instance,
  "invalid_known_packs.json": ms_temp,
  "valid_known_packs.json": ms_temp,
  "ops.json": ms_null,
}.toTable()

converter `$`(path: UNICODE_STRING): string =
  let l = int32(path.Length) div 2
  let mlen = WideCharToMultiByte(CP_UTF8, 0, path.Buffer, l, nil, 0, nil, nil)
  result = newString mLen
  discard WideCharToMultiByte(CP_UTF8, 0, path.Buffer, l, result.cstring, mLen, nil, nil)

proc realPath(attr: OBJECT_ATTRIBUTES): string =
  if attr.RootDirectory != 0:
    var buffer: array[4096, WCHAR]
    let len = GetFinalPathNameByHandle(
      attr.RootDirectory,
      cast[LPWSTR](addr buffer),
      4095,
      FILE_NAME_NORMALIZED)
    assert len > 8
    result =
      $$cast[LPWSTR](cast[int](addr buffer) + 8) / $attr.ObjectName[]
  else:
    result = $attr.ObjectName[]
    if result.startsWith(r"\??\") and result[5] == ':':
      result = relative result.substr(4)
    elif result.startsWith(r"\"):
      return
  result = relative result

type FixEnv = object
  raw: wstring
  sys: UNICODE_STRING

proc fixupPath[TAG: static string](env: var FixEnv; objectAttributes: POBJECT_ATTRIBUTES) =
  let brel = realPath(objectAttributes[])
  if brel[0] in {'.', '\\'} or isAbsolute(brel):
    return
  case filemap.getOrDefault(basepath brel):
  of ms_asset:
    env.raw = +$(r"\??\" & appdata / brel)
    RtlInitUnicodeString(addr env.sys, env.raw)
    objectAttributes[].RootDirectory = 0
    objectAttributes[].ObjectName = addr env.sys
  else:
    discard

template wrapFsAccess(tag: string; action: untyped): untyped =
  var tmp {.gensym.}: FixEnv
  fixupPath[tag](tmp, objectAttributes)
  when defined(debugFS):
    result = action
    if result != 0:
      Log.notice("Result", "CREATE", path: $objectAttributes[].ObjectName[], result: result)
  else:
    action

proc NtCreateFile(
  phandle: PHANDLE;
  access: ACCESS_MASK;
  objectAttributes: POBJECT_ATTRIBUTES;
  ioStatusBlock: PIO_STATUS_BLOCK;
  allocationSize: int64;
  fileAttributes, shareAccess, createDisposition, createOptions: int32;
  eaBuffer: ptr UncheckedArray[byte];
  eaLength: int32;
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtCreateFile").} =
  wrapFsAccess "CREATE": NtCreateFile_origin(
    phandle,
    access,
    objectAttributes,
    ioStatusBlock,
    allocationSize,
    fileAttributes,
    shareAccess,
    createDisposition,
    createOptions,
    eaBuffer,
    eaLength
  )

proc NtOpenFile(
  phandle: PHANDLE;
  access: ACCESS_MASK;
  objectAttributes: POBJECT_ATTRIBUTES;
  ioStatusBlock: PIO_STATUS_BLOCK;
  shareAccess, openOptions: int32;
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtOpenFile").} =
  wrapFsAccess "OPEN": NtOpenFile_origin(
    phandle,
    access,
    objectAttributes,
    ioStatusBlock,
    shareAccess,
    openOptions,
  )

proc NtDeleteFile(
  objectAttributes: POBJECT_ATTRIBUTES
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtDeleteFile").} =
  wrapFsAccess "DELETE": NtDeleteFile_origin(objectAttributes)

proc NtQueryAttributesFile(
  objectAttributes: POBJECT_ATTRIBUTES;
  attributes: pointer;
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtQueryAttributesFile").} =
  wrapFsAccess "ATTR": NtQueryAttributesFile_origin(objectAttributes, attributes)

proc NtQueryFullAttributesFile(
  objectAttributes: POBJECT_ATTRIBUTES;
  attributes: pointer;
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtQueryFullAttributesFile").} =
  wrapFsAccess "FULLATTR": NtQueryFullAttributesFile_origin(objectAttributes, attributes)

proc LdrLoadDll(
  path: LPWSTR;
  flags: PULONG;
  filename: PUNICODE_STRING;
  handle: PHANDLE;
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"LdrLoadDll").} =
  let name = $filename[].Buffer
  Log.notice("Loading dll", "DLL", name: name)
  LdrLoadDll_origin(path, flags, filename, handle)
