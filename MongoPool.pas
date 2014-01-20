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
  MongoDB, Classes, SyncObjs, MongoAPI;

const
  E_ConnectionStringProvidedForMongo = 90400;
  E_FailedAuthenticationToMongoDB    = 90401;
  E_FailedConnectingPooledReplicaSet = 90402;

type
  TMongoPooledRecord = record
    Mongo: TMongo;
    Pool: Pointer;
  end;

  TMongoPool = class(TObject)
  private
    FPools: TStringList;
    FLock: TCriticalSection;
    function AcquireFromPool(APool: TList; const AConnectionString: UTF8String): TMongo;
    procedure Authenticate(Result: TMongo; const ADBName, AUserName, APassword: UTF8String);
    function BuildConnectionString(const AHostName, AUserName, APassword, ADBName: UTF8String): UTF8String;
    function CreateMongoConnection(const AConnectionString: UTF8String): TMongo;
    function CreateNewPool(const AConnectionString: UTF8String): Pointer;
    procedure FreePools;
    function ParseReplicaName(const AConnectionString: UTF8String; var AReplicaName: UTF8String): UTF8String;
    procedure RemovePool(const AConnectionString: UTF8String);
  public
    constructor Create;
    destructor Destroy; override;
    function Acquire: TMongoPooledRecord; overload; {$IFDEF DELPHIXE} inline; {$ENDIF}
    function Acquire(const AConnectionString: UTF8String): TMongoPooledRecord; overload;
    function Acquire(const AHostName, AUserName, APassword: UTF8String): TMongoPooledRecord; overload; {$IFDEF DELPHIXE} inline; {$ENDIF}
    function Acquire(const APool: Pointer): TMongo; overload;
    procedure Release(const APoolRecord: TMongoPooledRecord); overload; {$IFDEF DELPHIXE} inline; {$ENDIF}
    function Acquire(const AHostName, AUserName, APassword, ADBName: UTF8String): TMongoPooledRecord; overload;
    class procedure ParseHostUserPwd(const AConnectionString: UTF8String; var AHostName, AUserName, APassword, AServerName: UTF8String);
    procedure Release(APool: Pointer; AMongo: TMongo); overload;
    procedure Release(const AConnectionString: UTF8String; AMongo: TMongo); overload;
    procedure Release(const AHostName, AUserName, APassword: UTF8String; AMongo: TMongo); overload;
    procedure Release(const AHostName, AUserName, APassword, ADBName: UTF8String; AMongo: TMongo); overload;
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
  SInternalErrorExpectedMongoPoolNotFound = 'Internal error. Expected mongo pool object not found on list';
  SConnectionStringProvidedForMongo = 'ConnectionString provided for Mongo pool doesn''t exist (D%d)';
  SFailedAuthenticationToMongoDB    = 'Failed authentication to MongoDB (D%d)';
  SFailedConnectingPooledReplicaSet = 'Failed connecting to pooled replicaset (D%d)';
  // END resource string wizard section

type
  TMongoPoolList = class(TList)
  private
    FLock: TCriticalSection;
    FConnectionString: UTF8String;
    procedure FreeMongosFromPool;
    function GetItems(Index: Integer): TMongo; {$IFDEF DELPHIXE} inline; {$ENDIF}
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
    property Count: Integer read GetCount;
    property ConnectionString: UTF8String read FConnectionString write
        FConnectionString;
    property Items[Index: Integer]: TMongo read GetItems; default;
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

function TMongoPool.Acquire(const AConnectionString: UTF8String): TMongoPooledRecord;
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
  try
    Result.Mongo := AcquireFromPool(Pool, AConnectionString);
  except
    if idx < 0 then
      RemovePool(AConnectionString);
    raise;
  end;
end;

function TMongoPool.AcquireFromPool(APool: TList; const AConnectionString: UTF8String): TMongo;
begin
  if (APool as TMongoPoolList).Count <= 0 then
    Result := CreateMongoConnection(AConnectionString)
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

class procedure TMongoPool.ParseHostUserPwd(const AConnectionString:
    UTF8String; var AHostName, AUserName, APassword, AServerName: UTF8String);
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
         AServerName := Copy(APassword, i + 1, Length(APassword));
        Delete(APassword, i, Length(APassword));
      end;
  end
  else AHostName := AConnectionString;
end;

function TMongoPool.Acquire(const AHostName, AUserName, APassword: UTF8String): TMongoPooledRecord;
begin
  Result := Acquire(AHostName, AUserName, APassword, '');
end;

function TMongoPool.Acquire(const APool: Pointer): TMongo;
begin
  Result := AcquireFromPool(APool, TMongoPoolList(APool).ConnectionString);
end;

function TMongoPool.Acquire: TMongoPooledRecord;
begin
  Result := Acquire(SLOOPBACK);
end;

function TMongoPool.Acquire(const AHostName, AUserName, APassword, ADBName:
    UTF8String): TMongoPooledRecord;
begin
  Result := Acquire(BuildConnectionString(AHostName, AUserName, APassword, ADBName));
end;

procedure TMongoPool.Authenticate(Result: TMongo; const ADBName, AUserName,
    APassword: UTF8String);
var
  Passed : Boolean;
begin
  if AUserName <> '' then
    if ADBName <> '' then
      Passed := Result.authenticate(AUserName, APassword, ADBName)
    else
      Passed := Result.authenticate(AUserName, APassword)
  else Passed := True;
  if not Passed then
    raise EMongo.Create(SFailedAuthenticationToMongoDB, E_FailedAuthenticationToMongoDB);
end;

function TMongoPool.BuildConnectionString(const AHostName, AUserName, APassword, ADBName: UTF8String): UTF8String;
begin
  Result := AHostName + '|' + AUserName + '|' + APassword;
  if Trim(ADBName) <> '' then
    Result := Result + '|' + ADBName;
end;

function TMongoPool.CreateMongoConnection(const AConnectionString: UTF8String):
    TMongo;
var
  AHostName, AUserName, APassword, ADBName, AReplicaName : UTF8String;
  AHostList : TStringList;
  i: Integer;
begin
  Result := nil;
  AHostList := TStringList.Create;
  try
    AHostList.CommaText := ParseReplicaName(AConnectionString, AReplicaName);
    try
      for i := 0 to AHostList.Count - 1 do
        begin
          ParseHostUserPwd(AHostList[i], AHostName, AUserName, APassword, ADBName);
          if AHostList.Count > 1 then
            begin
              if Result = nil then
                Result := TMongoReplSet.Create(AReplicaName);
              (Result as TMongoReplSet).addSeed(AHostName);
            end
          else
            Result := TMongo.Create(AHostName);
          if (i = AHostList.Count - 1) and (Result is TMongoReplset) then
            if not (Result as TMongoReplSet).Connect then
              raise EMongo.Create(SFailedConnectingPooledReplicaSet, E_FailedConnectingPooledReplicaSet);
          Authenticate(Result, ADBName, AUserName, APassword);
        end;
    except
      if Result <> nil then
        Result.Free;
      raise;
    end;
  finally
    AHostList.Free;
  end;
end;

function TMongoPool.CreateNewPool(const AConnectionString: UTF8String): Pointer;
begin
  Result := TMongoPoolList.Create;
  TMongoPoolList(Result).ConnectionString := AConnectionString;
  FPools.AddObject(AConnectionString, Result);
end;

function TMongoPool.ParseReplicaName(const AConnectionString: UTF8String; var
    AReplicaName: UTF8String): UTF8String;
var
  p : integer;
begin
  p := pos('@', AConnectionString);
  if p > 0 then
    begin
      AReplicaName := copy(AConnectionString, 1, p - 1);
      Result := copy(AConnectionString, p + 1, length(AConnectionString) - p);
    end
  else
  begin
    AReplicaName := '';
    Result := AConnectionString;
  end;
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

procedure TMongoPool.Release(const AConnectionString: UTF8String; AMongo: TMongo);
var
  idx: Integer;
begin
  FLock.Enter;
  try
    idx := FPools.IndexOf(AConnectionString);
    if idx >= 0 then
      Release(FPools.Objects[idx] as TMongoPoolList, AMongo)
    else 
      raise EMongo.Create(SConnectionStringProvidedForMongo, E_ConnectionStringProvidedForMongo)
  finally
    FLock.Leave;
  end;
end;

procedure TMongoPool.Release(const AHostName, AUserName, APassword: UTF8String; AMongo: TMongo);
begin
  Release(AHostName, AUserName, APassword, '', AMongo);
end;

procedure TMongoPool.Release(const AHostName, AUserName, APassword, ADBName:
    UTF8String; AMongo: TMongo);
var
  AConnectionString: UTF8String;
begin
  if AUserName <> '' then
    AConnectionString := BuildConnectionString(AHostName, AUserName, APassword, ADBName)
  else
    AConnectionString := AHostName;
  Release(AConnectionString, AMongo);
end;

procedure TMongoPool.RemovePool(const AConnectionString: UTF8String);
var
  idx : integer;
  Pool : TMongoPoolList;
begin
  FLock.Enter;
  try
    idx := FPools.IndexOf(AConnectionString);
    if idx >= 0 then
      begin
        Pool := FPools.Objects[idx] as TMongoPoolList;
        FPools.Delete(idx);
        Pool.Free;
      end
    else
      raise Exception.Create(SInternalErrorExpectedMongoPoolNotFound);
  finally
    FLock.Leave;
  end;
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

procedure TMongoPoolList.Lock;
begin
  FLock.Enter;
end;

procedure TMongoPoolList.Unlock;
begin
  FLock.Leave;
end;

end.
