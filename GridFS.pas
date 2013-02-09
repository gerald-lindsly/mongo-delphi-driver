{
     Copyright 2009-2011 10gen Inc.

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
{ GridFS Unit - The classes in this unit are used to store and/or
  access a "Grid File System" (GridFS) on a MongoDB server.
  While primarily intended to store large documents that
  won't fit on the server as a single BSON object,
  GridFS may also be used to store large numbers of smaller files.

  See http://www.mongodb.org/display/DOCS/GridFS and
  http://www.mongodb.org/display/DOCS/When+to+use+GridFS.

  Objects of class TGridFS represent the interface to the GridFS.
  Objects of class TGridfile are used to access gridfiles and read from them.
  Objects of class TGridfileWriter are used to write buffered data to the GridFS.
}
unit GridFS;

interface

uses
  MongoDB, MongoBson, MongoApi;

const
  GRIDFILE_DEFAULT = 0;
  GRIDFILE_NOMD5 = 1;
  GRIDFILE_COMPRESS = 2;

type
  IGridfile       = interface;
  IGridfileWriter = interface;

  TGridFS = class(TMongoObject)
  private
    { Pointer to externally managed data representing the GridFS }
    Handle: Pointer;
        { Holds a reference to the TMongo object used in construction.
          Prevents release until the TGridFS is destroyed. }
    conn: TMongo;
    fdb : UTF8String;
    FPrefix: UTF8String;
    procedure CheckHandle;
    procedure setAutoCheckLastError(value : Boolean);
    function getAutoCheckLastError : Boolean;
    function GetCaseInsensitiveFileNames: Boolean;
    procedure SetCaseInsensitiveFileNames(const Value: Boolean);
  public
      { Create a TGridFS object for accessing the GridFS on the MongoDB server.
        Parameter mongo is an already established connection object to the
        server; db is the name of the database in which to construct the GridFS.
        The prefix defaults to 'fs'.}
    constructor Create(mongo: TMongo; const db: UTF8String); overload;
      { Create a TGridFS object for accessing the GridFS on the MongoDB server.
        Parameter mongo is an already established connection object to the
        server; db is the name of the database in which to construct the GridFS.
        prefix is appended to the database name for the collections that represent
        the GridFS: 'db.prefix.files' & 'db.prefix.chunks'. }
    constructor Create(mongo: TMongo; const db, prefix: UTF8String); overload;
      { Store a file on the GridFS.  filename is the path to the file.
        Returns True if successful; otherwise, False. }
    function storeFile(const FileName: UTF8String; Flags: Integer =
        GRIDFILE_DEFAULT): Boolean; overload;
      { Store a file on the GridFS.  filename is the path to the file.
        remoteName is the name that the file will be known as within the GridFS.
        Returns True if successful; otherwise, False. }
    function storeFile(const FileName, remoteName: UTF8String; Flags: Integer =
        GRIDFILE_DEFAULT): Boolean; overload;
      { Store a file on the GridFS.  filename is the path to the file.
        remoteName is the name that the file will be known as within the GridFS.
        contentType is the MIME-type content type of the file.
        Returns True if successful; otherwise, False. }
    function storeFile(const FileName, remoteName, contentType: UTF8String; Flags:
        Integer = GRIDFILE_DEFAULT): Boolean; overload;
    { Remove a file from the GridFS. }
    procedure removeFile(const remoteName: UTF8String);
      { Store data as a GridFS file.  Pointer is the address of the data and length
        is its size. remoteName is the name that the file will be known as within the GridFS.
        Returns True if successful; otherwise, False. }
    function store(p: Pointer; Length: Int64; const remoteName: UTF8String; Flags:
        Integer = GRIDFILE_DEFAULT): Boolean; overload;
      { Store data as a GridFS file.  Pointer is the address of the data and length
        is its size. remoteName is the name that the file will be known as within the GridFS.
        contentType is the MIME-type content type of the file.
        Returns True if successful; otherwise, False. }
    function store(p: Pointer; Length: Int64; const remoteName, contentType:
        UTF8String; Flags: Integer = GRIDFILE_DEFAULT): Boolean; overload;
      { Create a TGridfileWriter object for writing buffered data to a GridFS file.
        remoteName is the name that the file will be known as within the GridFS. }
    function writerCreate(const remoteName: UTF8String; Flags: Integer =
        GRIDFILE_DEFAULT): IGridfileWriter; overload;
      { Create a TGridfileWriter object for writing buffered data to a GridFS file.
        remoteName is the name that the file will be known as within the GridFS.
        contentType is the MIME-type content type of the file. }
    function writerCreate(const remoteName, contentType: UTF8String; Flags: Integer
        = GRIDFILE_DEFAULT): IGridfileWriter; overload;
      { Locate a GridFS file by its remoteName and return a TGridfile object for
        accessing it. }
    function find(const remoteName: UTF8String; AWriteMode: Boolean): IGridfile;
        overload;
      { Locate a GridFS file by an TBson query document on the GridFS file descriptors.
        Returns a TGridfile object for accessing it. }
    function find(query: IBson; AWriteMode: Boolean): IGridfile; overload;
    { Destroy this GridFS object.  Releases external resources. }
    function createGridFile: IGridFile;
    destructor Destroy; override;
    property AutoCheckLastError: Boolean read getAutoCheckLastError write setAutoCheckLastError;
    property CaseInsensitiveFileNames: Boolean read GetCaseInsensitiveFileNames
        write SetCaseInsensitiveFileNames;
    property Mongo: TMongo read conn;
  end;

  IGridFile = interface
    ['{DA93414C-1D0B-4F08-A78A-F1914A2E214C}']
      { Get the Ith chunk of this gridfile.  The content of the chunk is
        in the 'data' field of the returned TBson document.  Returns nil
        if i is not in the range 0 to getChunkCount() - 1. }
    function getChunk(i: Integer): IBson;
    { Get the number of chunks into which the file is divided. }
    function getChunkCount: Integer;
    { Get the number of chunks into which the file is divided. }
    function getStoredChunkCount: Int64;
      { Get a cursor for stepping through a range of chunks of this gridfile.
        i is the index of the first chunk to be returned.  count is the number
        of chunks to return.  Returns nil if there are no chunks in the
        specified range. }
    function getChunks(i: Integer; Count: Integer): IMongoCursor;
    { Get the size of the chunks into which the file is divided. }
    function getChunkSize: Integer;
    { Get the content type of this gridfile. }
    function getContentType: UTF8String;
    { Get the descriptor of this gridfile as a TBson document. }
    function getDescriptor: IBson;
    { Get the filename (remoteName) of this gridfile. }
    function getFilename: UTF8String;
    { Get the length of this gridfile. }
    function getLength: Int64;
    { Get the MD5 hash of this gridfile.  This is a 16-digit hex string. }
    function getMD5: UTF8String;
      { Get any metadata associated with this gridfile as a TBson document.
        Returns nil if there is none. }
    function getMetadata: IBson;
    { Get the upload date of this gridfile. }
    function getUploadDate: TDateTime;
      { read data from this gridfile.  The gridfile maintains a current position
        so that successive reads will return consecutive data. The data is
        read to the address indicated by p and length bytes are read.  The size
        of the data read is returned and can be less than length if there was
        not enough data remaining to be read. }
    function read(p: Pointer; Length: Int64): Int64;
      { seek to a specified offset within the gridfile.  read() will then
        return data starting at that location.  Returns the position that
        was set.  This can be at the end of the gridfile if offset is greater
        the length of this gridfile. }
    function seek(offset: Int64): Int64;
    function getID : IBsonOID;
    function Handle : Pointer;
  end;

  IGridfileWriter = interface(IGridFile)
    ['{1BD1F2BA-C045-47CD-B1C7-611A77BCB590}']
      { Finish with this IGridfileWriter.  Flushes any data remaining to be written
        to a chunk and posts the 'directory' information of the gridfile to the
        GridFS. Returns True if successful; otherwise, False. }
    function finish: Boolean;
      { Write data to this IGridfileWriter. p is the address of the data and length
        is its size. Multiple calls to write() may be made to append successive
        data. }
    procedure Write(p: Pointer; Length: Int64);
    function truncate(newSize : int64) : Int64;
    function expand(bytesToExpand : Int64) : Int64;
    function setSize(newSize : Int64) : Int64;
  end;

implementation

uses
  SysUtils;

// START resource string wizard section
const
  SFiles_id = 'files_id';
  SChunks = '.chunks';
  SFs       = 'fs';
  SFilename = 'filename';
  // END resource string wizard section

// START resource string wizard section
resourcestring
  SGridFSHandleIsNil = 'GridFS Handle is nil';
  SGridFileHandleIsNil = 'GridFile Handle is nil';
  SInternalErrorOIDDescriptorOfFile = 'Internal error. OID descriptor of file is nil';
  SUnableToCreateGridFS = 'Unable to create GridFS';
  // END resource string wizard section

type
  {  Objects of class TGridfile are used to access gridfiles and read from them. }
  TGridfile = class(TMongoInterfacedObject, IGridFile)
  private
    procedure CheckHandle;
  protected
    { Pointer to externally managed data representing the gridfile }
    FHandle: Pointer;
        { Hold a reference to the TGridFS object used in construction of this
          TGridfile.  Prevents release until this TGridfile is destroyed. }
    gfs: TGridFS;
    { Create a TGridfile object.  Internal use only by TGridFS.find(). }
    constructor Create(gridfs: TGridFS);
    procedure DestroyGridFile;
  public
    function getStoredChunkCount: Int64;
    { Get the filename (remoteName) of this gridfile. }
    function getFilename: UTF8String;
    { Get the size of the chunks into which the file is divided. }
    function getChunkSize: Integer;
    { Get the length of this gridfile. }
    function getLength: Int64;
    { Get the content type of this gridfile. }
    function getContentType: UTF8String;
    { Get the upload date of this gridfile. }
    function getUploadDate: TDateTime;
    { Get the MD5 hash of this gridfile.  This is a 16-digit hex string. }
    function getMD5: UTF8String;
      { Get any metadata associated with this gridfile as a TBson document.
        Returns nil if there is none. }
    function getMetadata: IBson;
    { Get the number of chunks into which the file is divided. }
    function getChunkCount: Integer;
    { Get the descriptor of this gridfile as a TBson document. }
    function getDescriptor: IBson;
      { Get the Ith chunk of this gridfile.  The content of the chunk is
        in the 'data' field of the returned TBson document.  Returns nil
        if i is not in the range 0 to getChunkCount() - 1. }
    function getChunk(i: Integer): IBson;
      { Get a cursor for stepping through a range of chunks of this gridfile.
        i is the index of the first chunk to be returned.  count is the number
        of chunks to return.  Returns nil if there are no chunks in the
        specified range. }
    function getChunks(i: Integer; Count: Integer): IMongoCursor;
      { read data from this gridfile.  The gridfile maintains a current position
        so that successive reads will return consecutive data. The data is
        read to the address indicated by p and length bytes are read.  The size
        of the data read is returned and can be less than length if there was
        not enough data remaining to be read. }
    function read(p: Pointer; Length: Int64): Int64;
      { seek to a specified offset within the gridfile.  read() will then
        return data starting at that location.  Returns the position that
        was set.  This can be at the end of the gridfile if offset is greater
        the length of this gridfile. }
    function seek(offset: Int64): Int64;
    function Handle: Pointer;
    function getID: IBsonOID;
    { Destroy this TGridfile object.  Releases external resources. }
    destructor Destroy; override;
  end;

type
  { Objects of class TGridfileWriter are used to write buffered data to the GridFS. }
  TGridfileWriter = class(TGridFile, IGridfileWriter)
  private
    FInited: Boolean;
  public
      { Create a TGridfile writer on the given TGridFS that will write data to
        the given remoteName. }
    constructor Create(gridfs: TGridFS; remoteName: UTF8String; AInit: Boolean;
        AMeta: Pointer; Flags: Integer); overload;
      { Create a TGridfile writer on the given TGridFS that will write data to
        the given remoteName. contentType is the MIME-type content type of the gridfile
        to be written. }
    constructor Create(gridfs: TGridFS; const remoteName, contentType: UTF8String;
        AInit: Boolean; AMeta: Pointer; Flags: Integer); overload;
      { write data to this TGridfileWriter. p is the address of the data and length
        is its size. Multiple calls to write() may be made to append successive
        data. }
    procedure write(p: Pointer; Length: Int64);
      { Finish with this TGridfileWriter.  Flushes any data remaining to be written
        to a chunk and posts the 'directory' information of the gridfile to the
        GridFS. Returns True if successful; otherwise, False. }
    function truncate(newSize : int64): Int64;
    function expand(bytesToExpand : Int64): Int64;
    { setSize supercedes truncate in the sense it can change the file size up or down. If making
      file size larger, file will be zero filled }
    function setSize(newSize : Int64): Int64;
    function finish: Boolean;
      { Destroy this TGridfileWriter.  Calls finish() if necessary and releases
        external resources. }
    destructor Destroy; override;
  end;

{ TGridFS }

constructor TGridFS.Create(mongo: TMongo; const db, prefix: UTF8String);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  FPrefix := prefix;
  fdb := db;
  conn := mongo;
  Handle := gridfs_create;
  if gridfs_init(mongo.Handle, PAnsiChar(fdb),
    PAnsiChar(prefix), Handle) <> 0 then
  begin
    gridfs_dispose(Handle);
    raise Exception.Create(SUnableToCreateGridFS);
  end;
  AutoCheckLastError := True;
end;

constructor TGridFS.Create(mongo: TMongo; const db: UTF8String);
begin
  inherited Create;
  Create(mongo, db, SFs);
end;

destructor TGridFS.Destroy;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if Handle <> nil then
    begin
      gridfs_destroy(Handle);
      gridfs_dispose(Handle);
      Handle := nil;
    end;
  inherited;
end;

procedure TGridFS.CheckHandle;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if Handle = nil then
    raise EMongo.Create(SGridFSHandleIsNil);
end;

function TGridFS.storeFile(const FileName, remoteName, contentType: UTF8String;
    Flags: Integer = GRIDFILE_DEFAULT): Boolean;
var
  RetVal : Integer;
begin
  CheckHandle;
  conn.autoCmdResetLastError(fdb, False);
  RetVal := gridfs_store_file(Handle, PAnsiChar(FileName), PAnsiChar(remoteName), PAnsiChar(contentType), Flags);
  Result := RetVal = 0;
  conn.autoCheckCmdLastError(fdb, False);
end;

function TGridFS.storeFile(const FileName, remoteName: UTF8String; Flags:
    Integer = GRIDFILE_DEFAULT): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := storeFile(FileName, remoteName, '', Flags);
end;

function TGridFS.storeFile(const FileName: UTF8String; Flags: Integer =
    GRIDFILE_DEFAULT): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := storeFile(FileName, FileName, '', Flags);
end;

procedure TGridFS.removeFile(const remoteName: UTF8String);
begin
  CheckHandle;
  gridfs_remove_filename(Handle, PAnsiChar(remoteName));
end;

procedure TGridFS.setAutoCheckLastError(value: Boolean);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  conn.AutoCheckLastError := Value;
end;

function TGridFS.store(p: Pointer; Length: Int64; const remoteName,
    contentType: UTF8String; Flags: Integer = GRIDFILE_DEFAULT): Boolean;
begin
  CheckHandle;
  Result := (gridfs_store_buffer(Handle, p, Length, PAnsiChar(remoteName), PAnsiChar(contentType), Flags) = 0);
end;

function TGridFS.store(p: Pointer; Length: Int64; const remoteName: UTF8String;
    Flags: Integer = GRIDFILE_DEFAULT): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := store(p, Length, remoteName, '', Flags);
end;

function TGridFS.writerCreate(const remoteName, contentType: UTF8String; Flags:
    Integer = GRIDFILE_DEFAULT): IGridfileWriter;
begin
  CheckHandle;
  Result := TGridfileWriter.Create(Self, remoteName, contentType, True, bsonEmpty.Handle, Flags);
end;

function TGridFS.writerCreate(const remoteName: UTF8String; Flags: Integer =
    GRIDFILE_DEFAULT): IGridfileWriter;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := writerCreate(remoteName, '', Flags);
end;

function TGridFS.createGridFile: IGridFile;
begin
  CheckHandle;
  Result := TGridFile.Create(Self);
end;

function TGridFS.find(query: IBson; AWriteMode: Boolean): IGridfile;
var
  gf: IGridfile;
  AHandle : Pointer;
  meta : Pointer;
begin
  CheckHandle;
  gf := nil;
  if not AWriteMode then
    begin
      gf := TGridfile.Create(Self);
      AHandle := gf.Handle;
    end
    else AHandle := gridfile_create;
  try
    if gridfs_find_query(Handle, query.Handle, AHandle) = 0 then
      begin
        if AWriteMode then
          begin
            meta := bson_create;
            try
              gridfile_get_descriptor( AHandle, meta );
              gf := TGridfileWriter.Create(Self, gridfile_get_filename(AHandle), True, Meta, GRIDFILE_DEFAULT);
              gridfile_destroy(AHandle);
            finally
              bson_dispose(meta); // Dont' call Destroy for this object, data is owned by gridfile
            end;
          end;
        Result := gf;
      end
      else Result := nil;
  finally
    if AWriteMode then
      gridfile_dispose(AHandle);
  end;
end;

function TGridFS.getAutoCheckLastError: Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := conn.AutoCheckLastError;
end;

function TGridFS.find(const remoteName: UTF8String; AWriteMode: Boolean):
    IGridfile;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if CaseInsensitiveFileNames then
    Result := find(BSON([SFilename, UpperCase(remoteName)]), AWriteMode)
  else Result := find(BSON([SFilename, remoteName]), AWriteMode);
end;

function TGridFS.GetCaseInsensitiveFileNames: Boolean;
begin
  CheckHandle;
  Result := gridfs_get_caseInsensitive(Handle);
end;

procedure TGridFS.SetCaseInsensitiveFileNames(const Value: Boolean);
begin
  CheckHandle;
  gridfs_set_caseInsensitive(Handle, Value);
end;

{ TGridfileWriter }

constructor TGridfileWriter.Create(gridfs: TGridFS; const remoteName,
    contentType: UTF8String; AInit: Boolean; AMeta: Pointer; Flags: Integer);
begin
  inherited Create(gridfs);
  if AInit then
    begin
      gridfile_init(gfs.Handle, AMeta, Handle);
      FInited := True;
    end;
  gridfile_writer_init(Handle, gridfs.Handle, PAnsiChar(remoteName), PAnsiChar(contentType), Flags);
end;

constructor TGridfileWriter.Create(gridfs: TGridFS; remoteName: UTF8String;
    AInit: Boolean; AMeta: Pointer; Flags: Integer);
begin
  Create(gridfs, remoteName, '', AInit, AMeta, Flags);
end;

procedure TGridfileWriter.write(p: Pointer; Length: Int64);
begin
  CheckHandle;
  gridfile_write_buffer(Handle, p, Length);
end;

function TGridfileWriter.finish: Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if Handle = nil then
    Result := true
  else
  begin
    Result := (gridfile_writer_done(Handle) = 0);
    if FInited then
      DestroyGridFile
    else
    begin
      gridfile_dispose(Handle);
      FHandle := nil;
    end;
  end;
end;

destructor TGridfileWriter.Destroy;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  finish;
  inherited;
end;

function TGridfileWriter.expand(bytesToExpand : Int64): Int64;
begin
  CheckHandle;
  Result := gridfile_expand(Handle, bytesToExpand);
end;

function TGridfileWriter.setSize(newSize : Int64): Int64;
begin
  CheckHandle;
  Result := gridfile_set_size(Handle, newSize);
end;

function TGridfileWriter.truncate(newSize : int64): Int64;
begin
  CheckHandle;
  Result := gridfile_truncate(Handle, newSize);
end;

{ TGridfile }

constructor TGridfile.Create(gridfs: TGridFS);
begin
  inherited Create;
  gfs := gridfs;
  FHandle := gridfile_create;
end;

destructor TGridfile.Destroy;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  DestroyGridFile;
  inherited;
end;

procedure TGridfile.CheckHandle;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if FHandle = nil then
    raise EMongo.Create(SGridFileHandleIsNil);
end;

procedure TGridfile.DestroyGridFile;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if FHandle <> nil then
  begin
    gridfile_destroy(FHandle);
    gridfile_dispose(FHandle);
    FHandle := nil;
  end;
end;

function TGridfile.getFilename: UTF8String;
begin
  CheckHandle;
  Result := UTF8String(gridfile_get_filename(FHandle));
end;

function TGridfile.getChunkSize: Integer;
begin
  CheckHandle;
  Result := gridfile_get_chunksize(FHandle);
end;

function TGridfile.getLength: Int64;
begin
  CheckHandle;
  Result := gridfile_get_contentlength(FHandle);
end;

function TGridfile.getContentType: UTF8String;
begin
  CheckHandle;
  Result := UTF8String(gridfile_get_contenttype(FHandle));
end;

function TGridfile.getUploadDate: TDateTime;
begin
  CheckHandle;
  Result := Int64toDouble(gridfile_get_uploaddate(FHandle)) / (1000 * 24 * 60 * 60) + 25569;
end;

function TGridfile.getMD5: UTF8String;
begin
  CheckHandle;
  Result := UTF8String(gridfile_get_md5(FHandle));
end;

function TGridfile.getMetadata: IBson;
var
  b: Pointer;
begin
  CheckHandle;
  b := bson_create;
  try
    gridfile_get_metadata(FHandle, b);
    if bson_size(b) <= 5 then
      Result := nil
    else
      Result := NewBsonCopy(b);
  finally
    bson_dispose(b); // Dont' call Destroy for this object, data is owned by gridfile
  end;
end;

function TGridfile.getChunkCount: Integer;
begin
  CheckHandle;
  Result := gridfile_get_numchunks(FHandle);
end;

function TGridfile.getDescriptor: IBson;
var
  b : Pointer;
begin
  CheckHandle;
  b := bson_create;
  try
    gridfile_get_descriptor(FHandle, b);
    Result := NewBsonCopy(b);
  finally
    bson_dispose(b); // Dont' call Destroy for this object, data is owned by gridfile
  end;
end;

function TGridfile.getChunk(i: Integer): IBson;
var
  b: IBson;
  h : Pointer;
begin
  CheckHandle;
  h := bson_create;
  try
    b := NewBson(h);
  except
    bson_dispose_and_destroy(h);
    raise;
  end;
  gridfile_get_chunk(FHandle, i, b.Handle);
  if b.size <= 5 then
    Result := nil
  else
    Result := b;
end;

function TGridfile.getChunks(i: Integer; Count: Integer): IMongoCursor;
var
  Cursor: IMongoCursor;
begin
  CheckHandle;
  Cursor := NewMongoCursor;
  Cursor.Handle := gridfile_get_chunks(FHandle, i, Count);
  if Cursor.Handle = nil then
    Result := nil
  else
  begin
    Cursor.FindCalled;
    Result := Cursor;
  end;
end;

function TGridfile.getID: IBsonOID;
var
  poid : pointer;
begin
  CheckHandle;
  poid := gridfile_get_id(FHandle);
  if poid = nil then
    raise EMongo.Create(SInternalErrorOIDDescriptorOfFile);
  Result := NewBsonOID;
  Result.setValue(TBsonOIDValue(poid^));
end;

function TGridfile.getStoredChunkCount: Int64;
var
  buf : IBsonBuffer;
  q : IBson;
  id : Pointer;
  oid : IBsonOID;
begin
  CheckHandle;
  id := gridfile_get_id(FHandle);
  if id = nil then
    begin
      Result := 0;
      exit;
    end;
  oid := NewBsonOID;
  oid.setValue(TBsonOIDValue(id^));
  buf := NewBsonBuffer;
  buf.Append(SFiles_id, oid);
  q := buf.finish;
  Result := Trunc(gfs.conn.count(gfs.fdb + '.' + gfs.FPrefix + SChunks, q));
end;

function TGridfile.Handle: Pointer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FHandle;
end;

function TGridfile.read(p: Pointer; Length: Int64): Int64;
begin
  CheckHandle;
  Result := gridfile_read(FHandle, Length, p);
end;

function TGridfile.seek(offset: Int64): Int64;
begin
  CheckHandle;
  Result := gridfile_seek(FHandle, offset);
end;


end.

