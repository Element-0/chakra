import cppinterop/[cppstr, cppvec]
import ../hookmc, ../importmc, ../log

type DBStorage = object
type SnapshotFilenameAndLength = object
  filename: CppString
  length: uint64
type LevelStorageResult = object
  unknown: pointer
  data: CppString

proc getState(self: ptr DBStorage): LevelStorageResult {.
  thisabi,
  importmc: "?getState@DBStorage@@UEBA?AULevelStorageResult@Core@@XZ".}

proc savedb(self: ptr DBStorage; data: pointer) {.
  hookmc: "?saveLevelData@DBStorage@@UEAAXAEBVLevelData@@@Z".} =
  Log.debug("Saving", "SAVE")
  savedb_origin(self, data)
  let data = getState(self).data
  Log.debug("Saved", "SAVE", result: $data)

proc createSnapshot(self: ptr DBStorage; str: var CppString): CppVector[SnapshotFilenameAndLength] {.
  thisabi: buffer,
  hookmc: "?createSnapshot@DBStorage@@UEAA?AV?$vector@USnapshotFilenameAndLength@@V?$allocator@USnapshotFilenameAndLength@@@std@@@std@@AEBV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@3@@Z"
.} =
  Log.debug("creating snapshot", "SNAPSHOT", name: $str)
  result = createSnapshot_origin(self, buffer, str)
  Log.debug("Created snapshot", "SNAPSHOT")
  for item in buffer[]:
    Log.debug("item:", filename: $item.filename, length: int item.length)

{.used.}
