unit uPrimitiveAllocator;

interface

{$i DelphiVersion_defines.inc}

type
  {$IFNDEF DELPHI2007}
  PInteger = ^Integer;
  PBoolean = ^Boolean;
  {$ENDIF}
  IPrimitiveAllocator = interface
    ['{5B1FEFAE-77CF-41F6-98D6-7BBF869D289A}']
    function New(const value : Integer): PInteger; overload;
    function New(const value : Boolean): PBoolean; overload;
    function New(const value : AnsiChar): PAnsiChar; overload;
    function New(const value : Extended): PExtended; overload;
    function NewShortString(const value : ShortString): PShortString; overload;
    function New(const value : PAnsiChar): PAnsiChar; overload;
    function New(const value : WideChar): PWideChar; overload;
    function New(const value : AnsiString): PAnsiString; overload;
    function New(const value : Int64): PInt64; overload;
    {$IFDEF DELPHI2007}
    function New(const value : WideString): PWideString; overload;
    {$ENDIF}
    {$IFDEF DELPHI2009}
    function New(const value : currency): PCurrency; overload;
    function New(const value : PWideChar): PWideChar; overload;
    function New(const value : UnicodeString): PUnicodeString; overload;
    {$ENDIF}
  end;

function NewPrimitiveAllocator(InitialSize: Cardinal = 512) : IPrimitiveAllocator;

implementation

uses
  SysUtils, Classes, uAllocators;

type
  TPrimitiveAllocator = class(TInterfacedObject, IPrimitiveAllocator)
  private
    FHeap : TVariableBlockHeap;
    FStringsHeap : TFixedBlockHeap;
    FMemToClean : TList;
    procedure AddToMemToClean(APointer: Pointer);
    procedure CleanTrackedPointers;
    procedure InitStringHeap;
  public
    constructor Create(AInitialSize: Cardinal);
    destructor Destroy; override;
    function New(const value: Integer): PInteger; overload;
    function New(const value: Boolean): PBoolean; overload;
    function New(const value: AnsiChar): PAnsiChar; overload;
    function New(const value: Extended): PExtended; overload;
    function NewShortString(const value : ShortString): PShortString; overload;
    function New(const value: PAnsiChar): PAnsiChar; overload;
    function New(const value: WideChar): PWideChar; overload;
    function New(const value : AnsiString): PAnsiString; overload;
    function New(const value: Int64): PInt64; overload;
    {$IFDEF DELPHI2007}
    function New(const value : WideString): PWideString; overload;
    {$ENDIF}
    {$IFDEF DELPHI2009}
    function New(const value: Currency): PCurrency; overload;
    function New(const value: PWideChar): PWideChar; overload;
    function New(const value : UnicodeString): PUnicodeString; overload;
    {$ENDIF}
  end;

constructor TPrimitiveAllocator.Create(AInitialSize: Cardinal);
begin
  inherited Create;
  FHeap := TVariableBlockHeap.Create(AInitialSize);
  FHeap.TrackBlockArrays := True;
end;

destructor TPrimitiveAllocator.Destroy;
begin
  if FHeap <> nil then
    FreeAndNil(FHeap);
  CleanTrackedPointers;
  if FMemToClean <> nil then
    FreeAndNil(FMemToClean);
  if FStringsHeap <> nil then
    FreeAndNil(FStringsHeap);
  inherited Destroy;
end;

procedure TPrimitiveAllocator.AddToMemToClean(APointer: Pointer);
begin
  if FMemToClean = nil then
    FMemToClean := TList.Create;
  FMemToClean.Add(APointer);
end;

procedure TPrimitiveAllocator.CleanTrackedPointers;
var
  i : integer;
begin
  if FMemToClean = nil then
    exit;
  for i := 0 to FMemToClean.Count - 1 do
    begin
      case PVarRec(FMemToClean[i]).VType of
        vtAnsiString :
          begin
            PAnsiString(PVarRec(FMemToClean[i]).VAnsiString)^ := '';
            System.Dispose(PAnsiString(PVarRec(FMemToClean[i]).VAnsiString));
          end;
        {$IFDEF DELPHI2009}
        vtUnicodeString :
          begin
            PUnicodeString(PVarRec(FMemToClean[i]).VUnicodeString)^ := '';
            System.Dispose(PUnicodeString(PVarRec(FMemToClean[i]).VUnicodeString));
          end;
        {$ENDIF}
        vtWideString :
          begin
            PWideString(PVarRec(FMemToClean[i]).VWideString)^ := '';
            System.Dispose(PWideString(PVarRec(FMemToClean[i]).VWideString));
          end;
      end;
    end;
  FMemToClean.Clear;
end;

procedure TPrimitiveAllocator.InitStringHeap;
begin
  if FStringsHeap <> nil then
    exit;
  FStringsHeap := TFixedBlockHeap.Create(sizeof(TVarRec), 16);
  FStringsHeap.TrackBlockArrays := True;
end;

function TPrimitiveAllocator.New(const value: AnsiChar): PAnsiChar;
begin
  Result := FHeap.Alloc(sizeof(value));
  PAnsiChar(Result)^ := value;
end;

function TPrimitiveAllocator.New(const value : AnsiString): PAnsiString;
var
  Rec : PVarRec;
begin
  InitStringHeap;
  Rec := FStringsHeap.Alloc;
  Rec.VType := vtAnsiString;
  System.New(PAnsiString(Rec.VAnsiString));
  PAnsiString(Rec.VAnsiString)^ := value;
  Result := Rec.VAnsiString;
  AddToMemToClean(Rec);
end;

function TPrimitiveAllocator.New(const value: Boolean): PBoolean;
begin
  Result := FHeap.Alloc(sizeof(value));
  PBoolean(Result)^ := value;
end;

{$IFDEF DELPHI2009}
function TPrimitiveAllocator.New(const value: Currency): PCurrency;
begin
  Result := FHeap.Alloc(sizeof(value));
  PCurrency(Result)^ := value;
end;
{$ENDIF}

function TPrimitiveAllocator.New(const value: Extended): PExtended;
begin
  Result := FHeap.Alloc(sizeof(value));
  PExtended(Result)^ := value;
end;

function TPrimitiveAllocator.New(const value: Integer): PInteger;
begin
  Result := FHeap.Alloc(sizeof(value));
  PInteger(Result)^ := value;
end;

function TPrimitiveAllocator.New(const value: Int64): PInt64;
begin
  Result := FHeap.Alloc(sizeof(value));
  PInt64(Result)^ := value;
end;

function TPrimitiveAllocator.New(const value: PAnsiChar): PAnsiChar;
var
  ABytes : Cardinal;
begin
  ABytes := (StrLen(value) + 1) * sizeof(AnsiChar);
  Result := FHeap.Alloc(ABytes);
  system.Move(value^, Result^, ABytes);
end;

{$IFDEF DELPHI2009}
function TPrimitiveAllocator.New(const value: PWideChar): PWideChar;
var
  ABytes : Cardinal;
begin
  ABytes := (StrLen(value) + 1) * sizeof(WideChar);
  Result := FHeap.Alloc(ABytes);
  system.Move(value^, Result^, ABytes);
end;
{$ENDIF}

function TPrimitiveAllocator.NewShortString(const value : ShortString): PShortString;
begin
  Result := FHeap.Alloc(sizeof(value));
  PShortString(Result)^ := value;
end;

{$IFDEF DELPHI2009}
function TPrimitiveAllocator.New(const value : UnicodeString): PUnicodeString;
var
  Rec : PVarRec;
begin
  InitStringHeap;
  Rec := FStringsHeap.Alloc;
  Rec.VType := vtUnicodeString;
  System.New(PUnicodeString(Rec.VUnicodeString));
  PUnicodeString(Rec.VUnicodeString)^ := value;
  Result := Rec.VUnicodeString;
  AddToMemToClean(Rec);
end;
{$ENDIF}

{$IFDEF DELPHI2007}
function TPrimitiveAllocator.New(const value : WideString): PWideString;
var
  Rec : PVarRec;
begin
  InitStringHeap;
  Rec := FStringsHeap.Alloc;
  Rec.VType := vtWideString;
  System.New(PWideString(Rec.VWideString));
  PWideString(Rec.VWideString)^ := value;
  Result := Rec.VWideString;
  AddToMemToClean(Rec);
end;
{$ENDIF}

function TPrimitiveAllocator.New(const value: WideChar): PWideChar;
begin
  Result := FHeap.Alloc(sizeof(value));
  PWideChar(Result)^ := value;
end;

function NewPrimitiveAllocator(InitialSize: Cardinal = 512):
    IPrimitiveAllocator;
begin
  Result := TPrimitiveAllocator.Create(InitialSize);
end;


end.
