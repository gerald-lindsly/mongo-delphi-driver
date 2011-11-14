{ This unit implements the TMongo connection class for connecting to a MongoDB server
  and performing database operations on that server. }
unit MongoDB;

interface
  Uses
     MongoBson;

  const
    updateUpsert    = 1;
    updateMulti     = 2;
    updateBasic     = 4;

    indexUnique     = 1;
    indexDropDups   = 4;
    indexBackground = 8;
    indexSparse     = 16;

    { Create a tailable cursor. }
    cursorTailable  = 2;
    { Allow queries on a non-primary node. }
    cursorSlaveOk   = 4;
    { Disable cursor timeouts. }
    cursorNoTimeout = 16;
    { Momentarily block for more data. }
    cursorAwaitData = 32;
    { Stream in multiple 'more' packages. }
    cursorExhaust   = 64;
    { Allow reads even if a shard is down. }
    cursorPartial   = 128;

  type
    TMongoCursor = class;
    TStringArray = array of string;

    TMongo = class(TObject)
      { Pointer to externally managed data describing the connection.
        User code should not access this.  It is public only for
        access from the GridFS unit. }
      var handle : Pointer;
      { Create a TMongo connection object.  A connection is attempted on the
        MongoDB server running on the localhost '127.0.0.1:27017'.
        Check isConnected() to see if it was successful. }
      constructor Create(); overload;
      { Create a TMongo connection object.  The host:port to connect to is given
        as the host string. port defaults to 27017 if not given.
        Check the result of isConnected() to see if it was successful. }
      constructor Create(host : string); overload;
      { Determine whether this TMongo is currently connected to a MongoDB server.
        Returns True if connected; False, if not. }
      function isConnected() : Boolean;
      { Check the connection.  This returns True if isConnected() and the server
        responded to a 'ping'; otherwise, False. }
      function checkConnection() : Boolean;
      { Return True if the server reports that it is a master; otherwise, False. }
      function isMaster() : Boolean;
      { Temporarirly disconnect from the server.  The connection may be reestablished
        by calling reconnect.  This works on both normal connections and replsets. }
      procedure disconnect();
      { Reconnect to the MongoDB server after having called disconnect to suspend
        operations. }
      function reconnect() : Boolean;
      { Get an error code indicating the reason a connection or network communication
        failed. See mongo-c-driver/src/mongo.h and mongo_error_t. }
      function getErr() : Integer;
      { Set the timeout in milliseconds of a network operation.  The default of 0
        indicates that there is no timeout. }
      function setTimeout(millis : Integer) : Boolean;
      { Get the network operation timeout value in milliseconds.  The default of 0
        indicates that there is no timeout. }
      function getTimeout() : Integer;
      { Get the host:post of the primary server that this TMongo is connected to. }
      function getPrimary() : string;
      { Get the TCP/IP socket number being used for network communication }
      function getSocket() : Integer;
      { Get a list of databases from the server as an array of string }
      function getDatabases() : TStringArray;
      { Given a database name as a string, get the namespaces of the collections
        in that database as an array of string. }
      function getDatabaseCollections(db : string) : TStringArray;
      { Rename a collection.  from_ns is the current namespace of the collection
        to be renamed.  to_ns is the target namespace.
        The collection namespaces (from_ns, to_ns) are in the form 'database.collection'.
        Returns True if successful; otherwise, False.  Note that this function may
        be used to move a collection from one database to another. }
      function rename(from_ns : string; to_ns : string) : Boolean;
      { Drop a collection.  Removes the collection of the given name from the server.
        Exercise care when using this function.
        The collection namespace (ns) is in the form 'database.collection'. }
      function drop(ns : string) : Boolean;
      { Drop a database.  Removes the entire database of the given name from the server.
        Exercise care when using this function. }
      function dropDatabase(db : string) : Boolean;
      { Insert a document into the given namespace.
        The collection namespace (ns) is in the form 'database.collection'.
        See http://www.mongodb.org/display/DOCS/Inserting.
        Returns True if successful; otherwise, False. }
      function insert(ns : string; b : TBson) : Boolean; overload;
      { Insert a batch of documents into the given namespace (collection).
        The collection namespace (ns) is in the form 'database.collection'.
        See http://www.mongodb.org/display/DOCS/Inserting.
        Returns True if successful; otherwise, False. }
      function insert(ns : string; bs : array of TBson) : Boolean; overload;
      { Perform an update on the server.  The collection namespace (ns) is in the
        form 'database.collection'.  criteria indicates which records to update
        and objNew gives the replacement document.
        See http://www.mongodb.org/display/DOCS/Updating.
        Returns True if successful; otherwise, False. }
      function update(ns : string; criteria : TBson; objNew : TBson) : Boolean; overload;
      { Perform an update on the server.  The collection namespace (ns) is in the
        form 'database.collection'.  criteria indicates which records to update
        and objNew gives the replacement document. flags is a bit mask containing update
        options; updateUpsert, updateMulti, or updateBasic.
        See http://www.mongodb.org/display/DOCS/Updating.
        Returns True if successful; otherwise, False. }
      function update(ns : string; criteria : TBson; objNew : TBson; flags : Integer) : Boolean; overload;
      { Remove documents from the server.  The collection namespace (ns) is in the
        form 'database.collection'.  Documents that match the given criteria
        are removed from the collection.
        See http://www.mongodb.org/display/DOCS/Removing.
        Returns True if successful; otherwise, False. }
      function remove(ns : string; criteria : TBson) : Boolean;
      { Find the first document in the given namespace that matches a query.
        See http://www.mongodb.org/display/DOCS/Querying
        The collection namespace (ns) is in the form 'database.collection'.
        Returns the document as a TBson if found; otherwise, nil. }
      function findOne(ns : string; query : TBson) : TBson; overload;
      { Find the first document in the given namespace that matches a query.
        See http://www.mongodb.org/display/DOCS/Querying
        The collection namespace (ns) is in the form 'database.collection'.
        A subset of the documents fields to be returned is specified in fields.
        This can cut down on network traffic.
        Returns the document as a TBson if found; otherwise, nil. }
      function findOne(ns : string; query : TBson; fields : TBson) : TBson; overload;
      { Issue a query to the database.
        See http://www.mongodb.org/display/DOCS/Querying
        Requires a TMongoCursor that is used to specify optional parameters to
        the find and to step through the result set.
        The collection namespace (ns) is in the form 'database.collection'.
        Returns true if the query was successful and at least one document is
        in the result set; otherwise, false.
        Optionally, set other members of the TMongoCursor before calling
        find.  The TMongoCursor must be destroyed after finishing with a query.
        Instatiate a new cursor for another query.
        Example: @longcode(#
          var cursor : TMongoCursor;
          begin
          (* This finds all documents in the collection that have
             name equal to 'John' and steps through them. *)
            cursor := TMongoCursor.Create(BSON(['name', 'John']));
            if mongo.find(ns, cursor) then
              while cursor.next() do
                (* Do something with cursor.value() *)
          (* This finds all documents in the collection that have
             age equal to 32, but sorts them by name. *)
            cursor := TMongoCursor.Create(BSON(['age', 32]));
            cursor.sort := BSON(['name', True]);
            if mongo.find(ns, cursor) then
              while cursor.next() do
                (* Do something with cursor.value() *)
          end;
        #) }
      function find(ns : string; cursor : TMongoCursor) : Boolean;
      { Return the count of all documents in the given namespace.
        The collection namespace (ns) is in the form 'database.collection'. }
      function count(ns : string) : Double; overload;
      { Return the count of all documents in the given namespace that match
        the given query.
        The collection namespace (ns) is in the form 'database.collection'. }
      function count(ns : string; query : TBson) : Double; overload;
      { Create an index for the given collection so that accesses by the given
        key are faster.
        The collection namespace (ns) is in the form 'database.collection'.
        key is the name of the field on which to index.
        Returns nil if successful; otherwise, a TBson document that describes the error. }
      function indexCreate(ns : string; key : string) : TBson; overload;
      { Create an index for the given collection so that accesses by the given
        key are faster.
        The collection namespace (ns) is in the form 'database.collection'.
        key is the name of the field on which to index.
        options specifies a bit mask of indexUnique, indexDropDups, indexBackground,
        and/or indexSparse.
        Returns nil if successful; otherwise, a TBson document that describes the error. }
      function indexCreate(ns : string; key : string; options : Integer) : TBson; overload;
      { Create an index for the given collection so that accesses by the given
        key are faster.
        The collection namespace (ns) is in the form 'database.collection'.
        key is a TBson document that (possibly) defines a compound key.
        For example, @longcode(#
          mongo.indexCreate(ns, BSON(['age', True, 'name', True]));
          (* speed up accesses of documents by age and then name *)
        #)
        Returns nil if successful; otherwise, a TBson document that describes the error. }
      function indexCreate(ns : string; key : TBson) : TBson; overload;
      { Create an index for the given collection so that accesses by the given
        key are faster.
        The collection namespace (ns) is in the form 'database.collection'.
        key is a TBson document that (possibly) defines a compound key.
        For example, @longcode(#
          mongo.indexCreate(ns, BSON(['age', True, 'name', True]));
          (* speed up accesses of documents by age and then name *)
        #)
        options specifies a bit mask of indexUnique, indexDropDups, indexBackground,
        and/or indexSparse.
        Returns nil if successful; otherwise, a TBson document that describes the error. }
      function indexCreate(ns : string; key : TBson; options : Integer) : TBson; overload;
      { Add a user name / password to the 'admin' database.  This may be authenticated
        with the authenticate function.
        See http://www.mongodb.org/display/DOCS/Security+and+Authentication }
      function addUser(name : string; password : string) : Boolean; overload;
      { Add a user name / password to the given database.  This may be authenticated
        with the authenticate function.
        See http://www.mongodb.org/display/DOCS/Security+and+Authentication }
      function addUser(name : string; password : string; db : string) : Boolean; overload;
      { Authenticate a user name / password with the 'admin' database.
        See http://www.mongodb.org/display/DOCS/Security+and+Authentication }
      function authenticate(name : string; password : string) : Boolean; overload;
      { Authenticate a user name / password with the given database.
        See http://www.mongodb.org/display/DOCS/Security+and+Authentication }
      function authenticate(name : string; password : string; db : string) : Boolean; overload;
      { Issue a command to the server.  This supports all commands by letting you
        specify the command object as a TBson document.
        If successful, the response from the server is returned as a TBson document;
        otherwise, nil is returned.
        See http://www.mongodb.org/display/DOCS/List+of+Database+Commands }
      function command(db : string; command : TBson) : TBson; overload;
      { Issue a command to the server.  This version of the command() function
        supports that subset of commands which may be described by a cmdstr and
        an argument.
        If successful, the response from the server is returned as a TBson document;
        otherwise, nil is returned.
        See http://www.mongodb.org/display/DOCS/List+of+Database+Commands }
      function command(db : string; cmdstr : string; arg : OleVariant) : TBson; overload;
      { Get the last error reported by the server.  Returns a TBson document describing
        the error if there was one; otherwise, nil. }
      function getLastErr(db : string) : TBson;
      { Get the previous error reported by the server.  Returns a TBson document describing
        the error if there was one; otherwise, nil. }
      function getPrevErr(db : string) : TBson;
      { Reset the error status of the server.  After calling this function, both
        getLastErr() and getPrevErr() will return nil. }
      procedure resetErr(db : string);
      { Get the server error code.  As a convenience, this is saved here after calling
        getLastErr() or getPrevErr(). }
      function getServerErr() : Integer;
      { Get the server error string.  As a convenience, this is saved here after calling
        getLastErr() or getPrevErr(). }
      function getServerErrString() : string;
      { Destroy this TMongo object.  Severs the connection to the server and releases
        external resources. }
      destructor Destroy(); override;
    end;

    { TMongoReplset is a superclass of the TMongo connection class that implements
      a different constructor and several functions for connecting to a replset. }
    TMongoReplset = class(TMongo)
      { Create a TMongoReplset object given the replset name.  Unlike the constructor
        for TMongo, this does not yet establish the connection.  Call addSeed() for each
        of the seed hosts and then call Connect to connect to the replset. }
      constructor Create(name : string);
      { Add a seed to the replset.  The host string should be in the form 'host[:port]'.
        port defaults to 27017 if not given/
        After constructing a TMongoReplset, call this for each seed and then call
        Connect(). }
      procedure addSeed(host : string);
      { Connect to the replset.  The seeds added with addSeed() are polled to determine
        if they belong to the replset name given to the constructor.  Their hosts
        are then polled to determine the master to connect to.
        Returns True if it successfully connected; otherwise, False. }
      function Connect() : Boolean;
      { Get the number of hosts reported by the seeds }
      function getHostCount() : Integer;
      { Get the Ith host as a 'host:port' string. }
      function getHost(i : Integer) : string;
    end;

    { Objects of class TMongoCursor are used with TMongo.find() to specify
      optional parameters of the find and also to step though the result set.
      A TMongoCursor object is also returned by GridFS.TGridfile.getChunks() which
      is used to step through the chunks of a gridfile. }
    TMongoCursor = class(TObject)
      var
        { Pointer to externally managed data.  User code should not modify this. }
        handle  : Pointer;
        { A TBson document describing the query.
          See http://www.mongodb.org/display/DOCS/Querying }
        query   : TBson;
        { A TBson document describing the sort to be applied to the result set.
          See the example for TMongo.find().  Defaults to nil (no sort). }
        sort    : TBson;
        { A TBson document listing those fields to be included in the result set.
          This can be used to cut down on network traffic. Defaults to nil \
          (returns all fields of matching documents). }
        fields  : TBson;
        { Specifies a limiting count on the number of documents returned. The
          default of 0 indicates no limit on the number of records returned.}
        limit   : Integer;
        { Specifies the number of matched documents to skip. Default is 0. }
        skip    : Integer;
        { Specifies cursor options.  A bit mask of cursorTailable, cursorSlaveOk,
          cursorNoTimeout, cursorAwaitData, cursorExhaust , and/or cursorPartial.
          Defaults to 0 - no special handling. }
        options : Integer;
        { hold ref to the TMongo object of the find.  Prevents release of the
          TMongo object until after this cursor is destroyed. }
        conn    : TMongo;
      { Create a cursor with a empty query (which matches everything) }
      constructor Create(); overload;
      { Create a cursor with the given query. }
      constructor Create(query_ : TBson); overload;
      { Step to the first or next document in the result set.
        Returns True if there was a first or next document; otherwise,
        returns False when there are no more documents. }
      function next() : Boolean;
      { Return the current document of the result set }
      function value() : TBson;
      { Destroy this cursor.  TMongoCursor objects should be released and destroyed
        after using them with TMongo.find().  This releases resources associated
        with the query on both the client and server ends.  Construct a new
        TMongoCursor for another query. }
      destructor Destroy(); override;
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
    if i = 0 then begin
      hosturl := host;
      port := 27017;
    end
    else begin
      hosturl := Copy(host, 1, i - 1);
      port := StrToInt(Copy(host, i + 1, Length(host) - i));
    end;
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

