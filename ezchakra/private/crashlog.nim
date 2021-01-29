import winim/lean
import ../hookmc, ../ipc

## Don't send report
proc sendReport(): int {.hookmc: "?SendCrashReport@CrashReportSender@google_breakpad@@QEAA?AW4ReportResult@2@AEBV?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@AEBV?$map@V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@V12@U?$less@V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@@2@V?$allocator@U?$pair@$$CBV?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@V12@@std@@@2@@5@1PEAV45@@Z".} =
  ipcSubmit RequestPacket(kind: req_bye)
  TerminateProcess(-1, 1)
  quit 1

{.used.}
