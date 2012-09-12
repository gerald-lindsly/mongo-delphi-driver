{ This unit MUST NOT include any other units that reference Classes unit
  in its uses clause because this unit is used in the array memory allocator
  wich MUST be reference before Classes unit in the global scope of the
  project }

unit CnvGenUtils;

{$i LibVer.inc}

interface

uses
  Windows;

type
  DWORD = Cardinal;
  THandle = Longword;
  BOOL = LongBool;

const
  SZI = SizeOf (Integer);
  SZW = SizeOf (Word);
  SZT = SizeOf (TObject);
  SZP = SizeOf (Pointer);
  SZH = SizeOf (THandle);
  SZD = SizeOf (Double);
  SZL = SizeOf (LongWord);
  SZC = SizeOf (Currency);
  SZLI = SizeOf (Int64);

  iTlsBaseOffset = $0E10;

  VER_PLATFORM_WIN32s = 0;
  VER_PLATFORM_WIN32_WINDOWS = 1;
  VER_PLATFORM_WIN32_NT = 2;

type
  PInt = ^Integer;
  PByte = ^Byte;
  { MultiByte Character Set (MBCS) byte type }
  TMbcsByteType = (mbSingleByte, mbLeadByte, mbTrailByte);
  TStrVarRecArray = class;
  IStrVarRecArray = interface
    ['{0EEFBC72-98A5-4D3E-962B-82C7E191048B}']
    function Obj : TStrVarRecArray;
  end;

  TStrVarRecArray = class (TInterfacedObject, IStrVarRecArray)
  private
    Strings : array of string;
  protected
    function Obj: TStrVarRecArray;
  public
    Arr : array of TVarRec;
    constructor Create(const Values : array of Variant; FromIndex : integer = 0; 
        ToIndex : integer = -1);
    class function CreateIntf(const Values : array of Variant; FromIndex : integer
        = 0; ToIndex : integer = -1): IStrVarRecArray;
    procedure SetStr(Index : integer; const AStr : string);
    destructor Destroy; override;
  end;

function SetVmtEntry(AClass : TClass; VmtOffset : Integer; NewAddr : Pointer): Pointer;
procedure PatchMemory(p : Pointer; DataSize : Integer; Data : Pointer; OldData : pointer); overload;
procedure PatchMemory(p : Pointer; DataSize : Integer; Data : Pointer); overload;
function SetTlsOffset(P: PInt; AOffset: Integer; DirectReplacement : boolean =
    false): PInt;
{$IFNDEF WIN64}
function GetThreadVar(TlsSlot : integer): Pointer;
procedure SetThreadVar(TlsSlot : integer; Value : pointer);
{$ENDIF}
function KillProcess(const aProcess: string): Boolean;
function ProcessExists(const AProcess : string): Boolean;
function GetProcessHandle(const AProcess : string; dwDesiredAccess : DWORD):
    THandle;
function UpperCase(const S: string): string;
function ExtractFileName(const FileName: string): string;
function LastDelimiter(const Delimiters, S: AnsiString): Integer;
{$IFNDEF WIN64}
function StrScan(const Str: PAnsiChar; Chr: AnsiChar): PAnsiChar;
{$ENDIF}
function ByteType(const S: string; Index: Integer): TMbcsByteType;

function CnvGetComputerName: string;
function ParamCount: Integer;
function ParamStr(Index: Integer): string;

var
  Win32Platform : DWORD;

implementation

uses
  {$IFDEF WIN64} SysUtils, {$ENDIF} TLHelp32 {$IFDef LEVEL7} , Variants {$EndIf}; // This three units are safe because they not reference Classes

const
  //kernel = 'kernel32.dll';
  //PAGE_READWRITE = 4;
  FakeData : Pointer = nil;

(*type
  _OSVERSIONINFOW = record
    dwOSVersionInfoSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformId: DWORD;
    szCSDVersion: array[0..127] of AnsiChar; { Maintenance string for PSS usage }
  end;
  TOSVersionInfo = _OSVERSIONINFOW;

function VirtualProtect(lpAddress: Pointer; dwSize, flNewProtect: DWORD; var OldProtect: DWORD): BOOL; stdcall; external kernel name 'VirtualProtect';
function GetVersionEx(var lpVersionInformation: TOSVersionInfo): BOOL; stdcall; external kernel Name 'GetVersionExA';
function TlsGetValue(dwTlsIndex: DWORD): Pointer; stdcall; external kernel name 'TlsGetValue';
function TlsSetValue(dwTlsIndex: DWORD; lpTlsValue: Pointer): BOOL; stdcall; external kernel name 'TlsSetValue';
 *)
function SetVmtEntry(AClass : TClass; VmtOffset : Integer; NewAddr : Pointer):
    Pointer;
var
  VmtPtr : Pointer;
begin
  Result := nil;
  VmtPtr := Pointer (Integer (AClass) + VmtOffset);
  PatchMemory (VmtPtr, SizeOf (Pointer), @NewAddr, Result);
end;

procedure PatchMemory(p : Pointer; DataSize : Integer; Data : Pointer; OldData : pointer); {$IfDef LEVEL7} overload; {$ENDIF}
var
  OldProtect : DWORD;
begin
  VirtualProtect (p, DataSize, PAGE_READWRITE, OldProtect);
  if OldData <> @FakeData
    then Move (p^, OldData^, DataSize);
  move (Data^, p^, DataSize);
  VirtualProtect (p, DataSize, OldProtect, OldProtect);
end;

procedure PatchMemory (p : Pointer; DataSize : Integer; Data : Pointer); {$IfDef LEVEL7} overload; {$EndIf}
begin
  PatchMemory (p, DataSize, Data, @FakeData);
end;

function SetTlsOffset(P: PInt; AOffset: Integer; DirectReplacement : boolean =
    false): PInt;
var
  NewTlsOffset : Integer;
begin
  while P^ <> iTlsBaseOffset do
    Inc (PByte (P));
  if DirectReplacement
    then NewTlsOffset := AOffset
    else NewTlsOffset := iTlsBaseOffset + AOffset * SZI;
  PatchMemory (P, SizeOf (Integer), @NewTlsOffset);
  Inc (P);
  Result := P;
end;

procedure InitPlatformId;
var
  OSVersionInfo: TOSVersionInfo;
begin
  OSVersionInfo.dwOSVersionInfoSize := SizeOf(OSVersionInfo);
  if GetVersionEx(OSVersionInfo) then
    with OSVersionInfo do
      Win32Platform := dwPlatformId;
end;

{$IFNDEF WIN64}
function GetThreadVar(TlsSlot : integer): Pointer;
asm
    cmp         Win32Platform, VER_PLATFORM_WIN32_NT // Check if is WinNT or higher
    jge         @@GetDirectAccess
    push        TlsSlot
    call        TlsGetValue
    jmp         @@Exit
  @@GetDirectAccess:
    mov         Eax,fs:[TlsSlot]
  @@Exit:
end;

procedure SetThreadVar(TlsSlot : integer; Value : pointer);
asm
    cmp         Win32Platform, VER_PLATFORM_WIN32_NT // Check if is WinNT or higher
    jge         @@SetDirectAccess
    push        Value
    push        TlsSlot
    call        TlsSetValue
    jmp         @@Exit
  @@SetDirectAccess:
    mov         fs:[TlsSlot], Value
  @@Exit:
end;
{$ENDIF}

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

function UpperCase(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then Dec(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

function ExtractFileName(const FileName: string): string;
var
  I: Integer;
begin
  I := LastDelimiter('\:', AnsiString(FileName));
  Result := Copy(FileName, I + 1, MaxInt);
end;

function LastDelimiter(const Delimiters, S: AnsiString): Integer;
var
  P: PAnsiChar;
begin
  Result := Length(S);
  P := PAnsiChar(Delimiters);
  while Result > 0 do
  begin
    if (S[Result] <> #0) and (StrScan(P, S[Result]) <> nil) then
      if (ByteType(S, Result) = mbTrailByte) then
        Dec(Result)
      else
        Exit;
    Dec(Result);
  end;
end;

{$IFNDEF WIN64}
function StrScan(const Str: PAnsiChar; Chr: AnsiChar): PAnsiChar; assembler;
asm
        PUSH    EDI
        PUSH    EAX
        MOV     EDI,Str
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     ECX
        POP     EDI
        MOV     AL,Chr
        REPNE   SCASB
        MOV     EAX,0
        JNE     @@1
        MOV     EAX,EDI
        DEC     EAX
@@1:    POP     EDI
end;
{$ENDIF}

function ByteType(const S: string; Index: Integer): TMbcsByteType;
begin
  Result := mbSingleByte;
  {if SysLocale.FarEast then
    Result := ByteTypeTest(PChar(S), Index-1);}
end;

function ProcessExists(const AProcess : string): Boolean;
var
  h : THandle;
begin
  h := GetProcessHandle (AProcess, STANDARD_RIGHTS_REQUIRED);
  try
    Result := h <> 0;
  finally
    if h <> 0
      then CloseHandle (h);
  end;
end;

function GetProcessHandle(const AProcess : string; dwDesiredAccess : DWORD):
    THandle;
var
  SnapshotHandle : THandle;
  ProcessEntry32 : TProcessEntry32;
  ContinueLoop : BOOL;
  aProcessUpper : string;
  ProcName : string;
  ProcId : THandle;
begin
  Result := 0;
  aProcessUpper := UpperCase (aProcess);
  SnapshotHandle := CreateToolhelp32Snapshot (TH32CS_SNAPPROCESS, 0);
  try
    try
      ProcessEntry32.dwSize :=SizeOf (ProcessEntry32);
      ContinueLoop := Process32First (SnapshotHandle, ProcessEntry32);
      while Integer (ContinueLoop) <> 0 do
        begin
          ProcName := ExtractFileName (ProcessEntry32.szExeFile);
          if UpperCase (ProcName) = aProcessUpper
            then
            begin
              ProcId := ProcessEntry32.th32ProcessID;
              Result := OpenProcess (dwDesiredAccess, BOOL(0), ProcID);
              exit;
            end;
          ContinueLoop := Process32Next (SnapshotHandle, ProcessEntry32);
        end;
    finally
      CloseHandle (SnapshotHandle);
    end;
  except
    if Result <> 0
      then CloseHandle (Result);
    raise;
  end;
end;

function CnvGetComputerName: string;
var
  Comp: array[0..255] of Char;
  I: DWord;
begin
  I := MAX_COMPUTERNAME_LENGTH + 1;
  GetComputerName(Comp, I);
  Result := string(Comp);
end;

function ParamStr(Index: Integer): string;
begin
  Result := system.ParamStr(Index);
end;

function ParamCount: Integer;
begin
  Result := system.ParamCount;
end;

{ TStrVarRecArray }

constructor TStrVarRecArray.Create(const Values : array of Variant; FromIndex : 
    integer = 0; ToIndex : integer = -1);
var
  i : Integer;
begin
  inherited Create;
  if ToIndex = -1
    then ToIndex := Length (Values) - 1;
  SetLength (Arr, ToIndex - FromIndex + 1);
  SetLength (Strings, ToIndex - FromIndex + 1);
  for i := FromIndex to ToIndex do
    begin
      Arr [i - FromIndex].VType := vtAnsiString;
      SetStr (i - FromIndex, VarToStr (VarAsType (Values [i], varOleStr)));
    end;
end;

procedure TStrVarRecArray.SetStr(Index : integer; const AStr : string);
begin
  Strings [Index] := AStr;
  Arr [Index].VAnsiString := Pointer (Strings [Index]);
end;

function TStrVarRecArray.Obj: TStrVarRecArray;
begin
  Result := Self;
end;

class function TStrVarRecArray.CreateIntf(const Values : array of Variant; 
    FromIndex : integer = 0; ToIndex : integer = -1): IStrVarRecArray;
begin
  Result := TStrVarRecArray.Create (Values, FromIndex, ToIndex);
end;

destructor TStrVarRecArray.Destroy;
begin
  SetLength (Arr, 0);
  SetLength (Strings, 0);
  inherited;
end;

initialization
  InitPlatformId;
end.
