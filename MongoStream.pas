unit MongoStream;

interface

uses
  Classes, MongoDB, GridFS, MongoBson, MongoApi;

{$I MongoC_defines.inc}

type
  TMongoStreamMode = (msmWrite, msmCreate);
  TMongoStreamStatus = (mssOK, mssMissingChunks);
  TMongoStreamModeSet = set of TMongoStreamMode;
  TMongoStream = class(TStream)
  private
    FCurPos: Int64;
    FGridFS : TGridFS;
    FGridFile : IGridFile;
    FGridFileWriter : IGridfileWriter;
    FStatus: TMongoStreamStatus;
    FMongo: TMongo;
    procedure CheckGridFile;
    procedure CheckGridFS;
    procedure CheckWriteSupport;
    procedure EnforceStatusOK;
    function GetCaseInsensitiveNames: Boolean;
    function GetID: IBsonOID;
  protected
    MongoSignature: cardinal;
    procedure CheckValid;
    function GetSize: Int64; override;
    {$IFDEF DELPHI2007}
    procedure SetSize(NewSize: longint); override;
    procedure SetSize(const NewSize: Int64); overload; override;
    {$ELSE}
    procedure SetSize(NewSize: {$IFDef Enterprise} Int64 {$Else} longint {$EndIf}); override;
    {$ENDIF}
  public
    constructor Create(AMongo: TMongo; const ADB, AFileName: AnsiString; const
        AMode: TMongoStreamModeSet; ACompressed: Boolean); overload;
    constructor Create(AMongo: TMongo; const ADB, APrefix, AFileName: AnsiString;
        const AMode: TMongoStreamModeSet; ACaseInsensitiveFileNames, ACompressed:
        Boolean); overload;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    {$IFDEF DELPHI2007}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    function Seek(Offset: longint; Origin: Word ): longint; override;
    {$ELSE}
    function Seek(Offset: {$IFDef Enterprise} Int64 {$Else} longint {$EndIf}; Origin: TSeekOrigin ): {$IFDef Enterprise} Int64 {$Else} longint {$EndIf}; override;
    {$ENDIF}
    function Write(const Buffer; Count: Longint): Longint; override;
    property CaseInsensitiveNames: Boolean read GetCaseInsensitiveNames;
    property ID: IBsonOID read GetID;
    property Mongo: TMongo read FMongo;
    property Status: TMongoStreamStatus read FStatus;
  end;

implementation

// START resource string wizard section
const
  SFs = 'fs';
// END resource string wizard section


// START resource string wizard section
resourcestring
  SFileNotFound = 'File %s not found';
  SFGridFileIsNil = 'FGridFile is nil';
  SFGridFSIsNil = 'FGridFS is nil';
  SStreamNotCreatedForWriting = 'Stream not created for writing';
  SStatusMustBeOKInOrderToAllowStre = 'Status must be OK in order to allow stream read operations';
// END resource string wizard section


constructor TMongoStream.Create(AMongo: TMongo; const ADB, AFileName:
    AnsiString; const AMode: TMongoStreamModeSet; ACompressed: Boolean);
begin
  Create(AMongo, ADB, SFs, AFileName, AMode, True, ACompressed);
end;

constructor TMongoStream.Create(AMongo: TMongo; const ADB, APrefix, AFileName:
    AnsiString; const AMode: TMongoStreamModeSet; ACaseInsensitiveFileNames,
    ACompressed: Boolean);
var
  AFlags : Integer;
begin
  inherited Create;
  MongoSignature := DELPHI_MONGO_SIGNATURE;
  FMongo := AMongo;
  FStatus := mssOK;
  FGridFS := TGridFS.Create(AMongo, ADB, APrefix);
  FGridFS.CaseInsensitiveFileNames := ACaseInsensitiveFileNames;
  if msmCreate in AMode then
    begin
      FGridFS.removeFile(AFileName);
      AFlags := GRIDFILE_NOMD5;
      if ACompressed then
        AFlags := AFlags or GRIDFILE_COMPRESS;
      FGridFileWriter := FGridFS.writerCreate(AFileName, AFlags);
      FGridFile := FGridFileWriter;
    end
    else
    begin
      FGridFile := FGridFS.find(AFileName, msmWrite in AMode);
      if FGridFile = nil then
        raise EMongo.CreateFmt(SFileNotFound, [AFileName]);
      if msmWrite in AMode then
        FGridFileWriter := FGridFile as IGridfileWriter;
      if FGridFile.getStoredChunkCount <> FGridFile.getChunkCount then
        FStatus := mssMissingChunks;
    end;
end;

destructor TMongoStream.Destroy;
begin
  CheckValid;
  FGridFileWriter := nil;
  FGridFile := nil;
  if FGridFS <> nil then
    begin
      FGridFS.Free;
      FGridFS := nil;
    end;
  inherited;
  MongoSignature := 0;
end;

procedure TMongoStream.CheckGridFile;
begin
  CheckValid;
  if FGridFile = nil then
    raise EMongo.Create(SFGridFileIsNil);
end;

procedure TMongoStream.CheckGridFS;
begin
  CheckValid;
  if FGridFS = nil then
    raise EMongo.Create(SFGridFSIsNil);
end;

procedure TMongoStream.CheckValid;
begin
  if MongoSignature <> DELPHI_MONGO_SIGNATURE then
    raise EMongoFatalError.Create('Delphi Mongo error failed signature validation');
end;

procedure TMongoStream.CheckWriteSupport;
begin
  CheckValid;
  if FGridFileWriter = nil then
    raise EMongo.Create(SStreamNotCreatedForWriting);
end;

procedure TMongoStream.EnforceStatusOK;
begin
  CheckValid;
  if FStatus <> mssOK then
    raise EMongo.Create(SStatusMustBeOKInOrderToAllowStre);
end;

function TMongoStream.GetCaseInsensitiveNames: Boolean;
begin
  CheckGridFS;
  Result := FGridFS.CaseInsensitiveFileNames;
end;

function TMongoStream.GetID: IBsonOID;
begin
  CheckGridFile;
  Result := FGridFile.getId;
end;

function TMongoStream.GetSize: Int64;
begin
  CheckGridFile;
  Result := FGridFile.getLength;
end;

function TMongoStream.Read(var Buffer; Count: Longint): Longint;
begin
  EnforceStatusOK;
  CheckGridFile;
  Result := FGridFile.Read(@Buffer, Count);
  inc(FCurPos, Result);
end;

{$IFDEF DELPHI2007}
function TMongoStream.Seek(Offset: longint; Origin: Word ): longint;
{$ELSE}
function TMongoStream.Seek(Offset: {$IFDef Enterprise} Int64 {$Else} longint {$EndIf}; Origin: TSeekOrigin ): {$IFDef Enterprise} Int64 {$Else} longint {$EndIf};
{$ENDIF}
begin
  CheckGridFile;
  case Origin of
    soFromBeginning : FCurPos := Offset;
    soFromCurrent : FCurPos := FCurPos + Offset;
    soFromEnd : FCurPos := Size + Offset;
  end;
  Result := FGridFile.Seek(FCurPos);
end;

{$IFDEF DELPHI2007}
function TMongoStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  CheckValid;
  case Origin of
    soBeginning : FCurPos := Offset;
    soCurrent : FCurPos := FCurPos + Offset;
    soEnd : FCurPos := Size + Offset;
  end;
  Result := FGridFile.Seek(FCurPos);
end;

{$ENDIF}

{$IFDEF DELPHI2007}
procedure TMongoStream.SetSize(NewSize: longint);
{$ELSE}
procedure TMongoStream.SetSize(NewSize: {$IFDef Enterprise} Int64 {$Else} longint {$EndIf});
{$ENDIF}
begin
  CheckWriteSupport;
  FCurPos := FGridFileWriter.Truncate(NewSize);
end;

{$IFDEF DELPHI2007}
procedure TMongoStream.SetSize(const NewSize: Int64);
begin
  CheckWriteSupport;
  FCurPos := FGridFileWriter.Truncate(NewSize);
end;
{$ENDIF}

function TMongoStream.Write(const Buffer; Count: Longint): Longint;
begin
  CheckWriteSupport;
  FGridFileWriter.Write(@Buffer, Count);
  Result := Count;
  inc(FCurPos, Result);
end;

end.

