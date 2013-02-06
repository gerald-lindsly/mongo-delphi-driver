unit MongoPool;
{
     Copyright 2012 Convey Compliance Systems, Inc.

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

{ This class provides connection pooling for TMongo or TMongoReplSet object. All public methods, except constructor and
  destructor are threadsafe }

{$I DelphiVersion_defines.inc}

interface

uses
  MongoDB, Classes, SyncObjs;

type
  TMongoPooledRecord = record
    Mongo: TMongo;
    Pool: Pointer;
  end;

  TMongoPool = class(TObject)
  private
    FPools: TStringList;
    FLock: TCriticalSection;
    function AcquireFromPool(APool: TList; const AConnectionString: AnsiString): TMongo;
    function BuildConnectionString(const AHostName, AUserName, APassword, ADBName: AnsiString): AnsiString;
    function CreateNewPool(const AConnectionString: AnsiString): Pointer;
    procedure FreePools;
    procedure ParseHostUserPwd(const AConnectionString: AnsiString; var AHostName, AUserName, APassword, AServerName: AnsiString);
  public
    constructor Create;
    destructor Destroy; override;
    function Acquire: TMongoPooledRecord; overload; {$IFDEF DELPHIXE} inline; {$ENDIF}
    function Acquire(const AConnectionString: AnsiString): TMongoPooledRecord; overload;
    function Acquire(const AHostName, AUserName, APassword: AnsiString): TMongoPooledRecord; overload; {$IFDEF DELPHIXE} inline; {$ENDIF}
    function Acquire(const APool: Pointer): TMongo; overload; {$IFDEF DELPHIXE} inline; {$ENDIF}
    procedure Release(const APoolRecord: TMongoPooledRecord); overload; {$IFDEF DELPHIXE} inline; {$ENDIF}
    function Acquire(const AHostName, AUserName, APassword, ADBName: AnsiString): TMongoPooledRecord; overload;
    procedure Release(APool: Pointer; AMongo: TMongo); overload;
    procedure Release(const AConnectionString: AnsiString; AMongo: TMongo); overload;
    procedure Release(const AHostName, AUserName, APassword: AnsiString; AMongo: TMongo); overload;
    procedure Release(const AHostName, AUserName, APassword, ADBName: AnsiString; AMongo: TMongo); overload;
  end;

implementation

uses
  SysUtils;

// START resource string wizard section
const
  SLOOPBACK = '127.0.0.1';
  // END resource string wizard section

  // START resource string wizard section
resourcestring
  SConnectionStringProvidedForMongo = 'ConnectionString provided for Mongo pool doesn''t exist';
  SFailedAuthenticationToMongoDB    = 'Failed authentication to MongoDB';
  // END resource string wizard section

type
  TMongoPoolList = class(TList)
  private
    FLock: TCriticalSection;
    procedure FreeMongosFromPool;
    function GetItems(Index: Integer): TMongo; {$IFDEF DELPHIXE} inline; {$ENDIF}
    function GetCount: Integer;
    procedure SetItems(Index: Integer; const Value: TMongo); {$IFDEF DELPHIXE} inline; {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TMongo read GetItems write SetItems; default;
  end;

  { TMongoPool }

constructor TMongoPool.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FPools := TStringList.Create;
  FPools.Sorted := true;
end;

destructor TMongoPool.Destroy;
begin
  FreePools;
  FPools.Free;
  FLock.Free;
  inherited;
end;

procedure TMongoPool.FreePools;
var
  i: Integer;
begin
  for i := 0 to FPools.Count - 1 do
    FPools.Objects[i].Free;
  FPools.Clear;
end;

function TMongoPool.Acquire(const AConnectionString: AnsiString): TMongoPooledRecord;
var
  idx: Integer;
  Pool: TMongoPoolList;
begin
  FLock.Enter;
  try
    idx := FPools.IndexOf(AConnectionString);
    if idx < 0 then
      Pool := CreateNewPool(AConnectionString)
    else 
      Pool := FPools.Objects[idx] as TMongoPoolList;
  finally
    FLock.Leave;
  end;
  Result.Pool := Pool;
  Result.Mongo := AcquireFromPool(Pool, AConnectionString);
end;

function TMongoPool.AcquireFromPool(APool: TList; const AConnectionString: AnsiString): TMongo;
var
  AHostName: AnsiString;
  AUserName: AnsiString;
  APassword: AnsiString;
  ADBName : AnsiString;
  Passed : boolean;
begin
  if (APool as TMongoPoolList).Count <= 0 then
    begin
      ParseHostUserPwd(AConnectionString, AHostName, AUserName, APassword, ADBName);
      Result := TMongo.Create(AHostName);
      if ADBName <> '' then
        Passed := Result.authenticate(AUserName, APassword, ADBName)
      else
        Passed := Result.authenticate(AUserName, APassword);
      if not Passed then raise Exception.Create(SFailedAuthenticationToMongoDB);
    end
  else
    with APool as TMongoPoolList do
      begin
        Lock;
        try
          Result := Items[APool.Count - 1];
          Delete(Count - 1);
        finally
          Unlock;
        end;
      end;
end;

procedure TMongoPool.ParseHostUserPwd(const AConnectionString: AnsiString; var
    AHostName, AUserName, APassword, AServerName: AnsiString);
var
  i: Integer;
begin
  i := Pos('|', AConnectionString);
  if i > 0 then
  begin
    AHostName := Copy(AConnectionString, 1, i - 1);
    AUserName := Copy(AConnectionString, i + 1, Length(AConnectionString));
    i := Pos('|', AUserName);
    APassword := Copy(AUserName, i + 1, Length(AUserName));
    Delete(AUserName, i, Length(AUserName));
    i := Pos('|', APassword);
    if (i > 0) then
      begin
        if (i < Length(APassword)) then
         AServerName := Copy(APassword, i+1, Length(APassword));
        Delete(APassword, i, Length(APassword));
      end;
  end;
end;

function TMongoPool.Acquire(const AHostName, AUserName, APassword: AnsiString): TMongoPooledRecord;
begin
  Result := Acquire(AHostName, AUserName, APassword, '');
end;

function TMongoPool.Acquire(const APool: Pointer): TMongo;
begin
  Result := AcquireFromPool(APool, '');
end;

function TMongoPool.Acquire: TMongoPooledRecord;
begin
  Result := Acquire(SLOOPBACK);
end;

function TMongoPool.Acquire(const AHostName, AUserName, APassword, ADBName:
    AnsiString): TMongoPooledRecord;
begin
  Result := Acquire(BuildConnectionString(AHostName, AUserName, APassword, ADBName));
end;

function TMongoPool.BuildConnectionString(const AHostName, AUserName, APassword, ADBName: AnsiString): AnsiString;
begin
  Result := AHostName + '|' + AUserName + '|' + APassword;
  if Trim(ADBName) <> '' then
    Result := Result + '|' + ADBName;
end;

function TMongoPool.CreateNewPool(const AConnectionString: AnsiString): Pointer;
begin
  Result := TMongoPoolList.Create;
  FPools.AddObject(AConnectionString, Result);
end;

procedure TMongoPool.Release(const APoolRecord: TMongoPooledRecord);
begin
  Release(APoolRecord.Pool, APoolRecord.Mongo);
end;

procedure TMongoPool.Release(APool: Pointer; AMongo: TMongo);
begin
  with TMongoPoolList(APool) do
  begin
    Lock;
    try
      Add(AMongo);
    finally
      Unlock;
    end;
  end;
end;

procedure TMongoPool.Release(const AConnectionString: AnsiString; AMongo: TMongo);
var
  idx: Integer;
begin
  FLock.Enter;
  try
    idx := FPools.IndexOf(AConnectionString);
    if idx >= 0 then
      Release(FPools.Objects[idx] as TMongoPoolList, AMongo)
    else 
      raise Exception.Create(SConnectionStringProvidedForMongo)
    finally
      FLock.Leave;
  end;
end;

procedure TMongoPool.Release(const AHostName, AUserName, APassword: AnsiString; AMongo: TMongo);
begin
  Release(AHostName, AUserName, APassword, '', AMongo);
end;

procedure TMongoPool.Release(const AHostName, AUserName, APassword, ADBName:
    AnsiString; AMongo: TMongo);
var
  AConnectionString: AnsiString;
begin
  if AUserName <> '' then
    AConnectionString := BuildConnectionString(AHostName, AUserName, APassword, ADBName)
  else
    AConnectionString := AHostName;
  Release(AConnectionString, AMongo);
end;

{ TMongoPoolList }

constructor TMongoPoolList.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
end;

destructor TMongoPoolList.Destroy;
begin
  FreeMongosFromPool;
  FLock.Free;
  inherited;
end;

procedure TMongoPoolList.FreeMongosFromPool;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  Clear;
end;

function TMongoPoolList.GetCount: Integer;
begin
  Lock;
  try
    Result := inherited Count;
  finally
    Unlock;
  end;
end;

function TMongoPoolList.GetItems(Index: Integer): TMongo;
begin
  Result := TMongo(inherited Items[Index]);
end;

procedure TMongoPoolList.SetItems(Index: Integer; const Value: TMongo);
begin
  inherited Items[Index] := Value;
end;

procedure TMongoPoolList.Lock;
begin
  FLock.Enter;
end;

procedure TMongoPoolList.Unlock;
begin
  FLock.Leave;
end;

end.
