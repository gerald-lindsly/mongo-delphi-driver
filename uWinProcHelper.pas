unit uWinProcHelper;

{$i LibVer.inc}

interface

uses
  Windows;

function KillProcess(const aProcess: string): Boolean;
function GetProcessHandle(const AProcess : string; dwDesiredAccess : DWORD): THandle;

implementation

uses
  SysUtils, TLHelp32 {$IFDef LEVEL7} , Variants {$EndIf}; // This three units are safe because they not reference Classes

function KillProcess(const aProcess: string): Boolean;
var
  ProcessHandle : THandle;
begin
  ProcessHandle := GetProcessHandle (aProcess, PROCESS_TERMINATE);
  try
    Result := TerminateProcess (ProcessHandle, 0);
  finally
    if ProcessHandle <> 0
      then CloseHandle (ProcessHandle);
  end;
end;

function GetProcessHandle(const AProcess : string; dwDesiredAccess : DWORD): THandle;
var
  SnapshotHandle : THandle;
  ProcessEntry32 : TProcessEntry32;
  ContinueLoop : Boolean;
  ProcName : string;
  ProcId : THandle;
begin
  Result := 0;
  SnapshotHandle := CreateToolhelp32Snapshot (TH32CS_SNAPPROCESS, 0);
  try
    try
      ProcessEntry32.dwSize := SizeOf (ProcessEntry32);
      ContinueLoop := Process32First (SnapshotHandle, ProcessEntry32);
      while ContinueLoop do
        begin
          ProcName := ExtractFileName(ProcessEntry32.szExeFile);
          if CompareText(ProcName, AProcess) = 0
            then
            begin
              ProcId := ProcessEntry32.th32ProcessID;
              Result := OpenProcess (dwDesiredAccess, False, ProcID);
              exit;
            end;
          ContinueLoop := Process32Next (SnapshotHandle, ProcessEntry32);
        end;
    except
      if Result <> 0
        then CloseHandle (Result);
      raise;
    end;
  finally
    CloseHandle (SnapshotHandle);
  end;
end;

end.
