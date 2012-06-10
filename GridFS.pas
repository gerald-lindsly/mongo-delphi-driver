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
  MongoDB, MongoBson;

type
  TGridfile       = class;
  TGridfileWriter = class;

  TGridFS = class(TObject)
  private
    { Pointer to externally managed data representing the GridFS }
    Handle: Pointer;
        { Holds a reference to the TMongo object used in construction.
          Prevents release until the TGridFS is destroyed. }
    conn: TMongo;
  public
      { Create a TGridFS object for accessing the GridFS on the MongoDB server.
        Parameter mongo is an already established connection object to the
        server; db is the name of the database in which to construct the GridFS.
        The prefix defaults to 'fs'.}
    constructor Create(mongo: TMongo; const db: AnsiString); overload;
      { Create a TGridFS object for accessing the GridFS on the MongoDB server.
        Parameter mongo is an already established connection object to the
        server; db is the name of the database in which to construct the GridFS.
        prefix is appended to the database name for the collections that represent
        the GridFS: 'db.prefix.files' & 'db.prefix.chunks'. }
    constructor Create(mongo: TMongo; const db, prefix: AnsiString); overload;
      { Store a file on the GridFS.  filename is the path to the file.
        Returns True if successful; otherwise, False. }
    function storeFile(const FileName: AnsiString): Boolean; overload;
      { Store a file on the GridFS.  filename is the path to the file.
        remoteName is the name that the file will be known as within the GridFS.
        Returns True if successful; otherwise, False. }
    function storeFile(const FileName, remoteName: AnsiString): Boolean; overload;
      { Store a file on the GridFS.  filename is the path to the file.
        remoteName is the name that the file will be known as within the GridFS.
        contentType is the MIME-type content type of the file.
        Returns True if successful; otherwise, False. }
    function storeFile(const FileName, remoteName, contentType: AnsiString): Boolean; overload;
    { Remove a file from the GridFS. }
    procedure removeFile(const remoteName: AnsiString);
      { Store data as a GridFS file.  Pointer is the address of the data and length
        is its size. remoteName is the name that the file will be known as within the GridFS.
        Returns True if successful; otherwise, False. }
    function store(p: Pointer; Length: Int64; const remoteName: AnsiString): Boolean; overload;
      { Store data as a GridFS file.  Pointer is the address of the data and length
        is its size. remoteName is the name that the file will be known as within the GridFS.
        contentType is the MIME-type content type of the file.
        Returns True if successful; otherwise, False. }
    function store(p: Pointer; Length: Int64; const remoteName, contentType: AnsiString): Boolean; overload;
      { Create a TGridfileWriter object for writing buffered data to a GridFS file.
        remoteName is the name that the file will be known as within the GridFS. }
    function writerCreate(const remoteName: AnsiString): TGridfileWriter; overload;
      { Create a TGridfileWriter object for writing buffered data to a GridFS file.
        remoteName is the name that the file will be known as within the GridFS.
        contentType is the MIME-type content type of the file. }
    function writerCreate(const remoteName, contentType: AnsiString): TGridfileWriter; overload;
      { Locate a GridFS file by its remoteName and return a TGridfile object for
        accessing it. }
    function find(const remoteName: AnsiString): TGridfile; overload;
      { Locate a GridFS file by an TBson query document on the GridFS file descriptors.
        Returns a TGridfile object for accessing it. }
    function find(query: IBson): TGridfile; overload;
    { Destroy this GridFS object.  Releases external resources. }
    destructor Destroy; override;
  end;

  {  Objects of class TGridfile are used to access gridfiles and read from them. }
  TGridfile = class(TObject)
  private
    { Pointer to externally managed data representing the gridfile }
    Handle: Pointer;
        { Hold a reference to the TGridFS object used in construction of this
          TGridfile.  Prevents release until this TGridfile is destroyed. }
    gfs: TGridFS;
    { Create a TGridfile object.  Internal use only by TGridFS.find(). }
    constructor Create(gridfs: TGridFS);
  public
    { Get the filename (remoteName) of this gridfile. }
    function getFilename: AnsiString;
    { Get the size of the chunks into which the file is divided. }
    function getChunkSize: Integer;
    { Get the length of this gridfile. }
    function getLength: Int64;
    { Get the content type of this gridfile. }
    function getContentType: AnsiString;
    { Get the upload date of this gridfile. }
    function getUploadDate: TDateTime;
    { Get the MD5 hash of this gridfile.  This is a 16-digit hex string. }
    function getMD5: AnsiString;
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
      { Read data from this gridfile.  The gridfile maintains a current position
        so that successive reads will return consecutive data. The data is
        read to the address indicated by p and length bytes are read.  The size
        of the data read is returned and can be less than length if there was
        not enough data remaining to be read. }
    function Read(p: Pointer; Length: Int64): Int64;
      { Seek to a specified offset within the gridfile.  read() will then
        return data starting at that location.  Returns the position that
        was set.  This can be at the end of the gridfile if offset is greater
        the length of this gridfile. }
    function Seek(offset: Int64): Int64;
    { Destroy this TGridfile object.  Releases external resources. }
    destructor Destroy; override;
  end;

  { Objects of class TGridfileWriter are used to write buffered data to the GridFS. }
  TGridfileWriter = class(TObject)
  private
    { Holds a pointer to externally managed data representing the TGridfileWriter. }
    Handle: Pointer;
        { Holds a reference to the TGridFS object used in construction.
          Prevents release of the TGridFS until this TGridfileWriter is destroyed. }
    gfs: TGridFS;
  public
      { Create a TGridfile writer on the given TGridFS that will write data to
        the given remoteName. }
    constructor Create(gridfs: TGridFS; remoteName: AnsiString); overload;
      { Create a TGridfile writer on the given TGridFS that will write data to
        the given remoteName. contentType is the MIME-type content type of the gridfile
        to be written. }
    constructor Create(gridfs: TGridFS; const remoteName, contentType: AnsiString);
        overload;
      { Write data to this TGridfileWriter. p is the address of the data and length
        is its size. Multiple calls to write() may be made to append successive
        data. }
    procedure Write(p: Pointer; Length: Int64);
      { Finish with this TGridfileWriter.  Flushes any data remaining to be written
        to a chunk and posts the 'directory' information of the gridfile to the
        GridFS. Returns True if successful; otherwise, False. }
    function finish: Boolean;
      { Destroy this TGridfileWriter.  Calls finish() if necessary and releases
        external resources. }
    destructor Destroy; override;
  end;

implementation
  
uses
  SysUtils;

// START resource string wizard section
const
  SFs       = 'fs';
  SFilename = 'filename';
  // END resource string wizard section  

  // START resource string wizard section
resourcestring
  SUnableToCreateGridFS = 'Unable to create GridFS';
  // END resource string wizard section   

function gridfs_create: Pointer; cdecl; external 'mongoc.dll';
procedure gridfs_dispose(g: Pointer); cdecl; external 'mongoc.dll';  
function gridfs_init(c: Pointer; db: PAnsiChar; prefix: PAnsiChar; g: Pointer): Integer; cdecl; external 'mongoc.dll';  
procedure gridfs_destroy(g: Pointer); cdecl; external 'mongoc.dll';  
function gridfs_store_file(g: Pointer; FileName: PAnsiChar; remoteName: PAnsiChar; contentType: PAnsiChar): Integer; cdecl; external 'mongoc.dll';
procedure gridfs_remove_filename(g: Pointer; remoteName: PAnsiChar); cdecl; external 'mongoc.dll';
function gridfs_store_buffer(g: Pointer; p: Pointer; size: Int64; remoteName: PAnsiChar; contentType: PAnsiChar): Integer; cdecl; external 'mongoc.dll';
function gridfile_create: Pointer; cdecl; external 'mongoc.dll';
procedure gridfile_dispose(gf: Pointer); cdecl; external 'mongoc.dll';
procedure gridfile_writer_init(gf: Pointer; gfs: Pointer; remoteName: PAnsiChar; contentType: PAnsiChar); cdecl; external 'mongoc.dll';
procedure gridfile_write_buffer(gf: Pointer; Data: Pointer; Length: Int64); cdecl; external 'mongoc.dll';
function gridfile_writer_done(gf: Pointer): Integer; cdecl; external 'mongoc.dll';
function gridfs_find_query(g: Pointer; query: Pointer; gf: Pointer): Integer; cdecl; external 'mongoc.dll';
procedure gridfile_destroy(gf: Pointer); cdecl; external 'mongoc.dll';  
function gridfile_get_filename(gf: Pointer): PAnsiChar; cdecl; external 'mongoc.dll';  
function gridfile_get_chunksize(gf: Pointer): Integer; cdecl; external 'mongoc.dll';  
function gridfile_get_contentlength(gf: Pointer): Int64; cdecl; external 'mongoc.dll';  
function gridfile_get_contenttype(gf: Pointer): PAnsiChar; cdecl; external 'mongoc.dll';  
function gridfile_get_uploaddate(gf: Pointer): Int64; cdecl; external 'mongoc.dll';  
function gridfile_get_md5(gf: Pointer): PAnsiChar; cdecl; external 'mongoc.dll';  
procedure gridfile_get_metadata(gf: Pointer; b: Pointer); cdecl; external 'mongoc.dll';
function bson_create: Pointer; cdecl; external 'mongoc.dll';
procedure bson_dispose(b: Pointer); cdecl; external 'mongoc.dll';  
function bson_size(b: Pointer): Integer; cdecl; external 'mongoc.dll';  
procedure bson_copy(dest: Pointer; src: Pointer); cdecl; external 'mongoc.dll';  
function gridfile_get_numchunks(gf: Pointer): Integer; cdecl; external 'mongoc.dll';  
procedure gridfile_get_descriptor(gf: Pointer; b: Pointer); cdecl; external 'mongoc.dll';  
procedure gridfile_get_chunk(gf: Pointer; i: Integer; b: Pointer); cdecl; external 'mongoc.dll';  
function gridfile_get_chunks(gf: Pointer; i: Integer; Count: Integer): Pointer; cdecl; external 'mongoc.dll';
function gridfile_read(gf: Pointer; size: Int64; buf: Pointer): Int64; cdecl; external 'mongoc.dll';
function gridfile_seek(gf: Pointer; offset: Int64): Int64; cdecl; external 'mongoc.dll';
  
constructor TGridFS.Create(mongo: TMongo; const db, prefix: AnsiString);
begin
  inherited Create;
  conn := mongo;
  Handle := gridfs_create;
  if gridfs_init(mongo.Handle, PAnsiChar(db),
    PAnsiChar(prefix), Handle) <> 0 then
  begin
    gridfs_dispose(Handle);
    raise Exception.Create(SUnableToCreateGridFS);
  end;
end;

constructor TGridFS.Create(mongo: TMongo; const db: AnsiString);
begin
  Create(mongo, db, SFs);
end;

destructor TGridFS.Destroy;
begin
  gridfs_destroy(Handle);
  gridfs_dispose(Handle);
end;

function TGridFS.storeFile(const FileName, remoteName, contentType: AnsiString): Boolean;
begin
  Result := (gridfs_store_file(Handle, PAnsiChar(FileName), PAnsiChar(remoteName), PAnsiChar(contentType)) = 0);
end;

function TGridFS.storeFile(const FileName, remoteName: AnsiString): Boolean;
begin
  Result := storeFile(FileName, remoteName, '');
end;

function TGridFS.storeFile(const FileName: AnsiString): Boolean;
begin
  Result := storeFile(FileName, FileName, '');
end;

procedure TGridFS.removeFile(const remoteName: AnsiString);
begin
  gridfs_remove_filename(Handle, PAnsiChar(remoteName));
end;

function TGridFS.store(p: Pointer; Length: Int64; const remoteName, contentType: AnsiString): Boolean;
begin
  Result := (gridfs_store_buffer(Handle, p, Length, PAnsiChar(remoteName), PAnsiChar(contentType)) = 0);
end;

function TGridFS.store(p: Pointer; Length: Int64; const remoteName: AnsiString): Boolean;
begin
  Result := store(p, Length, remoteName, '');
end;

function TGridFS.writerCreate(const remoteName, contentType: AnsiString): TGridfileWriter;
begin
  Result := TGridfileWriter.Create(Self, remoteName, contentType);
end;

function TGridFS.writerCreate(const remoteName: AnsiString): TGridfileWriter;
begin
  Result := writerCreate(remoteName, '');
end;

constructor TGridfileWriter.Create(gridfs: TGridFS; const remoteName,
    contentType: AnsiString);
begin
  inherited Create;
  gfs := gridfs;
  Handle := gridfile_create;
  gridfile_writer_init(Handle, gridfs.Handle, PAnsiChar(remoteName), PAnsiChar(contentType));
end;

constructor TGridfileWriter.Create(gridfs: TGridFS; remoteName: AnsiString);
begin
  Create(gridfs, remoteName, '');
end;

procedure TGridfileWriter.Write(p: Pointer; Length: Int64);
begin
  gridfile_write_buffer(Handle, p, Length);
end;

function TGridfileWriter.finish: Boolean;
begin
  if Handle = nil then
    Result := true
  else 
  begin
    Result := (gridfile_writer_done(Handle) = 0);
    gridfile_dispose(Handle);
    Handle := nil;
  end;
end;

destructor TGridfileWriter.Destroy;
begin
  finish;
end;

function TGridFS.find(query: IBson): TGridfile;
var
  gf: TGridfile;
begin
  gf := TGridfile.Create(Self);
  if gridfs_find_query(Handle, query.Handle, gf.Handle) = 0 then
    Result := gf
  else 
  begin
    gridfile_dispose(gf.Handle);
    gf.Handle := nil;
    Result    := nil;
  end;
end;

function TGridFS.find(const remoteName: AnsiString): TGridfile;
begin
  Result := find(BSON([SFilename, remoteName]));
end;

constructor TGridfile.Create(gridfs: TGridFS);
begin
  inherited Create;
  gfs := gridfs;
  Handle := gridfile_create;
end;

destructor TGridfile.Destroy;
begin
  if Handle <> nil then
  begin
    gridfile_destroy(Handle);
    gridfile_dispose(Handle);
    Handle := nil;
  end;
  inherited;
end;

function TGridfile.getFilename: AnsiString;
begin
  Result := AnsiString(gridfile_get_filename(Handle));
end;

function TGridfile.getChunkSize: Integer;
begin
  Result := gridfile_get_chunksize(Handle);
end;

function TGridfile.getLength: Int64;
begin
  Result := gridfile_get_contentlength(Handle);
end;

function TGridfile.getContentType: AnsiString;
begin
  Result := AnsiString(gridfile_get_contenttype(Handle));
end;

function TGridfile.getUploadDate: TDateTime;
begin
  Result := Int64toDouble(gridfile_get_uploaddate(Handle)) / (1000 * 24 * 60 * 60) + 25569;
end;

function TGridfile.getMD5: AnsiString;
begin
  Result := AnsiString(gridfile_get_md5(Handle));
end;

function TGridfile.getMetadata: IBson;
var
  b: Pointer;
  res: IBson;
  h : Pointer;
begin
  b := bson_create;
  try
    gridfile_get_metadata(Handle, b);
    if bson_size(b) <= 5 then
      Result := nil
    else
    begin
      h := bson_create;
      try
        res := NewBson(h);
      except
        bson_dispose(h);
        raise;
      end;
      bson_copy(res.Handle, b);
      Result := res;
    end;
  finally
    bson_dispose(b);
  end;
end;

function TGridfile.getChunkCount: Integer;
begin
  Result := gridfile_get_numchunks(Handle);
end;

function TGridfile.getDescriptor: IBson;
var
  b : Pointer;
  res: IBson;
  h : Pointer;
begin
  b := bson_create;
  try
    gridfile_get_descriptor(Handle, b);
    h := bson_create;
    try
      res := NewBson(h);
    except
      bson_dispose(h);
      raise;
    end;
    bson_copy(res.Handle, b);
  finally
    bson_dispose(b);
  end;
  Result := res;
end;

function TGridfile.getChunk(i: Integer): IBson;
var
  b: IBson;
  h : Pointer;
begin
  h := bson_create;
  try
    b := NewBson(h);
  except
    bson_dispose(h);
    raise;
  end;
  gridfile_get_chunk(Handle, i, b.Handle);
  if b.size <= 5 then
    Result := nil
  else
    Result := b;
end;

function TGridfile.getChunks(i: Integer; Count: Integer): IMongoCursor;
var
  Cursor: IMongoCursor;
begin
  Cursor := NewMongoCursor;
  Cursor.Handle := gridfile_get_chunks(Handle, i, Count);
  if Cursor.Handle = nil then
    Result := nil
  else
    Result := Cursor;
end;

function TGridfile.Read(p: Pointer; Length: Int64): Int64;
begin
  Result := gridfile_read(Handle, Length, p);
end;

function TGridfile.Seek(offset: Int64): Int64;
begin
  Result := gridfile_seek(Handle, offset);
end;


end.
