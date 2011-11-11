unit GridFS;

interface
  Uses
    MongoDB, MongoBson;

  type
    TGridfile = class;
    TGridfileWriter = class;

    TGridFS = class(TObject)
      var
        handle : Pointer;
        conn   : TMongo;
      constructor Create(mongo : TMongo; db : string); overload;
      constructor Create(mongo : TMongo; db : string; prefix : string); overload;
      function storeFile(filename : string) : Boolean; overload;
      function storeFile(filename : string; remoteName : string) : Boolean; overload;
      function storeFile(filename : string; remoteName : string; contentType : string) : Boolean; overload;
      procedure removeFile(remoteName : string);
      function store(p : Pointer; length : Int64; remoteName : string) : Boolean; overload;
      function store(p : Pointer; length : Int64; remoteName : string; contentType : string) : Boolean; overload;
      function writerCreate(remoteName : string) : TGridfileWriter; overload;
      function writerCreate(remoteName : string; contentType : string) : TGridfileWriter; overload;
      function find(remoteName : string) : TGridfile; overload;
      function find(query : TBson) : TGridfile; overload;
      destructor Destroy(); override;
    end;

    TGridfile = class(TObject)
      var
        handle : Pointer;
        gfs : TGridFS;
    private
      constructor Create(gridfs : TGridFS);
    public
      function getFilename() : string;
      function getChunkSize() : Integer;
      function getLength() : Int64;
      function getContentType() : string;
      function getUploadDate() : TDateTime;
      function getMD5() : string;
      function getMetadata() : TBson;
      function getChunkCount() : Integer;
      function getDescriptor() : TBson;
      function getChunk(i : Integer) : TBson;
      function getChunks(i : Integer; count : Integer) : TMongoCursor;
      function read(p : Pointer; length : Int64) : Int64;
      function seek(offset : Int64) : Int64;
      destructor Destroy(); override;
    end;

    TGridfileWriter = class(TObject)
      var
        handle : Pointer;
        gfs    : TGridFS;
      constructor Create(gridfs : TGridFS; remoteName : string); overload;
      constructor Create(gridfs : TGridFS; remoteName : string; contentType : string); overload;
      procedure write(p : Pointer; length : Int64);
      function finish() : Boolean;
      destructor Destroy(); override;
    end;

implementation
  uses
    SysUtils;

  function gridfs_create() : Pointer; cdecl; external 'mongoc.dll';
  procedure gridfs_dispose(g : Pointer); cdecl; external 'mongoc.dll';
  function gridfs_init(c : Pointer; db : PAnsiChar; prefix : PAnsiChar; g : Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  procedure gridfs_destroy(g : Pointer); cdecl; external 'mongoc.dll';
  function gridfs_store_file(g : Pointer; filename : PAnsiChar; remoteName : PAnsiChar; contentType : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  procedure gridfs_remove_filename(g : Pointer; remoteName : PAnsiChar); cdecl; external 'mongoc.dll';
  function gridfs_store_buffer(g : Pointer; p : Pointer; size : Int64; remoteName : PAnsiChar; contentType : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  function gridfile_create() : Pointer; cdecl; external 'mongoc.dll';
  procedure gridfile_dispose(gf : Pointer); cdecl; external 'mongoc.dll';
  procedure gridfile_writer_init(gf : Pointer; gfs : Pointer; remoteName : PAnsiChar; contentType : PAnsiChar);
    cdecl; external 'mongoc.dll';
  procedure gridfile_write_buffer(gf : Pointer; data : Pointer; length : Int64);
    cdecl; external 'mongoc.dll';
  function gridfile_writer_done(gf : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function gridfs_find_query(g : Pointer; query : Pointer; gf : Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  procedure gridfile_destroy(gf : Pointer); cdecl; external 'mongoc.dll';
  function gridfile_get_filename(gf : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';
  function gridfile_get_chunksize(gf : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function gridfile_get_contentlength(gf : Pointer) : Int64; cdecl; external 'mongoc.dll';
  function gridfile_get_contenttype(gf : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';
  function gridfile_get_uploaddate(gf : Pointer) : Int64; cdecl; external 'mongoc.dll';
  function gridfile_get_md5(gf : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';
  procedure gridfile_get_metadata(gf : Pointer; b : Pointer); cdecl; external 'mongoc.dll';
  function bson_create() : Pointer; cdecl; external 'mongoc.dll';
  procedure bson_dispose(b : Pointer); cdecl; external 'mongoc.dll';
  function bson_size(b : Pointer) : Integer; cdecl; external 'mongoc.dll';
  procedure bson_copy(dest : Pointer; src : Pointer); cdecl; external 'mongoc.dll';
  function gridfile_get_numchunks(gf : Pointer) : Integer; cdecl; external 'mongoc.dll';
  procedure gridfile_get_descriptor(gf : Pointer; b : Pointer); cdecl; external 'mongoc.dll';
  procedure gridfile_get_chunk(gf : Pointer; i : Integer; b : Pointer); cdecl; external 'mongoc.dll';
  function gridfile_get_chunks(gf : Pointer; i : Integer; count : Integer) : Pointer;
    cdecl; external 'mongoc.dll';
  function gridfile_read(gf : Pointer; size : Int64; buf : Pointer) : Int64;
    cdecl; external 'mongoc.dll';
  function gridfile_seek(gf : Pointer; offset : Int64) : Int64;
    cdecl; external 'mongoc.dll';

  
  constructor TGridFS.Create(mongo: TMongo; db: string; prefix : string);
  begin
    conn := mongo;
    handle := gridfs_create();
    if gridfs_init(mongo.handle, PAnsiChar(AnsiString(db)),
                                 PAnsiChar(AnsiString(prefix)), handle) <> 0 then begin
       gridfs_dispose(handle);
       Raise Exception.Create('Unable to create GridFS');
    end;
  end;

  constructor TGridFS.Create(mongo: TMongo; db: string);
  begin
    Create(mongo, db, 'fs');
  end;

  destructor TGridFS.Destroy();
  begin
    gridfs_destroy(handle);
    gridfs_dispose(handle);
  end;

  function TGridFS.storeFile(filename : string; remoteName : string; contentType : string) : Boolean;
  begin
    Result := (gridfs_store_file(handle, PAnsiChar(AnsiString(filename)),
                                         PAnsiChar(AnsiString(remoteName)),
                                         PAnsiChar(AnsiString(contentType))) = 0);
  end;

  function TGridFS.storeFile(filename : string; remoteName : string) : Boolean;
  begin
    Result := storeFile(filename, remoteName, '');
  end;

  function TGridFS.storeFile(filename : string) : Boolean;
  begin
    Result := storeFile(filename, filename, '');
  end;

  procedure TGridFS.removeFile(remoteName : string);
  begin
    gridfs_remove_filename(handle, PAnsiChar(AnsiString(remoteName)));
  end;

  function TGridFS.store(p : Pointer; length : Int64; remoteName : string; contentType : string) : Boolean;
  begin
    Result := (gridfs_store_buffer(handle, p, length, PAnsiChar(AnsiString(remoteName)),
                                                      PAnsiChar(AnsiString(contentType))) = 0);
  end;

  function TGridFS.store(p : Pointer; length : Int64; remoteName : string) : Boolean;
  begin
    Result := store(p, length, remoteName, '');
  end;

  function TGridFS.writerCreate(remoteName : string; contentType : string) : TGridfileWriter;
  begin
    Result := TGridfileWriter.Create(Self, remoteName, contentType);
  end;

  function TGridFS.writerCreate(remoteName : string) : TGridfileWriter;
  begin
    Result := writerCreate(remoteName, '');
  end;

  constructor TGridfileWriter.Create(gridfs : TGridFS; remoteName : string; contentType : string);
  begin
    gfs := gridfs;
    handle := gridfile_create();
    gridfile_writer_init(handle, gridfs.handle, PAnsiChar(AnsiString(remoteName)), PAnsiChar(AnsiString(contentType)));
  end;

  constructor TGridfileWriter.Create(gridfs : TGridFS; remoteName : string);
  begin
    Create(gridfs, remoteName, '');
  end;

  procedure TGridfileWriter.write(p: Pointer; length: Int64);
  begin
    gridfile_write_buffer(handle, p, length);
  end;

  function TGridfileWriter.finish() : Boolean;
  begin
    if handle = nil then
      Result := True
    else begin
      Result := (gridfile_writer_done(handle) = 0);
      gridfile_dispose(handle);
      handle := nil;
    end;
  end;

  destructor TGridfileWriter.Destroy();
  begin
    finish();
  end;

  function TGridFS.find(query : TBson) : TGridfile;
  var
    gf : TGridfile;
  begin
    gf := TGridfile.Create(Self);
    if gridfs_find_query(handle, query.handle, gf.handle) = 0 then
      Result := gf
    else begin
      gridfile_dispose(gf.handle);
      gf.handle := nil;
      Result := nil;
    end;
  end;

  function TGridFS.find(remoteName : string) : TGridfile;
  begin
    Result := find(BSON(['filename', remoteName]));
  end;

  constructor TGridfile.Create(gridfs : TGridFS);
  begin
    gfs := gridfs;
    handle := gridfile_create();
  end;

  destructor TGridfile.Destroy();
  begin
    if handle <> nil then begin
      gridfile_destroy(handle);
      gridfile_dispose(handle);
      handle := nil;
    end;
  end;

  function TGridfile.getFilename() : string;
  begin
    Result := string(gridfile_get_filename(handle));
  end;

  function TGridfile.getChunkSize() : Integer;
  begin
    Result := gridfile_get_chunksize(handle);
  end;

  function TGridfile.getLength() : Int64;
  begin
    Result := gridfile_get_contentlength(handle);
  end;

  function TGridfile.getContentType() : string;
  begin
    Result := string(gridfile_get_contenttype(handle));
  end;

  function TGridfile.getUploadDate() : TDateTime;
  begin
    Result := Int64ToDouble(gridfile_get_uploaddate(handle)) / (1000 * 24 * 60 * 60) + 25569;
  end;
  
  function TGridfile.getMD5() : string;
  begin
    Result := string(gridfile_get_md5(handle));
  end;

  function TGridfile.getMetadata() : TBson;
  var
    b : Pointer;
    res : TBson;
  begin
    b := bson_create();
    gridfile_get_metadata(handle, b);
    if bson_size(b) <= 5 then
      Result := nil
    else begin
      res := TBson.Create(bson_create());
      bson_copy(res.handle, b);
      Result := res;
    end;
    bson_dispose(b);
  end;

  function TGridfile.getChunkCount() : Integer;
  begin
    Result := gridfile_get_numchunks(handle);
  end;
  
  function TGridfile.getDescriptor() : TBson;
  var
    b : Pointer;
    res : TBson;
  begin
    b := bson_create();
    gridfile_get_descriptor(handle, b);
    res := TBson.Create(bson_create());
    bson_copy(res.handle, b);
    bson_dispose(b);
    Result := res;
  end;

  function TGridfile.getChunk(i : Integer) : TBson;
  var
    b : TBson;
  begin
    b := TBson.Create(bson_create());
    gridfile_get_chunk(handle, i, b.handle);
    if b.size() <= 5 then
      Result := nil
    else
      Result := b;
  end;

  function TGridfile.getChunks(i : Integer; count : Integer) : TMongoCursor;
  var
    cursor : TMongoCursor;
  begin
    cursor := TMongoCursor.Create();
    cursor.handle := gridfile_get_chunks(handle, i, count);
    if cursor.handle = nil then
      Result := nil
    else
      Result := cursor;
  end;

  function TGridfile.read(p : Pointer; length : Int64) : Int64;
  begin
    Result := gridfile_read(handle, length, p);
  end;

  function TGridfile.seek(offset : Int64) : Int64;
  begin
    Result := gridfile_seek(handle, offset);
  end;

    
end.
