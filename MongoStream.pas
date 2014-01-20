{
    Copyright 2009-2012 Convey Compliance Systems, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
}

{ Use the option SerializedWithJournal set to True if you want to synchronize
  write operations with Journal writing to prevent overflowing Mongo database
  memory }

unit MongoStream;

interface

uses
  Classes, MongoDB, GridFS, MongoBson, MongoApi;

{$I MongoC_defines.inc}

const
  E_FileNotFound                     = 90300;
  E_FGridFileIsNil                   = 90301;
  E_FGridFSIsNil                     = 90302;
  E_StreamNotCreatedForWriting       = 90303;
  E_StatusMustBeOKInOrderToAllowStre = 90304;
  E_DelphiMongoErrorFailedSignature  = 90305;
  E_FailedInitializingEncryptionKey  = 90306;

  SERIALIZE_WITH_JOURNAL_BYTES_WRITTEN = 1024 * 1024 * 10; (* Serialize with Journal every 10 megs written by default *)

type
  TMongoStreamMode = (msmWrite, msmCreate);
  TMongoStreamStatus = (mssOK, mssMissingChunks);
  TMongoStreamModeSet = set of TMongoStreamMode;
  TAESKeyLength = (akl128, akl192, akl256);
  TMongoStream = class(TStream)
  private
    FCurPos: Int64;
    FGridFS : TGridFS;
    FGridFile : IGridFile;
    FGridFileWriter : IGridfileWriter;
    FStatus: TMongoStreamStatus;
    FMongo: TMongo;
    FSerializedWithJournal: Boolean;
    FBytesWritten: Cardinal;
    FDB : UTF8String;
    FLastSerializeWithJournalResult: IBson;
    FSerializeWithJournalByteWritten: Cardinal;
    FZlibAESContext : Pointer;
    FFlags : Integer;
    procedure CheckGridFile;
    procedure CheckGridFS;
    procedure CheckSerializeWithJournal; {$IFDEF DELPHI2007} inline; {$ENDIF}
    procedure CheckWriteSupport;
    procedure EnforceStatusOK;
    function GetCaseInsensitiveNames: Boolean; {$IFDEF DELPHI2007} inline; {$ENDIF}
    function GetID: IBsonOID; {$IFDEF DELPHI2007} inline; {$ENDIF}
    procedure SerializeWithJournal;
  protected
    function GetSize: {$IFNDEF VER130} Int64; override; {$ELSE}{$IFDEF Enterprise} Int64; override; {$ELSE} Longint; {$ENDIF}{$ENDIF}
    {$IFDEF DELPHI2007}
    procedure SetSize(NewSize: longint); override;
    procedure SetSize(const NewSize: Int64); overload; override;
    procedure SetSize64(const NewSize : Int64);
    {$ELSE}
    procedure SetSize(NewSize: {$IFDef Enterprise} Int64 {$Else} longint {$EndIf}); override;
    {$ENDIF}
  public
    constructor Create(AMongo: TMongo; const ADB, AFileName: UTF8String; const
        AMode: TMongoStreamModeSet; ACompressed: Boolean; const AEncryptionKey:
        String = ''; AEncryptionBits: TAESKeyLength = akl128); overload;
    constructor Create(AMongo: TMongo; const ADB, APrefix, AFileName: UTF8String;
        const AMode: TMongoStreamModeSet; ACaseInsensitiveFileNames, ACompressed:
        Boolean; const AEncryptionKey: String = ''; AEncryptionBits: TAESKeyLength
        = akl128); overload;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    {$IFDEF DELPHI2007}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    function Seek(Offset: longint; Origin: Word ): longint; override;
    {$ELSE}
    function Seek(Offset: {$IFDef Enterprise} Int64 {$Else} longint {$EndIf}; Origin: {$IFNDEF VER130}TSeekOrigin{$Else}{$IFDef Enterprise}TSeekOrigin{$ELSE}Word{$ENDIF}{$ENDIF}): {$IFDef Enterprise} Int64 {$Else} longint {$EndIf}; override;
    {$ENDIF}
    function Write(const Buffer; Count: Longint): Longint; override;

    property CaseInsensitiveNames: Boolean read GetCaseInsensitiveNames;
    property ID: IBsonOID read GetID;
    property LastSerializeWithJournalResult: IBson read FLastSerializeWithJournalResult;
    property Mongo: TMongo read FMongo;
    property SerializedWithJournal: Boolean read FSerializedWithJournal write FSerializedWithJournal default False;
    property SerializeWithJournalByteWritten : Cardinal read FSerializeWithJournalByteWritten write FSerializeWithJournalByteWritten default SERIALIZE_WITH_JOURNAL_BYTES_WRITTEN;
    property Status: TMongoStreamStatus read FStatus;
    property Size: {$IFNDEF VER130}Int64 {$ELSE}{$IFDef Enterprise}Int64 {$ELSE}Longint{$ENDIF}{$ENDIF} read GetSize write {$IFDEF DELPHI2007}SetSize64{$ELSE}SetSize{$ENDIF};
  end;

implementation

const
  SFs = 'fs';
  GET_LAST_ERROR_CMD = 'getLastError';
  WAIT_FOR_JOURNAL_OPTION = 'j';
  aklLenToKeyLen : array [TAESKeyLength] of integer = (128, 192, 256);

resourcestring
  SFileNotFound = 'File %s not found (D%d)';
  SFGridFileIsNil = 'FGridFile is nil (D%d)';
  SFGridFSIsNil = 'FGridFS is nil (D%d)';
  SStreamNotCreatedForWriting = 'Stream not created for writing (D%d)';
  SStatusMustBeOKInOrderToAllowStre = 'Status must be OK in order to allow stream read operations (D%d)';
  SFailedInitializingEncryptionKey = 'Failed initializing encryption key (D%d)';

constructor TMongoStream.Create(AMongo: TMongo; const ADB, AFileName:
    UTF8String; const AMode: TMongoStreamModeSet; ACompressed: Boolean; const
    AEncryptionKey: String = ''; AEncryptionBits: TAESKeyLength = akl128);
begin
  Create(AMongo, ADB, SFs, AFileName, AMode, True, ACompressed, AEncryptionKey, AEncryptionBits);
end;

constructor TMongoStream.Create(AMongo: TMongo; const ADB, APrefix, AFileName:
    UTF8String; const AMode: TMongoStreamModeSet; ACaseInsensitiveFileNames,
    ACompressed: Boolean; const AEncryptionKey: String = ''; AEncryptionBits:
    TAESKeyLength = akl128);
begin
  inherited Create;
  FSerializeWithJournalByteWritten := SERIALIZE_WITH_JOURNAL_BYTES_WRITTEN;
  FDB := ADB;
  FMongo := AMongo;
  FStatus := mssOK;
  FGridFS := TGridFS.Create(AMongo, FDB, APrefix);
  FGridFS.CaseInsensitiveFileNames := ACaseInsensitiveFileNames;
  FFlags := GRIDFILE_NOMD5;
  if ACompressed then
    FFlags := FFlags or GRIDFILE_COMPRESS;
  if AEncryptionKey <> '' then
    FFlags := FFlags or GRIDFILE_ENCRYPT;
  if msmCreate in AMode then
    begin
      FGridFileWriter := FGridFS.writerCreate(AFileName, FFlags);
      FGridFile := FGridFileWriter;
      FGridFileWriter.Truncate(0);
    end
    else
    begin
      FGridFile := FGridFS.find(AFileName, msmWrite in AMode);
      if FGridFile = nil then
        raise EMongo.Create(SFileNotFound, AFileName, E_FileNotFound);
      if msmWrite in AMode then
        FGridFileWriter := FGridFile as IGridfileWriter;
      if FGridFile.getStoredChunkCount <> FGridFile.getChunkCount then
        FStatus := mssMissingChunks;
    end;
  FZlibAESContext := create_ZLib_AES_filter_context(FFlags);
  gridfile_set_filter_context(FGridFile.Handle, FZlibAESContext);
  if (AEncryptionKey <> '') and (ZLib_AES_filter_context_set_encryption_key(FZlibAESContext, PAnsiChar(AnsiString(AEncryptionKey)), aklLenToKeyLen[AEncryptionBits]) <> 0) then
    raise EMongo.Create(SFailedInitializingEncryptionKey, E_FailedInitializingEncryptionKey);
end;

destructor TMongoStream.Destroy;
begin
  FGridFileWriter := nil;
  FGridFile := nil;
  if FGridFS <> nil then
    begin
      FGridFS.Free;
      FGridFS := nil;
    end;
  inherited;
  if FZlibAESContext <> nil then
    destroy_ZLib_AES_filter_context(FZlibAESContext, FFlags);
end;

procedure TMongoStream.CheckGridFile;
begin
  if FGridFile = nil then
    raise EMongo.Create(SFGridFileIsNil, E_FGridFileIsNil);
end;

procedure TMongoStream.CheckGridFS;
begin
  if FGridFS = nil then
    raise EMongo.Create(SFGridFSIsNil, E_FGridFSIsNil);
end;

procedure TMongoStream.CheckWriteSupport;
begin
  if FGridFileWriter = nil then
    raise EMongo.Create(SStreamNotCreatedForWriting, E_StreamNotCreatedForWriting);
end;

procedure TMongoStream.EnforceStatusOK;
begin
  if FStatus <> mssOK then
    raise EMongo.Create(SStatusMustBeOKInOrderToAllowStre, E_StatusMustBeOKInOrderToAllowStre);
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

function TMongoStream.GetSize: {$IFNDEF VER130}Int64{$ELSE}{$IFDef Enterprise}Int64{$ELSE}Longint{$ENDIF}{$ENDIF};
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
function TMongoStream.Seek(Offset: {$IFDef Enterprise} Int64 {$Else} longint {$EndIf}; Origin: {$IFNDEF VER130}TSeekOrigin{$Else}{$IFDef Enterprise}TSeekOrigin{$ELSE}Word{$ENDIF}{$ENDIF}): {$IFDef Enterprise} Int64 {$Else} longint {$EndIf};
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
  FCurPos := FGridFileWriter.setSize(NewSize);
end;

{$IFDEF DELPHI2007}
procedure TMongoStream.SetSize(const NewSize: Int64);
begin
  CheckWriteSupport;
  FCurPos := FGridFileWriter.setSize(NewSize);
end;
{$ENDIF}

procedure TMongoStream.SerializeWithJournal;
var
  Cmd : IBson;
begin
  (* This command will cause Mongo database to wait until Journal file is written before returning *)
  Cmd := BSON([GET_LAST_ERROR_CMD, 1, WAIT_FOR_JOURNAL_OPTION, 1]);
  FLastSerializeWithJournalResult := FMongo.command(FDB, Cmd);
end;

procedure TMongoStream.CheckSerializeWithJournal;
begin
  if FSerializedWithJournal and (FBytesWritten > FSerializeWithJournalByteWritten) then
    begin
      FBytesWritten := 0;
      SerializeWithJournal;
    end;
end;

{$IFDEF DELPHI2007}
procedure TMongoStream.SetSize64(const NewSize : Int64);
begin
  SetSize(NewSize);
end;
{$ENDIF}

function TMongoStream.Write(const Buffer; Count: Longint): Longint;
begin
  CheckWriteSupport;
  Result := FGridFileWriter.Write(@Buffer, Count);
  inc(FCurPos, Result);
  inc(FBytesWritten, Result);
  CheckSerializeWithJournal;
end;

end.
