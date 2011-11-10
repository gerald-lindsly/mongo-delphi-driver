unit MongoDB;

interface
  Uses
     MongoBson;

  type
    TMongoCursor = class;
    TStringArray = array of string;

    TMongo = class(TObject)
      var handle : Pointer;

      const
        updateUpsert    = 1;
        updateMulti     = 2;
        updateBasic     = 4;
        indexUnique     = 1;
        indexDropDups   = 4;
        indexBackground = 8;
        indexSparse     = 16;

      constructor Create(); overload;
      constructor Create(host : string); overload;
      function isConnected() : Boolean;
      function checkConnection() : Boolean;
      function isMaster() : Boolean;
      procedure disconnect();
      function reconnect() : Boolean;
      function getErr() : Integer;
      function setTimeout(millis : Integer) : Boolean;
      function getTimeout() : Integer;
      function getPrimary() : string;
      function getSocket() : Integer;
      function getDatabases() : TStringArray;
      function getDatabaseCollections(db : string) : TStringArray;
      function rename(from_ns : string; to_ns : string) : Boolean;
      function drop(ns : string) : Boolean;
      function dropDatabase(db : string) : Boolean;
      function insert(ns : string; b : TBson) : Boolean; overload;
      function insert(ns : string; bs : array of TBson) : Boolean; overload;
      function update(ns : string; criteria : TBson; objNew : TBson) : Boolean; overload;
      function update(ns : string; criteria : TBson; objNew : TBson; flags : Integer) : Boolean; overload;
      function remove(ns : string; criteria : TBson) : Boolean;
      function findOne(ns : string; query : TBson) : TBson; overload;
      function findOne(ns : string; query : TBson; fields : TBson) : TBson; overload;
      function find(ns : string; cursor : TMongoCursor) : Boolean;
      function count(ns : string) : Double; overload;
      function count(ns : string; query : TBson) : Double; overload;
      function indexCreate(ns : string; key : string) : TBson; overload;
      function indexCreate(ns : string; key : string; options : Integer) : TBson; overload;
      function indexCreate(ns : string; key : TBson) : TBson; overload;
      function indexCreate(ns : string; key : TBson; options : Integer) : TBson; overload;
      function addUser(name : string; password : string) : Boolean; overload;
      function addUser(name : string; password : string; db : string) : Boolean; overload;
      function authenticate(name : string; password : string) : Boolean; overload;
      function authenticate(name : string; password : string; db : string) : Boolean; overload;
      function command(db : string; command : TBson) : TBson; overload;
      function command(db : string; cmdstr : string; arg : OleVariant) : TBson; overload;
      function getLastErr(db : string) : TBson;
      function getPrevErr(db : string) : TBson;
      procedure resetErr(db : string);
      function getServerErr() : Integer;
      function getServerErrString() : string;
      destructor Destroy(); override;
    end;

    TMongoReplset = class(TMongo)
      constructor Create(name : string);
      procedure addSeed(host : string);
      function Connect() : Boolean;
      function getHostCount() : Integer;
      function getHost(i : Integer) : string;
    end;

    TMongoCursor = class(TObject)
      var
        handle  : Pointer;
        query   : TBson;
        sort    : TBson;
        fields  : TBson;
        limit   : Integer;
        skip    : Integer;
        options : Integer;
        conn    : TMongo; (* hold ref to prevent release *)

      const
        tailable   = 2;   (* Create a tailable cursor. *)
        slave_ok   = 4;   (* Allow queries on a non-primary node. *)
        no_timeout = 16;  (* Disable cursor timeouts. *)
        await_data = 32;  (* Momentarily block for more data. *)
        exhaust    = 64;  (* Stream in multiple 'more' packages. *)
        partial    = 128; (* Allow reads even if a shard is down. *)

      constructor Create(); overload;
      constructor Create(query_ : TBson); overload;
      destructor Destroy(); override;
      function next() : Boolean;
      function value() : TBson;
    end;

implementation
  Uses
    SysUtils;

  function mongo_create() : Pointer; cdecl; external 'mongoc.dll';
  procedure mongo_dispose(c : Pointer); cdecl; external 'mongoc.dll';
  function mongo_connect(c : Pointer; host : PAnsiChar; port : Integer) : Integer;
    cdecl; external 'mongoc.dll';
  procedure mongo_destroy(c : Pointer); cdecl; external 'mongoc.dll';
  procedure mongo_replset_init(c : Pointer; name : PAnsiChar); external 'mongoc.dll';
  procedure mongo_replset_add_seed(c : Pointer; host : PAnsiChar; port : Integer);
    cdecl; external 'mongoc.dll';
  function mongo_replset_connect(c : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function mongo_is_connected(c : Pointer) : Boolean;  cdecl; external 'mongoc.dll';
  function mongo_get_err(c : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function mongo_set_op_timeout(c : Pointer; millis : Integer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_get_op_timeout(c : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function mongo_get_primary(c : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';
  function mongo_check_connection(c : Pointer) : Integer; cdecl; external 'mongoc.dll';
  procedure mongo_disconnect(c : Pointer); cdecl; external 'mongoc.dll';
  function mongo_reconnect(c : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function mongo_cmd_ismaster(c : Pointer; b : Pointer) : Boolean;
    cdecl; external 'mongoc.dll';
  function mongo_get_socket(c : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function mongo_get_host_count(c : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function mongo_get_host(c : Pointer; i : Integer) : PAnsiChar; cdecl; external 'mongoc.dll';
  function mongo_insert(c : Pointer; ns : PAnsiChar; b : Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_insert_batch(c : Pointer; ns : PAnsiChar; bsons : Pointer; count : Integer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_update(c : Pointer; ns : PAnsiChar; cond : Pointer; op : Pointer; flags : Integer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_remove(c : Pointer; ns : PAnsiChar; criteria : Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_find_one(c : Pointer; ns : PAnsiChar; query : Pointer; fields : Pointer; result : Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_create() : Pointer;  external 'mongoc.dll';
  procedure bson_dispose(b : Pointer); cdecl; external 'mongoc.dll';
  procedure bson_copy(dest : Pointer; src : Pointer); cdecl; external 'mongoc.dll';
  function mongo_cursor_create() : Pointer;  cdecl; external 'mongoc.dll';
  procedure mongo_cursor_dispose(cursor : Pointer); cdecl; external 'mongoc.dll';
  procedure mongo_cursor_destroy(cursor : Pointer); cdecl; external 'mongoc.dll';
  function mongo_find(c : Pointer; ns : PAnsiChar; query : Pointer; fields : Pointer;
                      limit, skip, options : Integer) : Pointer; cdecl; external 'mongoc.dll';
  function mongo_cursor_next(cursor : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function mongo_cursor_bson(cursor : Pointer) : Pointer; cdecl; external 'mongoc.dll';
  function mongo_cmd_drop_collection(c : Pointer; db : PAnsiChar; collection : PAnsiChar; result : Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_cmd_drop_db(c : Pointer; db : PAnsiChar) : Integer; cdecl; external 'mongoc.dll';
  function mongo_count(c : Pointer; db : PAnsiChar; collection : PAnsiChar; query : Pointer) : Double;
    cdecl; external 'mongoc.dll';
  function mongo_create_index(c : Pointer; ns : PAnsiChar; key : Pointer; options : Integer; res : Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_cmd_add_user(c : Pointer; db : PAnsiChar; name : PAnsiChar; password : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_cmd_authenticate(c : Pointer; db : PAnsiChar; name : PAnsiChar; password : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_run_command(c : Pointer; db : PAnsiChar; command : Pointer; res: Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_cmd_get_last_error(c : Pointer; db : PAnsiChar; res: Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_cmd_get_prev_error(c : Pointer; db : PAnsiChar; res: Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  function mongo_get_server_err(c : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function mongo_get_server_err_string(c : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';

  procedure parseHost(host : string; var hosturl : string; var port : Integer);
  var i : Integer;
  begin
    i := Pos(':', host);
    hosturl := Copy(host, 1, i - 1);
    port := StrToInt(Copy(host, i + 1, Length(host) - i));
  end;

  constructor TMongo.Create();
  begin
    handle := mongo_create();
    mongo_connect(handle, '127.0.0.1', 27017);
  end;

  constructor TMongo.Create(host : string);
  var
    hosturl : string;
    port : Integer;
  begin
    handle := mongo_create();
    parseHost(host, hosturl, port);
    mongo_connect(handle, PAnsiChar(AnsiString(hosturl)), port);
  end;

  destructor TMongo.Destroy();
  begin
    mongo_destroy(handle);
    mongo_dispose(handle);
  end;

  constructor TMongoReplset.Create(name: string);
  begin
    handle := mongo_create();
    mongo_replset_init(handle, PAnsiChar(AnsiString(name)));
  end;

  procedure TMongoReplset.addSeed(host : string);
  var
    hosturl : string;
    port : Integer;
  begin
    parseHost(host, hosturl, port);
    mongo_replset_add_seed(handle, PAnsiChar(AnsiString(hosturl)), port);
  end;

  function TMongoReplset.Connect() : Boolean;
  begin
    Result := (mongo_replset_connect(handle) = 0);
  end;

  function TMongo.isConnected() : Boolean;
  begin
    Result := mongo_is_connected(handle);
  end;

  function TMongo.checkConnection() : Boolean;
  begin
    Result := (mongo_check_connection(handle) = 0);
  end;

  function TMongo.isMaster() : Boolean;
  begin
    Result := mongo_cmd_ismaster(handle, nil);
  end;

  procedure TMongo.disconnect();
  begin
    mongo_disconnect(handle);
  end;

  function TMongo.reconnect() : Boolean;
  begin
    Result := (mongo_reconnect(handle) = 0);
  end;

  function TMongo.getErr() : Integer;
  begin
    Result := mongo_get_err(handle);
  end;

  function TMongo.setTimeout(millis: Integer) : Boolean;
  begin
    Result := (mongo_set_op_timeout(handle, millis) = 0);
  end;

  function TMongo.getTimeout() : Integer;
  begin
    Result := mongo_get_op_timeout(handle);
  end;

  function TMongo.getPrimary() : string;
  begin
    Result := string(mongo_get_primary(handle));
  end;

  function TMongo.getSocket() : Integer;
  begin
    Result := mongo_get_socket(handle);
  end;

  function TMongoReplset.getHostCount() : Integer;
  begin
    Result := mongo_get_host_count(handle);
  end;

  function TMongoReplset.getHost(i : Integer) : string;
  begin
    Result := string(mongo_get_host(handle, i));
  end;

  function TMongo.getDatabases() : TStringArray;
  var
    b : TBson;
    it, databases, database : TBsonIterator;
    name : string;
    count, i : Integer;
  begin
    b := command('admin', 'listDatabases', True);
    if b = nil then
      Result := nil
    else begin
      it := b.iterator;
      it.next();
      count := 0;
      databases := it.subiterator();
      while databases.next() do begin
        database := databases.subiterator();
        database.next();
        name := database.value();
        if (name <> 'admin') and (name <> 'local') then
          inc(count);
      end;
      SetLength(Result, count);
      i := 0;
      databases := it.subiterator();
      while databases.next() do begin
        database := databases.subiterator();
        database.next();
        name := database.value();
        if (name <> 'admin') and (name <> 'local') then begin
          Result[i] := name;
          inc(i);
        end;
      end;
    end;
  end;

  function TMongo.getDatabaseCollections(db : string) : TStringArray;
    var
      cursor : TMongoCursor;
      count, i : Integer;
      ns, name : string;
      b : TBson;
  begin
    count := 0;
    ns := db + '.system.namespaces';
    cursor := TMongoCursor.Create();
    if find(ns, cursor) then
      while cursor.next() do begin
        b := cursor.value();
        name := b.value('name');
        if (Pos('.system.', name) = 0) and (Pos('$', name) = 0) then
          inc(count);
      end;
    SetLength(Result, count);
    i := 0;
    cursor := TMongoCursor.Create();
    if find(ns, cursor) then
      while cursor.next() do begin
        b := cursor.value();
        name := b.value('name');
        if (Pos('.system.', name) = 0) and (Pos('$', name) = 0) then begin
          Result[i] := name;
          inc(i);
        end;
      end;
  end;

  function TMongo.rename(from_ns : string; to_ns : string) : Boolean;
  begin
    Result := (command('admin', BSON(['renameCollection', from_ns, 'to', to_ns])) <> nil);
  end;

  function TMongo.drop(ns : string) : Boolean;
    var
      db : string;
      collection : string;
      i : Integer;
  begin
    i := Pos('.', ns);
    if i = 0 then
      Raise Exception.Create('TMongo.drop: expected a ''.'' in the namespace.');
    db := Copy(ns, 1, i - 1);
    collection := Copy(ns, i+1, Length(ns) - i);
    Result := (mongo_cmd_drop_collection(handle, PAnsiChar(AnsiString(db)),
                                                 PAnsiChar(AnsiString(collection)), nil) = 0);
  end;

  function TMongo.dropDatabase(db : string) : Boolean;
  begin
    Result := (mongo_cmd_drop_db(handle, PAnsiChar(AnsiString(db))) = 0);
  end;

  function TMongo.insert(ns: string; b: TBson) : Boolean;
  begin
    Result := (mongo_insert(handle, PAnsiChar(AnsiString(ns)), b.handle) = 0);
  end;

  function TMongo.insert(ns: string; bs: array of TBson) : Boolean;
  var
    ps : array of Pointer;
    i : Integer;
    len : Integer;
  begin
    len := Length(bs);
    SetLength(ps, Len);
    for i := 0 to Len-1 do
      ps[i] := bs[i].handle;
    Result := (mongo_insert_batch(handle, PAnsiChar(AnsiString(ns)), &ps, len) = 0);
  end;

  function TMongo.update(ns : string; criteria : TBson; objNew : TBson; flags : Integer) : Boolean;
  begin
    Result := (mongo_update(handle, PAnsiChar(AnsiString(ns)), criteria.handle, objNew.handle, flags) = 0);
  end;

  function TMongo.update(ns : string; criteria : TBson; objNew : TBson) : Boolean;
  begin
    Result := update(ns, criteria, objNew, 0);
  end;

  function TMongo.remove(ns : string; criteria : TBson) : Boolean;
  begin
    Result := (mongo_remove(handle, PAnsiChar(AnsiString(ns)), criteria.handle) = 0);
  end;

  function TMongo.findOne(ns : string; query : TBson; fields : TBson) : TBson;
    var
      res : Pointer;
  begin
    res := bson_create();
    if (mongo_find_one(handle, PAnsiChar(AnsiString(ns)), query.handle, fields.handle, res) = 0) then
      Result := TBson.Create(res)
    else begin
      mongo_dispose(res);
      Result := nil;
    end;
  end;

  function TMongo.findOne(ns : string; query : TBson) : TBson;
  begin
    Result := findOne(ns, query, TBson.Create(nil));
  end;

  constructor TMongoCursor.Create();
  begin
    handle := nil;
    query := nil;
    sort := nil;
    fields := nil;
    limit := 0;
    skip := 0;
    options := 0;
    conn := nil;
  end;

  constructor TMongoCursor.Create(query_ : TBson);
  begin
    handle := nil;
    query := query_;
    sort := nil;
    fields := nil;
    limit := 0;
    skip := 0;
    options := 0;
    conn := nil;
  end;

  destructor TMongoCursor.Destroy();
  begin
    mongo_cursor_destroy(handle);
    mongo_cursor_dispose(handle);
  end;

  function TMongo.find(ns : string; cursor : TMongoCursor) : Boolean;
    var
       q  : TBson;
       bb : TBsonBuffer;
       ch : Pointer;
  begin
    if cursor.fields = nil then
       cursor.fields := TBson.Create(nil);
    q := cursor.query;
    if q = nil then
      q := bsonEmpty;
    if cursor.sort <> nil then begin
      bb := TBsonBuffer.Create();
      bb.append('$query', cursor.query);
      bb.append('$sort', cursor.sort);
      q := bb.finish;
    end;
    cursor.conn := Self;
    ch := mongo_find(handle, PAnsiChar(AnsiString(ns)), q.handle, cursor.fields.handle,
                     cursor.limit, cursor.skip, cursor.options);
    if ch <> nil then begin
      cursor.handle := ch;
      Result := True;
    end
    else
      Result := False;
  end;


  function TMongoCursor.next() : Boolean;
  begin
    Result := (mongo_cursor_next(handle) = 0);
  end;
  
  function TMongoCursor.value() : TBson;
  var
    b : TBson;
    h : Pointer;
  begin
    h := bson_create();
    b := TBson.Create(h);
    bson_copy(h, mongo_cursor_bson(handle));
    Result := b;
  end;

  function TMongo.count(ns : string; query : TBson) : Double;
    var
      db : string;
      collection : string;
      i : Integer;
  begin
    i := Pos('.', ns);
    if i = 0 then
      Raise Exception.Create('TMongo.drop: expected a ''.'' in the namespace.');
    db := Copy(ns, 1, i - 1);
    collection := Copy(ns, i+1, Length(ns) - i);
    Result := mongo_count(handle, PAnsiChar(AnsiString(db)), 
                                  PAnsiChar(AnsiString(collection)), query.handle);
  end;

  function TMongo.count(ns : string) : Double;
  begin
    Result := count(ns, TBson.Create(nil));
  end;

  function TMongo.indexCreate(ns : string; key : TBson; options : Integer) : TBson;
  var
    res : TBson;
    created : Boolean;
  begin
    res := TBson.Create(bson_create());
    created := (mongo_create_index(handle, PAnsiChar(AnsiString(ns)), key.handle, options, res.handle) = 0);
    if not created then
      Result := res
    else
      Result := nil;
  end;
  
  function TMongo.indexCreate(ns : string; key : TBson) : TBson;
  begin
    Result := indexCreate(ns, key, 0);
  end;

  function TMongo.indexCreate(ns : string; key : string; options : Integer) : TBson;
  begin
    Result := indexCreate(ns, BSON([key, True]), options);
  end;
  
  function TMongo.indexCreate(ns : string; key : string) : TBson;
  begin
    Result := indexCreate(ns, key, 0);
  end;
  
  function TMongo.addUser(name : string; password : string; db : string) : Boolean;
  begin
    Result := (mongo_cmd_add_user(handle, PAnsiChar(AnsiString(db)),
                                          PAnsiChar(AnsiString(name)),
                                          PAnsiChar(AnsiString(password))) = 0);
  end;
  
  function TMongo.addUser(name : string; password : string) : Boolean;
  begin
    Result := addUser(name, password, 'admin');  
  end;

  function TMongo.authenticate(name : string; password : string; db : string) : Boolean;
  begin
    Result := (mongo_cmd_authenticate(handle, PAnsiChar(AnsiString(db)),
                                              PAnsiChar(AnsiString(name)),
                                              PAnsiChar(AnsiString(password))) = 0);
  end;
  
  function TMongo.authenticate(name : string; password : string) : Boolean;
  begin
    Result := authenticate(name, password, 'admin');
  end;
  
  function TMongo.command(db : string; command : TBson) : TBson;
  var
    b : TBson;
    res : Pointer;
  begin
    res := bson_create();
    if mongo_run_command(handle, PAnsiChar(AnsiString(db)), command.handle, res) = 0 then begin
      b := TBson.Create(bson_create());
      bson_copy(b.handle, res);
      Result := b;
    end
    else
      Result := nil;
    bson_dispose(res);
  end;
  
  function TMongo.command(db : string; cmdstr : string; arg : OleVariant) : TBson;
  begin
    Result := command(db, BSON([cmdstr, arg]));
  end;

  function TMongo.getLastErr(db : string) : TBson;
  var
    b : TBson;
    res : Pointer;
  begin
    res := bson_create();
    if mongo_cmd_get_last_error(handle, PAnsiChar(AnsiString(db)), res) <> 0 then begin
      b := TBson.Create(bson_create());
      bson_copy(b.handle, res);
      Result := b;
    end
    else
      Result := nil;
    bson_dispose(res);
  end;
  
  function TMongo.getPrevErr(db : string) : TBson;
  var
    b : TBson;
    res : Pointer;
  begin
    res := bson_create();
    if mongo_cmd_get_prev_error(handle, PAnsiChar(AnsiString(db)), res) <> 0 then begin
      b := TBson.Create(bson_create());
      bson_copy(b.handle, res);
      Result := b;
    end
    else
      Result := nil;
    bson_dispose(res);
  end;
  
  procedure TMongo.resetErr(db : string);
  begin
    command(db, 'reseterror', True);
  end;

  function TMongo.getServerErr() : Integer;
  begin
    Result := mongo_get_server_err(handle);
  end;

  function TMongo.getServerErrString() : string;
  begin
    Result := string(mongo_get_server_err_string(handle));
  end;

end.

